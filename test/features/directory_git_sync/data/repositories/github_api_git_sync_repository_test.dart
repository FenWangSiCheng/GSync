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
        expect(result.message, contains('2 个文件'));
        expect(
          File('${tempDirectory.path}/README.md').readAsStringSync(),
          'hello',
        );
        expect(
          File('${tempDirectory.path}/journal/existing.md').readAsStringSync(),
          'updated',
        );
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
      expect(result.message, contains('没有可下载的文件'));
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
