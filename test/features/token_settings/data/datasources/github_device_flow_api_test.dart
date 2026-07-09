import 'dart:convert';

import 'package:flutter_foundations/features/token_settings/data/datasources/github_device_flow_api.dart';
import 'package:flutter_foundations/features/token_settings/domain/entities/github_device_token_poll_result.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/github_device_flow_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GitHubDeviceFlowApi', () {
    test('requests a device code without a client secret', () async {
      late http.Request capturedRequest;
      final api = GitHubDeviceFlowApi(
        MockClient((request) async {
          capturedRequest = request;
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
      );

      final authorization = await api.requestDeviceCode(
        clientId: 'client-id',
        scope: 'repo',
      );

      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.url.toString(),
        'https://github.com/login/device/code',
      );
      expect(capturedRequest.bodyFields['client_id'], 'client-id');
      expect(capturedRequest.bodyFields['scope'], 'repo');
      expect(capturedRequest.bodyFields.containsKey('client_secret'), isFalse);
      expect(authorization.deviceCode, 'device-code');
      expect(authorization.userCode, 'ABCD-1234');
      expect(
        authorization.verificationUri.toString(),
        'https://github.com/login/device',
      );
      expect(authorization.expiresIn, const Duration(minutes: 15));
      expect(authorization.interval, const Duration(seconds: 5));
    });

    test('polls for an authorized token', () async {
      late http.Request capturedRequest;
      final api = GitHubDeviceFlowApi(
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

      final result = await api.pollToken(
        clientId: 'client-id',
        deviceCode: 'device-code',
      );

      expect(
        capturedRequest.url.toString(),
        'https://github.com/login/oauth/access_token',
      );
      expect(capturedRequest.bodyFields['client_id'], 'client-id');
      expect(capturedRequest.bodyFields['device_code'], 'device-code');
      expect(
        capturedRequest.bodyFields['grant_type'],
        'urn:ietf:params:oauth:grant-type:device_code',
      );
      expect(capturedRequest.bodyFields.containsKey('client_secret'), isFalse);
      expect(
        result,
        isA<GitHubDeviceTokenAuthorized>().having(
          (result) => result.accessToken,
          'accessToken',
          'gho-token',
        ),
      );
    });

    test(
      'maps pending, slow down, expired, and denied poll responses',
      () async {
        final responses = [
          {'error': 'authorization_pending'},
          {'error': 'slow_down', 'interval': 10},
          {'error': 'expired_token'},
          {'error': 'access_denied'},
        ];
        var responseIndex = 0;
        final api = GitHubDeviceFlowApi(
          MockClient((_) async {
            return http.Response(jsonEncode(responses[responseIndex++]), 200);
          }),
        );

        expect(
          await api.pollToken(clientId: 'client-id', deviceCode: 'device-code'),
          isA<GitHubDeviceTokenPending>(),
        );
        expect(
          await api.pollToken(clientId: 'client-id', deviceCode: 'device-code'),
          isA<GitHubDeviceTokenSlowDown>().having(
            (result) => result.interval,
            'interval',
            const Duration(seconds: 10),
          ),
        );
        expect(
          await api.pollToken(clientId: 'client-id', deviceCode: 'device-code'),
          isA<GitHubDeviceTokenExpired>(),
        );
        expect(
          await api.pollToken(clientId: 'client-id', deviceCode: 'device-code'),
          isA<GitHubDeviceTokenDenied>(),
        );
      },
    );

    test('throws readable failures for OAuth errors', () async {
      final api = GitHubDeviceFlowApi(
        MockClient((_) async {
          return http.Response(
            jsonEncode({
              'error': 'device_flow_disabled',
              'error_description': 'Device flow is not enabled.',
            }),
            200,
          );
        }),
      );

      await expectLater(
        api.requestDeviceCode(clientId: 'client-id', scope: 'repo'),
        throwsA(
          isA<GitHubDeviceFlowException>().having(
            (error) => error.message,
            'message',
            contains('Device flow is not enabled'),
          ),
        ),
      );
    });

    test('throws readable failures for non-success responses', () async {
      final api = GitHubDeviceFlowApi(
        MockClient((_) async {
          return http.Response('', 500);
        }),
      );

      await expectLater(
        api.requestDeviceCode(clientId: 'client-id', scope: 'repo'),
        throwsA(
          isA<GitHubDeviceFlowException>().having(
            (error) => error.message,
            'message',
            'GitHub 授权请求失败(500)。',
          ),
        ),
      );
    });

    test('throws readable failures for unknown poll errors', () async {
      final api = GitHubDeviceFlowApi(
        MockClient((_) async {
          return http.Response(jsonEncode({'error': 'bad_verification'}), 200);
        }),
      );

      await expectLater(
        api.pollToken(clientId: 'client-id', deviceCode: 'device-code'),
        throwsA(
          isA<GitHubDeviceFlowException>().having(
            (error) => error.message,
            'message',
            contains('bad_verification'),
          ),
        ),
      );
    });
  });
}
