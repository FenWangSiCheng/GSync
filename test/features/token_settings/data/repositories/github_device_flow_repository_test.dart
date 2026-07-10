import 'dart:convert';

import 'package:flutter_foundations/core/config/app_config.dart';
import 'package:flutter_foundations/features/token_settings/data/datasources/github_device_flow_api.dart';
import 'package:flutter_foundations/features/token_settings/data/repositories/fixture_github_device_flow_repository.dart';
import 'package:flutter_foundations/features/token_settings/data/repositories/github_api_device_flow_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_device_token_poll_result.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_device_flow_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GitHubApiDeviceFlowRepository', () {
    test('uses configured client id and scope for authorization', () async {
      final requests = <http.Request>[];
      final repository = GitHubApiDeviceFlowRepository(
        appConfig: const AppConfig(
          currentFlavor: Flavor.prod,
          githubOAuthClientId: 'client-id',
          githubOAuthScope: 'public_repo',
        ),
        api: GitHubDeviceFlowApi(
          MockClient((request) async {
            requests.add(request);
            return http.Response(
              jsonEncode({
                'device_code': 'device-code',
                'user_code': 'ABCD-1234',
                'verification_uri': 'https://github.com/login/device',
                'expires_in': 900,
                'interval': 5,
              }),
              200,
            );
          }),
        ),
      );

      final authorization = await repository.requestAuthorization();

      expect(authorization.userCode, 'ABCD-1234');
      expect(requests.single.bodyFields['client_id'], 'client-id');
      expect(requests.single.bodyFields['scope'], 'public_repo');
    });

    test('uses configured client id when polling token', () async {
      late http.Request capturedRequest;
      final repository = GitHubApiDeviceFlowRepository(
        appConfig: const AppConfig(
          currentFlavor: Flavor.prod,
          githubOAuthClientId: 'client-id',
        ),
        api: GitHubDeviceFlowApi(
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
      );

      final result = await repository.pollToken(deviceCode: 'device-code');

      expect(capturedRequest.bodyFields['client_id'], 'client-id');
      expect(capturedRequest.bodyFields['device_code'], 'device-code');
      expect(
        result,
        isA<GitHubDeviceTokenAuthorized>().having(
          (result) => result.accessToken,
          'accessToken',
          'gho-token',
        ),
      );
    });

    test('reports missing OAuth client id before calling GitHub', () async {
      var called = false;
      final repository = GitHubApiDeviceFlowRepository(
        appConfig: const AppConfig(currentFlavor: Flavor.prod),
        api: GitHubDeviceFlowApi(
          MockClient((_) async {
            called = true;
            return http.Response('{}', 200);
          }),
        ),
      );

      expect(
        () => repository.requestAuthorization(),
        throwsA(
          isA<GitHubDeviceFlowException>().having(
            (error) => error.message,
            'message',
            contains('GitHub OAuth Client ID 未配置'),
          ),
        ),
      );
      expect(called, isFalse);
    });
  });

  group('FixtureGitHubDeviceFlowRepository', () {
    test('returns deterministic authorization and fixture token', () async {
      const repository = FixtureGitHubDeviceFlowRepository();

      final authorization = await repository.requestAuthorization();
      final pollResult = await repository.pollToken(
        deviceCode: authorization.deviceCode,
      );

      expect(authorization.userCode, 'ABCD-1234');
      expect(
        authorization.verificationUri.toString(),
        'https://github.com/login/device',
      );
      expect(
        pollResult,
        isA<GitHubDeviceTokenAuthorized>().having(
          (result) => result.accessToken,
          'accessToken',
          FixtureGitHubDeviceFlowRepository.fixtureAccessToken,
        ),
      );
    });

    test('rejects unknown fixture device codes', () async {
      const repository = FixtureGitHubDeviceFlowRepository();

      await expectLater(
        repository.pollToken(deviceCode: 'wrong-code'),
        throwsA(isA<GitHubDeviceFlowException>()),
      );
    });
  });
}
