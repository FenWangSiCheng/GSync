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

    test('creates and updates files through the GitHub Contents API', () async {
      await File('${tempDirectory.path}/new.md').writeAsString('hello');
      await Directory('${tempDirectory.path}/journal').create();
      await File(
        '${tempDirectory.path}/journal/existing.md',
      ).writeAsString('updated');
      await Directory('${tempDirectory.path}/.git').create();
      await File('${tempDirectory.path}/.git/config').writeAsString('ignored');

      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        expect(
          request.headers[HttpHeaders.authorizationHeader],
          'Bearer token',
        );

        if (request.method == 'GET' &&
            request.url.path.endsWith('/contents/mobile/journal/existing.md')) {
          expect(request.url.queryParameters['ref'], 'main');
          return http.Response(jsonEncode({'sha': 'existing-sha'}), 200);
        }
        if (request.method == 'GET') {
          return http.Response(jsonEncode({'message': 'Not Found'}), 404);
        }
        if (request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['message'], 'Sync directory from GitSync');
          expect(body['branch'], 'main');
          if (request.url.path.endsWith('/contents/mobile/new.md')) {
            expect(body['content'], base64Encode(utf8.encode('hello')));
            expect(body.containsKey('sha'), isFalse);
            return http.Response(jsonEncode({'content': {}}), 201);
          }
          if (request.url.path.endsWith(
            '/contents/mobile/journal/existing.md',
          )) {
            expect(body['content'], base64Encode(utf8.encode('updated')));
            expect(body['sha'], 'existing-sha');
            return http.Response(jsonEncode({'content': {}}), 200);
          }
        }
        return http.Response(jsonEncode({'message': 'unexpected'}), 500);
      });
      final repository = GithubApiGitSyncRepository(GitHubContentsApi(client));

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
        requests.map((request) => '${request.method} ${request.url.path}'),
        containsAll([
          'GET /repos/octocat/notes/contents/mobile/new.md',
          'PUT /repos/octocat/notes/contents/mobile/new.md',
          'GET /repos/octocat/notes/contents/mobile/journal/existing.md',
          'PUT /repos/octocat/notes/contents/mobile/journal/existing.md',
        ]),
      );
      expect(
        requests.any((request) => request.url.path.contains('/.git/')),
        isFalse,
      );
    });

    test('reports invalid GitHub targets as readable failures', () async {
      await File('${tempDirectory.path}/note.md').writeAsString('hello');
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
      await File('${tempDirectory.path}/note.md').writeAsString('hello');
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
