import '../entities/github_device_token_poll_result.dart';
import '../repositories/github_device_flow_repository.dart';

class PollGitHubDeviceToken {
  const PollGitHubDeviceToken(this._repository);

  final GitHubDeviceFlowRepository _repository;

  Future<GitHubDeviceTokenPollResult> call({required String deviceCode}) =>
      _repository.pollToken(deviceCode: deviceCode);
}
