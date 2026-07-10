import '../../domain/entities/github_repository_selection.dart';
import '../../domain/repositories/github_repository_catalog_repository.dart';
import 'fixture_git_sync_repository.dart';

class FixtureGitHubRepositoryCatalogRepository
    implements GitHubRepositoryCatalogRepository {
  const FixtureGitHubRepositoryCatalogRepository();

  static const fixtureRepository = GitHubRepositorySummary(
    owner: 'octocat',
    name: 'gitsync-fixture',
    fullName: 'octocat/gitsync-fixture',
    defaultBranch: 'main',
    htmlUrl: FixtureGitSyncRepository.fixtureRemoteUrl,
    isPrivate: false,
  );

  static const secondaryRepository = GitHubRepositorySummary(
    owner: 'octocat',
    name: 'notes-archive',
    fullName: 'octocat/notes-archive',
    defaultBranch: 'main',
    htmlUrl: 'https://github.com/octocat/notes-archive',
    isPrivate: true,
  );

  static const fixtureBranch = GitHubBranchSummary(name: 'main');

  @override
  Future<List<GitHubRepositorySummary>> fetchRepositories(String token) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (token != FixtureGitSyncRepository.fixtureCredential) {
      return const [];
    }
    return const [fixtureRepository, secondaryRepository];
  }

  @override
  Future<List<GitHubBranchSummary>> fetchBranches({
    required GitHubRepositorySummary repository,
    required String token,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (token != FixtureGitSyncRepository.fixtureCredential) {
      return const [];
    }
    if (repository.fullName == fixtureRepository.fullName) {
      return const [fixtureBranch, GitHubBranchSummary(name: 'dev')];
    }
    return const [GitHubBranchSummary(name: 'main')];
  }
}
