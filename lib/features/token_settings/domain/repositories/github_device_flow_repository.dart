import '../entities/github_device_authorization.dart';
import '../entities/github_device_token_poll_result.dart';

abstract class GitHubDeviceFlowRepository {
  Future<GitHubDeviceAuthorization> requestAuthorization();

  Future<GitHubDeviceTokenPollResult> pollToken({required String deviceCode});
}

class GitHubDeviceFlowException implements Exception {
  const GitHubDeviceFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}
