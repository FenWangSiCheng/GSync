import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_oauth_authorization_session.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_oauth_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_oauth_redirect_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/complete_github_oauth_redirect_authorization.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/delete_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/get_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/save_git_token.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/start_github_oauth_redirect_authorization.dart';
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TokenSettingsBloc', () {
    late _FakeGitTokenRepository tokenRepository;
    late _FakeGitHubOAuthRedirectRepository oauthRedirectRepository;

    setUp(() {
      tokenRepository = _FakeGitTokenRepository();
      oauthRedirectRepository = _FakeGitHubOAuthRedirectRepository();
    });

    TokenSettingsBloc buildBloc() {
      return TokenSettingsBloc(
        getGitToken: GetGitToken(tokenRepository),
        saveGitToken: SaveGitToken(tokenRepository),
        deleteGitToken: DeleteGitToken(tokenRepository),
        startOAuthRedirectAuthorization: StartGitHubOAuthRedirectAuthorization(
          oauthRedirectRepository,
        ),
        completeOAuthRedirectAuthorization:
            CompleteGitHubOAuthRedirectAuthorization(oauthRedirectRepository),
      );
    }

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'loads existing authorization status',
      build: () {
        tokenRepository.token = 'test-token';
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TokenSettingsStarted()),
      expect: () => [
        isA<TokenSettingsState>()
            .having((state) => state.hasToken, 'hasToken', isTrue)
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              'GitHub 授权已安全保存。',
            ),
      ],
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'starts OAuth redirect authorization and waits for callback',
      build: buildBloc,
      act: (bloc) => bloc.add(const TokenSettingsOAuthRedirectRequested()),
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.openingBrowser,
        ),
        isA<TokenSettingsState>()
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.waitingForCallback,
            )
            .having(
              (state) => state.oauthRedirectUrl,
              'oauthRedirectUrl',
              contains('https://github.com/login/oauth/authorize'),
            )
            .having(
              (state) => state.oauthCallbackStatus,
              'oauthCallbackStatus',
              '正在等待 GitHub 授权回调。',
            ),
      ],
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'handles OAuth callback and stores the authorized token',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const TokenSettingsOAuthRedirectRequested());
        bloc.add(
          TokenSettingsOAuthCallbackReceived(
            Uri.parse(
              'gitsync-dev://oauth/github/callback?code=oauth-code&state=fixture-state',
            ),
          ),
        );
      },
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.openingBrowser,
        ),
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.waitingForCallback,
        ),
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.saving,
        ),
        isA<TokenSettingsState>()
            .having((state) => state.hasToken, 'hasToken', isTrue)
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.saved,
            )
            .having(
              (state) => state.oauthCallbackStatus,
              'oauthCallbackStatus',
              'GitHub 授权回调处理完成。',
            ),
      ],
      verify: (_) {
        expect(tokenRepository.token, 'gho-oauth-token');
      },
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'reports OAuth redirect configuration failures',
      build: () {
        oauthRedirectRepository.startError = const GitHubOAuthRedirectException(
          'GitHub OAuth 回调地址未配置。',
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TokenSettingsOAuthRedirectRequested()),
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.openingBrowser,
        ),
        isA<TokenSettingsState>()
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.failure,
            )
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              'GitHub OAuth 回调地址未配置。',
            ),
      ],
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'reports OAuth callback failures without storing a token',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const TokenSettingsOAuthRedirectRequested());
        bloc.add(
          TokenSettingsOAuthCallbackReceived(
            Uri.parse(
              'gitsync-dev://oauth/github/callback?code=oauth-code&state=bad-state',
            ),
          ),
        );
      },
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.openingBrowser,
        ),
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.waitingForCallback,
        ),
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.saving,
        ),
        isA<TokenSettingsState>()
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.failure,
            )
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              'GitHub OAuth state 校验失败。',
            ),
      ],
      verify: (_) {
        expect(tokenRepository.token, isNull);
      },
    );

    blocTest<TokenSettingsBloc, TokenSettingsState>(
      'deletes saved authorization',
      build: () {
        tokenRepository.token = 'test-token';
        return buildBloc();
      },
      seed: () => const TokenSettingsState(hasToken: true),
      act: (bloc) => bloc.add(const TokenSettingsDeleteRequested()),
      expect: () => [
        isA<TokenSettingsState>().having(
          (state) => state.status,
          'status',
          TokenSettingsStatus.saving,
        ),
        isA<TokenSettingsState>()
            .having((state) => state.hasToken, 'hasToken', isFalse)
            .having(
              (state) => state.status,
              'status',
              TokenSettingsStatus.deleted,
            ),
      ],
      verify: (_) {
        expect(tokenRepository.token, isNull);
      },
    );
  });
}

class _FakeGitTokenRepository implements GitTokenRepository {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String token) async {
    this.token = token.trim();
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }
}

class _FakeGitHubOAuthRedirectRepository
    implements GitHubOAuthRedirectRepository {
  GitHubOAuthRedirectException? startError;
  GitHubOAuthAuthorizationSession? _pendingSession;

  @override
  Future<GitHubOAuthAuthorizationSession> startAuthorization() async {
    final error = startError;
    if (error != null) throw error;
    final redirectUri = Uri.parse('gitsync-dev://oauth/github/callback');
    final session = GitHubOAuthAuthorizationSession(
      authorizationUrl: Uri.https('github.com', '/login/oauth/authorize', {
        'client_id': 'dev-fixture-client-id',
        'redirect_uri': redirectUri.toString(),
        'scope': 'repo',
        'state': 'fixture-state',
        'code_challenge': 'fixture-challenge',
        'code_challenge_method': 'S256',
      }),
      redirectUri: redirectUri,
      state: 'fixture-state',
      codeVerifier: 'fixture-verifier',
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
    if (callbackUri.queryParameters['state'] != session.state) {
      throw const GitHubOAuthRedirectException('GitHub OAuth state 校验失败。');
    }
    _pendingSession = null;
    return const GitHubOAuthToken(
      accessToken: 'gho-oauth-token',
      tokenType: 'bearer',
      scope: 'repo',
    );
  }
}
