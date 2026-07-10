import 'dart:convert';
import 'dart:io';

import 'package:flutter_foundations/features/directory_git_sync/data/datasources/github_contents_api.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/github_api_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_request.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GithubApiGitSyncRepository', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('github_api_sync_');
    });

    tearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'downloads remote repository files into the local directory',
      () async {
        await File('${tempDirectory.path}/stale.md').writeAsString('stale');
        await Directory('${tempDirectory.path}/empty').create();
        await File(
          '${tempDirectory.path}/journal/old.md',
        ).create(recursive: true);
        await Link(
          '${tempDirectory.path}/old-link',
        ).create('${tempDirectory.path}/stale.md');
        final requests = <http.Request>[];
        final client = MockClient((request) async {
          requests.add(request);
          expect(
            request.headers[HttpHeaders.authorizationHeader],
            'Bearer token',
          );

          if (request.method == 'GET' &&
              request.url.path.endsWith('/contents/mobile') &&
              request.url.queryParameters['ref'] == 'main') {
            return http.Response(
              jsonEncode([
                {'type': 'file', 'path': 'mobile/README.md'},
                {'type': 'dir', 'path': 'mobile/journal'},
              ]),
              200,
            );
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/contents/mobile/README.md')) {
            expect(request.url.queryParameters['ref'], 'main');
            return http.Response(
              jsonEncode({
                'type': 'file',
                'path': 'mobile/README.md',
                'encoding': 'base64',
                'content': base64Encode(utf8.encode('hello')),
              }),
              200,
            );
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/contents/mobile/journal')) {
            return http.Response(
              jsonEncode([
                {'type': 'file', 'path': 'mobile/journal/existing.md'},
              ]),
              200,
            );
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith(
                '/contents/mobile/journal/existing.md',
              )) {
            return http.Response(
              jsonEncode({
                'type': 'file',
                'path': 'mobile/journal/existing.md',
                'encoding': 'base64',
                'content': base64Encode(utf8.encode('updated')),
              }),
              200,
            );
          }
          return http.Response(jsonEncode({'message': 'unexpected'}), 500);
        });
        final repository = GithubApiGitSyncRepository(
          GitHubContentsApi(client),
        );

        final result = await repository.syncDirectory(
          DirectorySyncRequest(
            directoryPath: tempDirectory.path,
            remoteUrl: 'https://github.com/octocat/notes/tree/main/mobile',
            credential: 'token',
          ),
        );

        expect(result.type, DirectorySyncResultType.success);
        expect(result.message, contains('已下载 2 个远端文件'));
        expect(
          File('${tempDirectory.path}/README.md').readAsStringSync(),
          'hello',
        );
        expect(
          File('${tempDirectory.path}/journal/existing.md').readAsStringSync(),
          'updated',
        );
        expect(File('${tempDirectory.path}/stale.md').existsSync(), isFalse);
        expect(Directory('${tempDirectory.path}/empty').existsSync(), isFalse);
        expect(
          File('${tempDirectory.path}/journal/old.md').existsSync(),
          isFalse,
        );
        expect(
          FileSystemEntity.typeSync(
            '${tempDirectory.path}/old-link',
            followLinks: false,
          ),
          FileSystemEntityType.notFound,
        );
        expect(result.message, contains('清理 4 个本地残留项目'));
        expect(
          requests.map((request) => '${request.method} ${request.url.path}'),
          containsAll([
            'GET /repos/octocat/notes/contents/mobile',
            'GET /repos/octocat/notes/contents/mobile/README.md',
            'GET /repos/octocat/notes/contents/mobile/journal',
            'GET /repos/octocat/notes/contents/mobile/journal/existing.md',
          ]),
        );
        expect(requests.any((request) => request.method == 'PUT'), isFalse);
      },
    );

    test('clears a local directory when the remote path is a file', () async {
      await Directory('${tempDirectory.path}/README.md').create();
      await File('${tempDirectory.path}/README.md/old.md').writeAsString('old');
      final repository = GithubApiGitSyncRepository(
        GitHubContentsApi(
          MockClient((request) async {
            if (request.url.path.endsWith('/contents')) {
              return http.Response(
                jsonEncode([
                  {'type': 'file', 'path': 'README.md'},
                ]),
                200,
              );
            }
            if (request.url.path.endsWith('/contents/README.md')) {
              return http.Response(
                jsonEncode({
                  'type': 'file',
                  'path': 'README.md',
                  'encoding': 'base64',
                  'content': base64Encode(utf8.encode('remote')),
                }),
                200,
              );
            }
            return http.Response(jsonEncode({'message': 'unexpected'}), 500);
          }),
        ),
      );

      final result = await repository.syncDirectory(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://github.com/octocat/notes',
          credential: 'token',
        ),
      );

      expect(result.type, DirectorySyncResultType.success);
      expect(
        File('${tempDirectory.path}/README.md').readAsStringSync(),
        'remote',
      );
    });

    test('clears a local file when the remote path is a directory', () async {
      await File('${tempDirectory.path}/journal').writeAsString('old file');
      final repository = GithubApiGitSyncRepository(
        GitHubContentsApi(
          MockClient((request) async {
            if (request.url.path.endsWith('/contents')) {
              return http.Response(
                jsonEncode([
                  {'type': 'dir', 'path': 'journal'},
                ]),
                200,
              );
            }
            if (request.url.path.endsWith('/contents/journal')) {
              return http.Response(
                jsonEncode([
                  {'type': 'file', 'path': 'journal/note.md'},
                ]),
                200,
              );
            }
            if (request.url.path.endsWith('/contents/journal/note.md')) {
              return http.Response(
                jsonEncode({
                  'type': 'file',
                  'path': 'journal/note.md',
                  'encoding': 'base64',
                  'content': base64Encode(utf8.encode('remote note')),
                }),
                200,
              );
            }
            return http.Response(jsonEncode({'message': 'unexpected'}), 500);
          }),
        ),
      );

      final result = await repository.syncDirectory(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://github.com/octocat/notes',
          credential: 'token',
        ),
      );

      expect(result.type, DirectorySyncResultType.success);
      expect(
        File('${tempDirectory.path}/journal/note.md').readAsStringSync(),
        'remote note',
      );
    });

    test(
      'preserves local entries when downloading a remote file fails',
      () async {
        final residual = File('${tempDirectory.path}/local-only.md');
        await residual.writeAsString('keep me');
        final repository = GithubApiGitSyncRepository(
          GitHubContentsApi(
            MockClient((request) async {
              if (request.url.path.endsWith('/contents')) {
                return http.Response(
                  jsonEncode([
                    {'type': 'file', 'path': 'remote.md'},
                  ]),
                  200,
                );
              }
              if (request.url.path.endsWith('/contents/remote.md')) {
                return http.Response(jsonEncode({'message': 'broken'}), 500);
              }
              return http.Response(jsonEncode({'message': 'unexpected'}), 500);
            }),
          ),
        );

        final result = await repository.syncDirectory(
          DirectorySyncRequest(
            directoryPath: tempDirectory.path,
            remoteUrl: 'https://github.com/octocat/notes',
            credential: 'token',
          ),
        );

        expect(result.type, DirectorySyncResultType.failure);
        expect(residual.readAsStringSync(), 'keep me');
      },
    );

    test('reports no changes when the remote directory is empty', () async {
      final repository = GithubApiGitSyncRepository(
        GitHubContentsApi(
          MockClient((_) async {
            return http.Response(jsonEncode(<Object?>[]), 200);
          }),
        ),
      );

      final result = await repository.syncDirectory(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://github.com/octocat/notes',
          credential: 'token',
        ),
      );

      expect(result.type, DirectorySyncResultType.noChanges);
      expect(result.message, contains('本地目录已与远端一致'));
    });

    test('uses selected request branch for repository root targets', () async {
      late Uri capturedUri;
      final repository = GithubApiGitSyncRepository(
        GitHubContentsApi(
          MockClient((request) async {
            capturedUri = request.url;
            return http.Response(jsonEncode(<Object?>[]), 200);
          }),
        ),
      );

      await repository.syncDirectory(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://github.com/octocat/notes',
          credential: 'token',
          branch: 'feature/sync',
        ),
      );

      expect(capturedUri.queryParameters['ref'], 'feature/sync');
    });

    test('reports invalid GitHub targets as readable failures', () async {
      final repository = GithubApiGitSyncRepository(
        GitHubContentsApi(MockClient((_) async => http.Response('', 500))),
      );

      final result = await repository.syncDirectory(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://example.com/octocat/notes',
          credential: 'secret-token',
        ),
      );

      expect(result.type, DirectorySyncResultType.failure);
      expect(result.message, contains('请输入 GitHub 仓库地址'));
      expect(result.message, isNot(contains('secret-token')));
    });

    test('reports GitHub API failures without leaking the token', () async {
      final repository = GithubApiGitSyncRepository(
        GitHubContentsApi(
          MockClient((_) async {
            return http.Response(
              jsonEncode({'message': 'Bad credentials'}),
              401,
            );
          }),
        ),
      );

      final result = await repository.syncDirectory(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://github.com/octocat/notes',
          credential: 'secret-token',
        ),
      );

      expect(result.type, DirectorySyncResultType.failure);
      expect(result.message, contains('GitHub 认证失败'));
      expect(result.message, isNot(contains('secret-token')));
    });
  });
}
