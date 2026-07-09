import '../entities/github_oauth_token.dart';
import '../repositories/github_oauth_redirect_repository.dart';

class CompleteGitHubOAuthRedirectAuthorization {
  const CompleteGitHubOAuthRedirectAuthorization(this._repository);

  final GitHubOAuthRedirectRepository _repository;

  Future<GitHubOAuthToken> call({required Uri callbackUri}) {
    return _repository.completeAuthorization(callbackUri: callbackUri);
  }
}
