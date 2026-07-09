import '../entities/github_oauth_authorization_session.dart';
import '../repositories/github_oauth_redirect_repository.dart';

class StartGitHubOAuthRedirectAuthorization {
  const StartGitHubOAuthRedirectAuthorization(this._repository);

  final GitHubOAuthRedirectRepository _repository;

  Future<GitHubOAuthAuthorizationSession> call() {
    return _repository.startAuthorization();
  }
}
