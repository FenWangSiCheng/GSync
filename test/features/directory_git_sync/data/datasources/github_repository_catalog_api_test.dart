import 'dart:convert';
import 'dart:io';

import 'package:flutter_foundations/features/directory_git_sync/data/datasources/github_repository_catalog_api.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/github_repository_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GitHubRepositoryCatalogApi', () {
    test('fetchRepositories maps authenticated repositories', () async {
      late http.Request capturedRequest;
      final api = GitHubRepositoryCatalogApi(
        MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode([
              {
                'name': 'notes',
                'full_name': 'octocat/notes',
                'private': true,
                'default_branch': 'trunk',
                'html_url': 'https://github.com/octocat/notes',
                'owner': {'login': 'octocat'},
              },
            ]),
            200,
          );
        }),
      );

      final repositories = await api.fetchRepositories(token: 'token');

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.url.path, '/user/repos');
      expect(capturedRequest.url.queryParameters['per_page'], '100');
      expect(
        capturedRequest.headers[HttpHeaders.authorizationHeader],
        'Bearer token',
      );
      expect(
        repositories.single,
        const GitHubRepositorySummary(
          owner: 'octocat',
          name: 'notes',
          fullName: 'octocat/notes',
          defaultBranch: 'trunk',
          htmlUrl: 'https://github.com/octocat/notes',
          isPrivate: true,
        ),
      );
    });

    test('fetchBranches maps repository branch names', () async {
      late http.Request capturedRequest;
      final api = GitHubRepositoryCatalogApi(
        MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode([
              {'name': 'main'},
              {'name': 'feature/sync'},
              {'commit': {}},
            ]),
            200,
          );
        }),
      );

      final branches = await api.fetchBranches(
        repository: const GitHubRepositorySummary(
          owner: 'octocat',
          name: 'notes',
          fullName: 'octocat/notes',
          defaultBranch: 'main',
          htmlUrl: 'https://github.com/octocat/notes',
          isPrivate: false,
        ),
        token: 'token',
      );

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.url.path, '/repos/octocat/notes/branches');
      expect(branches, const [
        GitHubBranchSummary(name: 'main'),
        GitHubBranchSummary(name: 'feature/sync'),
      ]);
    });

    test('reports authentication failures with a readable message', () async {
      final api = GitHubRepositoryCatalogApi(
        MockClient((_) async {
          return http.Response(jsonEncode({'message': 'Bad credentials'}), 401);
        }),
      );

      await expectLater(
        api.fetchRepositories(token: 'bad-token'),
        throwsA(
          isA<GitHubRepositoryCatalogApiException>().having(
            (error) => error.message,
            'message',
            contains('GitHub 认证失败'),
          ),
        ),
      );
    });
  });
}
