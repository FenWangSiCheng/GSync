import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_foundations/core/config/app_config.dart';
import 'package:flutter_foundations/features/token_settings/data/datasources/github_oauth_api.dart';
import 'package:flutter_foundations/features/token_settings/data/datasources/oauth_browser_launcher.dart';
import 'package:flutter_foundations/features/token_settings/data/repositories/github_api_oauth_redirect_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_oauth_redirect_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GitHubApiOAuthRedirectRepository', () {
    test('builds an authorize URL with PKCE and opens it', () async {
      final launcher = _FakeOAuthBrowserLauncher();
      final repository = GitHubApiOAuthRedirectRepository(
        appConfig: const AppConfig(
          currentFlavor: Flavor.prod,
          githubOAuthClientId: 'client-id',
          githubOAuthRedirectUri: 'gitsync://oauth/github/callback',
          githubOAuthScope: 'repo',
        ),
        api: GitHubOAuthApi(MockClient((_) async => http.Response('{}', 200))),
        browserLauncher: launcher,
        randomString: _queuedRandom(['state-value', 'verifier-value']),
      );

      final session = await repository.startAuthorization();

      expect(launcher.openedUrl, session.authorizationUrl);
      expect(session.state, 'state-value');
      expect(session.codeVerifier, 'verifier-value');
      expect(session.redirectUri.toString(), 'gitsync://oauth/github/callback');
      expect(session.authorizationUrl.host, 'github.com');
      expect(session.authorizationUrl.path, '/login/oauth/authorize');
      expect(
        session.authorizationUrl.queryParameters['client_id'],
        'client-id',
      );
      expect(
        session.authorizationUrl.queryParameters['redirect_uri'],
        'gitsync://oauth/github/callback',
      );
      expect(session.authorizationUrl.queryParameters['scope'], 'repo');
      expect(session.authorizationUrl.queryParameters['state'], 'state-value');
      expect(
        session.authorizationUrl.queryParameters['code_challenge'],
        _challengeFor('verifier-value'),
      );
      expect(
        session.authorizationUrl.queryParameters['code_challenge_method'],
        'S256',
      );
    });

    test(
      'validates callback state and exchanges code without a secret',
      () async {
        late http.Request capturedRequest;
        final repository = GitHubApiOAuthRedirectRepository(
          appConfig: const AppConfig(
            currentFlavor: Flavor.prod,
            githubOAuthClientId: 'client-id',
            githubOAuthRedirectUri: 'gitsync://oauth/github/callback',
          ),
          api: GitHubOAuthApi(
            MockClient((request) async {
              capturedRequest = request;
              return http.Response(
                jsonEncode({
                  'access_token': 'gho-token',
                  'token_type': 'bearer',
                  'scope': 'repo',
                }),
                200,
              );
            }),
          ),
          browserLauncher: _FakeOAuthBrowserLauncher(),
          randomString: _queuedRandom(['state-value', 'verifier-value']),
        );
        await repository.startAuthorization();

        final token = await repository.completeAuthorization(
          callbackUri: Uri.parse(
            'gitsync://oauth/github/callback?code=oauth-code&state=state-value',
          ),
        );

        expect(token.accessToken, 'gho-token');
        expect(
          capturedRequest.url.toString(),
          'https://github.com/login/oauth/access_token',
        );
        expect(capturedRequest.bodyFields['client_id'], 'client-id');
        expect(capturedRequest.bodyFields['code'], 'oauth-code');
        expect(
          capturedRequest.bodyFields['redirect_uri'],
          'gitsync://oauth/github/callback',
        );
        expect(capturedRequest.bodyFields['code_verifier'], 'verifier-value');
        expect(
          capturedRequest.bodyFields.containsKey('client_secret'),
          isFalse,
        );
      },
    );

    test('rejects callback errors and mismatched state', () async {
      final repository = GitHubApiOAuthRedirectRepository(
        appConfig: const AppConfig(
          currentFlavor: Flavor.prod,
          githubOAuthClientId: 'client-id',
          githubOAuthRedirectUri: 'gitsync://oauth/github/callback',
        ),
        api: GitHubOAuthApi(MockClient((_) async => http.Response('{}', 200))),
        browserLauncher: _FakeOAuthBrowserLauncher(),
        randomString: _queuedRandom(['state-value', 'verifier-value']),
      );
      await repository.startAuthorization();

      await expectLater(
        repository.completeAuthorization(
          callbackUri: Uri.parse(
            'gitsync://oauth/github/callback?error=access_denied&state=state-value',
          ),
        ),
        throwsA(
          isA<GitHubOAuthRedirectException>().having(
            (error) => error.message,
            'message',
            contains('access_denied'),
          ),
        ),
      );

      await expectLater(
        repository.completeAuthorization(
          callbackUri: Uri.parse(
            'gitsync://oauth/github/callback?code=oauth-code&state=bad-state',
          ),
        ),
        throwsA(
          isA<GitHubOAuthRedirectException>().having(
            (error) => error.message,
            'message',
            'GitHub OAuth state 校验失败。',
          ),
        ),
      );
    });

    test('reports missing OAuth redirect configuration', () async {
      final repository = GitHubApiOAuthRedirectRepository(
        appConfig: const AppConfig(
          currentFlavor: Flavor.prod,
          githubOAuthClientId: 'client-id',
        ),
        api: GitHubOAuthApi(MockClient((_) async => http.Response('{}', 200))),
        browserLauncher: _FakeOAuthBrowserLauncher(),
      );

      await expectLater(
        repository.startAuthorization(),
        throwsA(
          isA<GitHubOAuthRedirectException>().having(
            (error) => error.message,
            'message',
            contains('githubOAuthRedirectUri'),
          ),
        ),
      );
    });
  });
}

String Function(int length) _queuedRandom(List<String> values) {
  var index = 0;
  return (_) => values[index++];
}

String _challengeFor(String verifier) {
  final digest = sha256.convert(utf8.encode(verifier));
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

class _FakeOAuthBrowserLauncher implements OAuthBrowserLauncher {
  Uri? openedUrl;

  @override
  Future<void> open(Uri url) async {
    openedUrl = url;
  }
}
