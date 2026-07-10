import 'dart:convert';
import 'dart:io';

import 'package:flutter_foundations/features/directory_git_sync/data/datasources/github_contents_api.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/models/github_repository_target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GitHubContentsApi', () {
    const target = GitHubRepositoryTarget(
      owner: 'octocat',
      repo: 'notes',
      branch: 'main',
      targetPath: 'mobile',
    );

    test('fetchDirectoryEntries parses files and directories', () async {
      late http.Request capturedRequest;
      final api = GitHubContentsApi(
        MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode([
              {'type': 'file', 'path': 'mobile/README.md'},
              {'type': 'dir', 'path': 'mobile/journal'},
              {'type': 'symlink', 'path': 'mobile/link'},
            ]),
            200,
          );
        }),
      );

      final entries = await api.fetchDirectoryEntries(
        target: target,
        path: 'mobile',
        token: 'token',
      );

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.url.path, '/repos/octocat/notes/contents/mobile');
      expect(capturedRequest.url.queryParameters['ref'], 'main');
      expect(
        capturedRequest.headers[HttpHeaders.authorizationHeader],
        'Bearer token',
      );
      expect(entries, hasLength(2));
      expect(entries.first.isFile, isTrue);
      expect(entries.last.isDirectory, isTrue);
    });

    test('fetchDirectoryEntries accepts a single file response', () async {
      final api = GitHubContentsApi(
        MockClient((_) async {
          return http.Response(
            jsonEncode({'type': 'file', 'path': 'mobile/README.md'}),
            200,
          );
        }),
      );

      final entries = await api.fetchDirectoryEntries(
        target: target,
        path: 'mobile/README.md',
        token: 'token',
      );

      expect(entries.single.path, 'mobile/README.md');
    });

    test('fetchFileBytes decodes base64 file content', () async {
      final api = GitHubContentsApi(
        MockClient((_) async {
          return http.Response(
            jsonEncode({
              'encoding': 'base64',
              'content': '${base64Encode(utf8.encode('hello'))}\n',
            }),
            200,
          );
        }),
      );

      final bytes = await api.fetchFileBytes(
        target: target,
        path: 'mobile/README.md',
        token: 'token',
      );

      expect(utf8.decode(bytes), 'hello');
    });

    test('reports authentication failures with a readable message', () async {
      final api = GitHubContentsApi(
        MockClient((_) async {
          return http.Response(jsonEncode({'message': 'Bad credentials'}), 401);
        }),
      );

      await expectLater(
        api.fetchDirectoryEntries(target: target, path: 'mobile', token: 'bad'),
        throwsA(
          isA<GitHubContentsApiException>().having(
            (error) => error.message,
            'message',
            contains('GitHub 认证失败'),
          ),
        ),
      );
    });
  });
}
