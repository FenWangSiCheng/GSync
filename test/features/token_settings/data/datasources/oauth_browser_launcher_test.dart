import 'package:flutter_foundations/features/token_settings/data/datasources/oauth_browser_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChromeSafariOAuthBrowserLauncher', () {
    test('opens URLs when browser support is available', () async {
      Uri? openedUrl;
      final launcher = ChromeSafariOAuthBrowserLauncher(
        isAvailable: () async => true,
        openUrl: (url) async {
          openedUrl = url;
        },
      );

      await launcher.open(
        Uri.parse('https://github.com/login/oauth/authorize'),
      );

      expect(openedUrl.toString(), 'https://github.com/login/oauth/authorize');
    });

    test(
      'throws a readable failure when browser support is unavailable',
      () async {
        final launcher = ChromeSafariOAuthBrowserLauncher(
          isAvailable: () async => false,
          openUrl: (_) async {
            throw StateError('openUrl should not be called');
          },
        );

        await expectLater(
          launcher.open(Uri.parse('https://github.com/login/oauth/authorize')),
          throwsA(
            isA<OAuthBrowserLaunchException>().having(
              (error) => error.message,
              'message',
              '无法打开 GitHub 授权页面。',
            ),
          ),
        );
      },
    );
  });
}
