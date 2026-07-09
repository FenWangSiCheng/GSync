import 'package:flutter_foundations/features/token_settings/data/repositories/fixture_github_oauth_redirect_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_oauth_redirect_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FixtureGitHubOAuthRedirectRepository', () {
    test('returns deterministic authorization and fixture token', () async {
      final repository = FixtureGitHubOAuthRedirectRepository();

      final session = await repository.startAuthorization();
      final token = await repository.completeAuthorization(
        callbackUri: Uri.parse(
          'gitsync-dev://oauth/github/callback?code=fixture-code&state=fixture-state',
        ),
      );

      expect(
        session.redirectUri.toString(),
        'gitsync-dev://oauth/github/callback',
      );
      expect(session.state, FixtureGitHubOAuthRedirectRepository.fixtureState);
      expect(
        session.authorizationUrl.queryParameters['code_challenge_method'],
        'S256',
      );
      expect(
        token.accessToken,
        FixtureGitHubOAuthRedirectRepository.fixtureAccessToken,
      );
    });

    test('rejects invalid callback URLs, errors, state, and missing code', () async {
      final repository = FixtureGitHubOAuthRedirectRepository();
      await repository.startAuthorization();

      await expectLater(
        repository.completeAuthorization(
          callbackUri: Uri.parse(
            'gitsync-dev://bad/github/callback?code=fixture-code&state=fixture-state',
          ),
        ),
        throwsA(isA<GitHubOAuthRedirectException>()),
      );

      await expectLater(
        repository.completeAuthorization(
          callbackUri: Uri.parse(
            'gitsync-dev://oauth/github/callback?error=access_denied&state=fixture-state',
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
            'gitsync-dev://oauth/github/callback?code=fixture-code&state=bad-state',
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

      await expectLater(
        repository.completeAuthorization(
          callbackUri: Uri.parse(
            'gitsync-dev://oauth/github/callback?state=fixture-state',
          ),
        ),
        throwsA(
          isA<GitHubOAuthRedirectException>().having(
            (error) => error.message,
            'message',
            'GitHub OAuth 回调缺少 code。',
          ),
        ),
      );
    });
  });
}
