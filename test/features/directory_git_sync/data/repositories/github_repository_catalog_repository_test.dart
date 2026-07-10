import 'dart:convert';

import 'package:flutter_foundations/features/directory_git_sync/data/datasources/github_repository_catalog_api.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_github_repository_catalog_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/github_api_repository_catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('FixtureGitHubRepositoryCatalogRepository', () {
    test(
      'returns deterministic repositories and branches for fixture token',
      () async {
        const repository = FixtureGitHubRepositoryCatalogRepository();

        final repositories = await repository.fetchRepositories(
          FixtureGitSyncRepository.fixtureCredential,
        );
        final branches = await repository.fetchBranches(
          repository: repositories.first,
          token: FixtureGitSyncRepository.fixtureCredential,
        );

        expect(repositories.map((repo) => repo.fullName), [
          'octocat/gitsync-fixture',
          'octocat/notes-archive',
        ]);
        expect(branches.map((branch) => branch.name), ['main', 'dev']);
      },
    );

    test('returns empty catalog for unknown fixture token', () async {
      const repository = FixtureGitHubRepositoryCatalogRepository();

      expect(await repository.fetchRepositories('wrong-token'), isEmpty);
      expect(
        await repository.fetchBranches(
          repository:
              FixtureGitHubRepositoryCatalogRepository.fixtureRepository,
          token: 'wrong-token',
        ),
        isEmpty,
      );
    });
  });

  group('GitHubApiRepositoryCatalogRepository', () {
    test('delegates repository and branch loading to the API', () async {
      final repository = GitHubApiRepositoryCatalogRepository(
        GitHubRepositoryCatalogApi(
          MockClient((request) async {
            if (request.url.path == '/user/repos') {
              return http.Response(
                jsonEncode([
                  {
                    'name': 'notes',
                    'full_name': 'octocat/notes',
                    'private': false,
                    'default_branch': 'main',
                    'html_url': 'https://github.com/octocat/notes',
                    'owner': {'login': 'octocat'},
                  },
                ]),
                200,
              );
            }
            return http.Response(
              jsonEncode([
                {'name': 'main'},
              ]),
              200,
            );
          }),
        ),
      );

      final repositories = await repository.fetchRepositories('token');
      final branches = await repository.fetchBranches(
        repository: repositories.single,
        token: 'token',
      );

      expect(repositories.single.fullName, 'octocat/notes');
      expect(branches.single.name, 'main');
    });
  });
}
