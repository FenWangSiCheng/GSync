import '../../domain/entities/github_oauth_authorization_session.dart';
import '../../domain/entities/github_oauth_token.dart';
import '../../domain/repositories/github_oauth_redirect_repository.dart';

class FixtureGitHubOAuthRedirectRepository
    implements GitHubOAuthRedirectRepository {
  static const fixtureAccessToken = 'test-token';
  static const fixtureState = 'fixture-state';

  GitHubOAuthAuthorizationSession? _pendingSession;

  @override
  Future<GitHubOAuthAuthorizationSession> startAuthorization() async {
    final redirectUri = Uri.parse('gitsync-dev://oauth/github/callback');
    final session = GitHubOAuthAuthorizationSession(
      authorizationUrl: Uri.https('github.com', '/login/oauth/authorize', {
        'client_id': 'dev-fixture-client-id',
        'redirect_uri': redirectUri.toString(),
        'scope': 'repo',
        'state': fixtureState,
        'code_challenge': 'fixture-code-challenge',
        'code_challenge_method': 'S256',
      }),
      redirectUri: redirectUri,
      state: fixtureState,
      codeVerifier: 'fixture-code-verifier',
    );
    _pendingSession = session;
    return session;
  }

  @override
  Future<GitHubOAuthToken> completeAuthorization({
    required Uri callbackUri,
  }) async {
    final session = _pendingSession;
    if (session == null) {
      throw const GitHubOAuthRedirectException('GitHub OAuth 授权会话已失效,请重新开始授权。');
    }
    _validateCallback(callbackUri: callbackUri, session: session);
    _pendingSession = null;
    return const GitHubOAuthToken(
      accessToken: fixtureAccessToken,
      tokenType: 'bearer',
      scope: 'repo',
    );
  }

  void _validateCallback({
    required Uri callbackUri,
    required GitHubOAuthAuthorizationSession session,
  }) {
    if (callbackUri.scheme != session.redirectUri.scheme ||
        callbackUri.host != session.redirectUri.host ||
        callbackUri.path != session.redirectUri.path) {
      throw const GitHubOAuthRedirectException('GitHub OAuth 回调地址无效。');
    }
    if (callbackUri.queryParameters['error'] case final String error) {
      throw GitHubOAuthRedirectException('GitHub 授权已取消:$error');
    }
    if (callbackUri.queryParameters['state'] != session.state) {
      throw const GitHubOAuthRedirectException('GitHub OAuth state 校验失败。');
    }
    final code = callbackUri.queryParameters['code'];
    if (code == null || code.trim().isEmpty) {
      throw const GitHubOAuthRedirectException('GitHub OAuth 回调缺少 code。');
    }
  }
}
