import '../../domain/entities/github_repository_selection.dart';
import '../../domain/repositories/github_repository_catalog_repository.dart';
import '../datasources/github_repository_catalog_api.dart';

class GitHubApiRepositoryCatalogRepository
    implements GitHubRepositoryCatalogRepository {
  const GitHubApiRepositoryCatalogRepository(this._api);

  final GitHubRepositoryCatalogApi _api;

  @override
  Future<List<GitHubRepositorySummary>> fetchRepositories(String token) {
    return _api.fetchRepositories(token: token);
  }

  @override
  Future<List<GitHubBranchSummary>> fetchBranches({
    required GitHubRepositorySummary repository,
    required String token,
  }) {
    return _api.fetchBranches(repository: repository, token: token);
  }
}
