import '../entities/github_oauth_authorization_session.dart';
import '../entities/github_oauth_token.dart';

abstract interface class GitHubOAuthRedirectRepository {
  Future<GitHubOAuthAuthorizationSession> startAuthorization();

  Future<GitHubOAuthToken> completeAuthorization({required Uri callbackUri});
}

class GitHubOAuthRedirectException implements Exception {
  const GitHubOAuthRedirectException(this.message);

  final String message;

  @override
  String toString() => message;
}
