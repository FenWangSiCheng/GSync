import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/github_oauth_authorization_session.dart';
import '../../domain/entities/github_oauth_token.dart';
import '../../domain/repositories/github_oauth_redirect_repository.dart';
import '../datasources/github_oauth_api.dart';
import '../datasources/oauth_browser_launcher.dart';

class GitHubApiOAuthRedirectRepository
    implements GitHubOAuthRedirectRepository {
  GitHubApiOAuthRedirectRepository({
    required AppConfig appConfig,
    required GitHubOAuthApi api,
    required OAuthBrowserLauncher browserLauncher,
    String Function(int length)? randomString,
  }) : _appConfig = appConfig,
       _api = api,
       _browserLauncher = browserLauncher,
       _randomString = randomString ?? _secureRandomString;

  final AppConfig _appConfig;
  final GitHubOAuthApi _api;
  final OAuthBrowserLauncher _browserLauncher;
  final String Function(int length) _randomString;
  GitHubOAuthAuthorizationSession? _pendingSession;

  @override
  Future<GitHubOAuthAuthorizationSession> startAuthorization() async {
    final clientId = _clientId;
    final redirectUri = _redirectUri;
    final state = _randomString(32);
    final codeVerifier = _randomString(64);
    final authorizationUrl = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri.toString(),
      if (_appConfig.githubOAuthScope.trim().isNotEmpty)
        'scope': _appConfig.githubOAuthScope.trim(),
      'state': state,
      'code_challenge': _pkceChallenge(codeVerifier),
      'code_challenge_method': 'S256',
    });

    final session = GitHubOAuthAuthorizationSession(
      authorizationUrl: authorizationUrl,
      redirectUri: redirectUri,
      state: state,
      codeVerifier: codeVerifier,
    );
    _pendingSession = session;
    await _browserLauncher.open(authorizationUrl);
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
    final token = await _api.exchangeCode(
      clientId: _clientId,
      code: callbackUri.queryParameters['code']!.trim(),
      redirectUri: session.redirectUri,
      codeVerifier: session.codeVerifier,
    );
    _pendingSession = null;
    return token;
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
      final description = callbackUri.queryParameters['error_description'];
      if (description != null && description.trim().isNotEmpty) {
        throw GitHubOAuthRedirectException('GitHub 授权已取消:$description');
      }
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

  String get _clientId {
    final clientId = _appConfig.githubOAuthClientId.trim();
    if (clientId.isEmpty) {
      throw const GitHubOAuthRedirectException(
        'GitHub OAuth Client ID 未配置,请在 dart defines 中设置 githubOAuthClientId。',
      );
    }
    return clientId;
  }

  Uri get _redirectUri {
    final redirectUri = Uri.tryParse(_appConfig.githubOAuthRedirectUri.trim());
    if (redirectUri == null ||
        redirectUri.scheme.isEmpty ||
        redirectUri.host.isEmpty) {
      throw const GitHubOAuthRedirectException(
        'GitHub OAuth 回调地址未配置,请在 dart defines 中设置 githubOAuthRedirectUri。',
      );
    }
    return redirectUri;
  }
}

String _pkceChallenge(String codeVerifier) {
  final digest = sha256.convert(utf8.encode(codeVerifier));
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

String _secureRandomString(int length) {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
}
