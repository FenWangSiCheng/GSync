import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_oauth_authorization_session.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_oauth_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_oauth_redirect_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/complete_github_oauth_redirect_authorization.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/save_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/start_github_oauth_redirect_authorization.dart';
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Token settings entities', () {
    test('state exposes OAuth redirect and delete availability', () {
      const empty = TokenSettingsState();
      final opening = empty.copyWith(
        status: TokenSettingsStatus.openingBrowser,
      );
      final saved = empty.copyWith(hasToken: true);

      expect(empty.canStartOAuthRedirect, isTrue);
      expect(opening.isBusy, isTrue);
      expect(opening.canStartOAuthRedirect, isFalse);
      expect(empty.canDelete, isFalse);
      expect(saved.canDelete, isTrue);
      expect(saved.props, [
        true,
        TokenSettingsStatus.idle,
        '正在检查访问令牌。',
        '',
        '',
      ]);
    });

    test('events expose value props', () {
      expect(const TokenSettingsStarted().props, isEmpty);
      expect(const TokenSettingsOAuthRedirectRequested().props, isEmpty);
      expect(
        TokenSettingsOAuthCallbackReceived(
          Uri.parse('gitsync-dev://oauth/github/callback'),
        ).props,
        [Uri.parse('gitsync-dev://oauth/github/callback')],
      );
      expect(const TokenSettingsDeleteRequested().props, isEmpty);
    });

    test('save token validation rejects blank values', () async {
      const useCase = SaveGitToken(_NeverCalledGitTokenRepository());

      expect(() => useCase('   '), throwsA(isA<SaveGitTokenException>()));
    });

    test('OAuth redirect entities expose value props', () {
      final redirectUri = Uri.parse('gitsync-dev://oauth/github/callback');
      final authorizationUrl = Uri.https(
        'github.com',
        '/login/oauth/authorize',
      );
      final session = GitHubOAuthAuthorizationSession(
        authorizationUrl: authorizationUrl,
        redirectUri: redirectUri,
        state: 'state',
        codeVerifier: 'verifier',
      );
      const token = GitHubOAuthToken(
        accessToken: 'token',
        tokenType: 'bearer',
        scope: 'repo',
      );

      expect(session.props, [
        authorizationUrl,
        redirectUri,
        'state',
        'verifier',
      ]);
      expect(token.props, ['token', 'bearer', 'repo']);
    });

    test('OAuth redirect use cases delegate to repository', () async {
      final repository = _FakeGitHubOAuthRedirectRepository();
      final start = StartGitHubOAuthRedirectAuthorization(repository);
      final complete = CompleteGitHubOAuthRedirectAuthorization(repository);

      await start();
      final token = await complete(
        callbackUri: Uri.parse(
          'gitsync-dev://oauth/github/callback?code=code&state=state',
        ),
      );

      expect(repository.started, isTrue);
      expect(repository.completed, isTrue);
      expect(token.accessToken, 'token');
    });

    test('OAuth redirect exception string is readable', () {
      const error = GitHubOAuthRedirectException('GitHub OAuth state 校验失败。');

      expect(error.toString(), 'GitHub OAuth state 校验失败。');
    });
  });
}

class _NeverCalledGitTokenRepository implements GitTokenRepository {
  const _NeverCalledGitTokenRepository();

  @override
  Future<String?> readToken() {
    throw StateError('readToken should not be called');
  }

  @override
  Future<void> saveToken(String token) {
    throw StateError('saveToken should not be called');
  }

  @override
  Future<void> deleteToken() {
    throw StateError('deleteToken should not be called');
  }
}

class _FakeGitHubOAuthRedirectRepository
    implements GitHubOAuthRedirectRepository {
  bool started = false;
  bool completed = false;

  @override
  Future<GitHubOAuthAuthorizationSession> startAuthorization() async {
    started = true;
    return GitHubOAuthAuthorizationSession(
      authorizationUrl: Uri.https('github.com', '/login/oauth/authorize'),
      redirectUri: Uri.parse('gitsync-dev://oauth/github/callback'),
      state: 'state',
      codeVerifier: 'verifier',
    );
  }

  @override
  Future<GitHubOAuthToken> completeAuthorization({
    required Uri callbackUri,
  }) async {
    completed = true;
    return const GitHubOAuthToken(
      accessToken: 'token',
      tokenType: 'bearer',
      scope: 'repo',
    );
  }
}
