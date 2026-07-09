import 'dart:convert';

import 'package:flutter_foundations/features/token_settings/data/datasources/github_oauth_api.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_oauth_redirect_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GitHubOAuthApi', () {
    test('exchanges an authorization code for a token', () async {
      late http.Request capturedRequest;
      final api = GitHubOAuthApi(
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
      );

      final token = await api.exchangeCode(
        clientId: 'client-id',
        code: 'oauth-code',
        redirectUri: Uri.parse('gitsync://oauth/github/callback'),
        codeVerifier: 'verifier',
      );

      expect(token.accessToken, 'gho-token');
      expect(
        capturedRequest.url.toString(),
        'https://github.com/login/oauth/access_token',
      );
      expect(capturedRequest.bodyFields['client_id'], 'client-id');
      expect(capturedRequest.bodyFields['code'], 'oauth-code');
      expect(capturedRequest.bodyFields['code_verifier'], 'verifier');
      expect(capturedRequest.bodyFields.containsKey('client_secret'), isFalse);
    });

    test('throws readable failures for OAuth errors', () async {
      final api = GitHubOAuthApi(
        MockClient((_) async {
          return http.Response(
            jsonEncode({
              'error': 'redirect_uri_mismatch',
              'error_description': 'The redirect_uri MUST match.',
            }),
            200,
          );
        }),
      );

      await expectLater(
        api.exchangeCode(
          clientId: 'client-id',
          code: 'oauth-code',
          redirectUri: Uri.parse('gitsync://oauth/github/callback'),
          codeVerifier: 'verifier',
        ),
        throwsA(
          isA<GitHubOAuthRedirectException>().having(
            (error) => error.message,
            'message',
            contains('The redirect_uri MUST match'),
          ),
        ),
      );
    });

    test('maps known OAuth errors without descriptions', () async {
      final api = GitHubOAuthApi(
        MockClient((_) async {
          return http.Response(
            jsonEncode({'error': 'bad_verification_code'}),
            200,
          );
        }),
      );

      await expectLater(
        api.exchangeCode(
          clientId: 'client-id',
          code: 'oauth-code',
          redirectUri: Uri.parse('gitsync://oauth/github/callback'),
          codeVerifier: 'verifier',
        ),
        throwsA(
          isA<GitHubOAuthRedirectException>().having(
            (error) => error.message,
            'message',
            'GitHub 授权 code 无效,请重新授权。',
          ),
        ),
      );
    });

    test('throws readable failures for non-success responses', () async {
      final api = GitHubOAuthApi(
        MockClient((_) async => http.Response('', 500)),
      );

      await expectLater(
        api.exchangeCode(
          clientId: 'client-id',
          code: 'oauth-code',
          redirectUri: Uri.parse('gitsync://oauth/github/callback'),
          codeVerifier: 'verifier',
        ),
        throwsA(
          isA<GitHubOAuthRedirectException>().having(
            (error) => error.message,
            'message',
            'GitHub 授权换取令牌失败(500)。',
          ),
        ),
      );
    });
  });
}
