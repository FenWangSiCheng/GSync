import '../entities/github_repository_selection.dart';
import '../repositories/github_repository_catalog_repository.dart';

class LoadGitHubRepositories {
  const LoadGitHubRepositories(this._repository);

  final GitHubRepositoryCatalogRepository _repository;

  Future<List<GitHubRepositorySummary>> call(String token) =>
      _repository.fetchRepositories(token);
}
