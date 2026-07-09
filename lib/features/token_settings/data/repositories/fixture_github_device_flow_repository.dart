import '../../domain/entities/github_device_authorization.dart';
import '../../domain/entities/github_device_token_poll_result.dart';
import '../../domain/repositories/github_device_flow_repository.dart';

class FixtureGitHubDeviceFlowRepository implements GitHubDeviceFlowRepository {
  const FixtureGitHubDeviceFlowRepository();

  static const fixtureAccessToken = 'test-token';

  @override
  Future<GitHubDeviceAuthorization> requestAuthorization() async {
    return GitHubDeviceAuthorization(
      deviceCode: 'fixture-device-code',
      userCode: 'ABCD-1234',
      verificationUri: Uri.parse('https://github.com/login/device'),
      expiresIn: const Duration(minutes: 15),
      interval: Duration.zero,
    );
  }

  @override
  Future<GitHubDeviceTokenPollResult> pollToken({
    required String deviceCode,
  }) async {
    if (deviceCode != 'fixture-device-code') {
      throw const GitHubDeviceFlowException('GitHub 设备码无效,请重新授权。');
    }
    return const GitHubDeviceTokenAuthorized(
      accessToken: fixtureAccessToken,
      tokenType: 'bearer',
      scope: 'repo',
    );
  }
}
