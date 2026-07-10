import '../entities/github_repository_selection.dart';
import '../repositories/github_repository_catalog_repository.dart';

class LoadGitHubRepositoryBranches {
  const LoadGitHubRepositoryBranches(this._repository);

  final GitHubRepositoryCatalogRepository _repository;

  Future<List<GitHubBranchSummary>> call({
    required GitHubRepositorySummary repository,
    required String token,
  }) {
    return _repository.fetchBranches(repository: repository, token: token);
  }
}
