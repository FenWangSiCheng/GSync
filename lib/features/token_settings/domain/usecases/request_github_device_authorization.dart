import '../entities/github_device_authorization.dart';
import '../repositories/github_device_flow_repository.dart';

class RequestGitHubDeviceAuthorization {
  const RequestGitHubDeviceAuthorization(this._repository);

  final GitHubDeviceFlowRepository _repository;

  Future<GitHubDeviceAuthorization> call() =>
      _repository.requestAuthorization();
}
