import '../entities/github_repository_selection.dart';

abstract class GitHubRepositoryCatalogRepository {
  Future<List<GitHubRepositorySummary>> fetchRepositories(String token);

  Future<List<GitHubBranchSummary>> fetchBranches({
    required GitHubRepositorySummary repository,
    required String token,
  });
}
