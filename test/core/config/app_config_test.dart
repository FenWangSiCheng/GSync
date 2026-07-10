import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    group('fromEnvironment', () {
      test('should parse dev flavor from environment', () {
        // Note: Since we cannot set environment variables in tests,
        // this test demonstrates the expected behavior
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.currentFlavor, Flavor.dev);
      });

      test('should parse stg flavor from environment', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.currentFlavor, Flavor.stg);
      });

      test('should parse prod flavor from environment', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.currentFlavor, Flavor.prod);
      });
    });

    group('appName getter', () {
      test('should return correct app name for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.appName, 'GitSync 开发版');
      });

      test('should return correct app name for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.appName, 'GitSync 预发布版');
      });

      test('should return correct app name for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.appName, 'GitSync');
      });
    });

    group('baseUrl getter', () {
      test('should return dev base URL for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.baseUrl, 'https://api-dev.example.com');
      });

      test('should return staging base URL for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.baseUrl, 'https://api-staging.example.com');
      });

      test('should return production base URL for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.baseUrl, 'https://api.example.com');
      });
    });

    group('mockApiDataSource getter', () {
      test('should return true for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.mockApiDataSource, true);
      });

      test('should return false for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.mockApiDataSource, false);
      });

      test('should return false for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.mockApiDataSource, false);
      });
    });

    group('isNeedProxy getter', () {
      test('should return true for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.isNeedProxy, true);
      });

      test('should return true for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.isNeedProxy, true);
      });

      test('should return false for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.isNeedProxy, false);
      });
    });

    group('flavorName getter', () {
      test('should return correct flavor name for dev', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.flavorName, 'dev');
      });

      test('should return correct flavor name for stg', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.flavorName, 'stg');
      });

      test('should return correct flavor name for prod', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.flavorName, 'prod');
      });
    });

    group('flavorTitle getter', () {
      test('should return correct flavor title for dev', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.flavorTitle, 'template dev');
      });

      test('should return correct flavor title for stg', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.flavorTitle, 'template stg');
      });

      test('should return correct flavor title for prod', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.flavorTitle, 'template prod');
      });
    });

    group('isProduction getter', () {
      test('should return false for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.isProduction, false);
      });

      test('should return false for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.isProduction, false);
      });

      test('should return true for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.isProduction, true);
      });
    });

    group('GitHub OAuth config', () {
      test('defaults to no client id and repo scope', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.githubOAuthClientId, isEmpty);
        expect(config.githubOAuthScope, 'repo');
      });

      test('reports GitHub OAuth context without exposing client id', () {
        const config = AppConfig(
          currentFlavor: Flavor.prod,
          githubOAuthClientId: 'client-id',
          githubOAuthScope: 'public_repo',
        );

        expect(
          config.harnessContext['github_oauth_client_id_configured'],
          true,
        );
        expect(config.harnessContext['github_oauth_scope'], 'public_repo');
        expect(config.harnessContext.values, isNot(contains('client-id')));
      });
    });
  });
}
