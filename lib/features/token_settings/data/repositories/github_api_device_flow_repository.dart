import '../../../../core/config/app_config.dart';
import '../../domain/entities/github_device_authorization.dart';
import '../../domain/entities/github_device_token_poll_result.dart';
import '../../domain/repositories/github_device_flow_repository.dart';
import '../datasources/github_device_flow_api.dart';

class GitHubApiDeviceFlowRepository implements GitHubDeviceFlowRepository {
  const GitHubApiDeviceFlowRepository({
    required AppConfig appConfig,
    required GitHubDeviceFlowApi api,
  }) : _appConfig = appConfig,
       _api = api;

  final AppConfig _appConfig;
  final GitHubDeviceFlowApi _api;

  @override
  Future<GitHubDeviceAuthorization> requestAuthorization() {
    final clientId = _clientId;
    return _api.requestDeviceCode(
      clientId: clientId,
      scope: _appConfig.githubOAuthScope,
    );
  }

  @override
  Future<GitHubDeviceTokenPollResult> pollToken({required String deviceCode}) {
    return _api.pollToken(clientId: _clientId, deviceCode: deviceCode);
  }

  String get _clientId {
    final clientId = _appConfig.githubOAuthClientId.trim();
    if (clientId.isEmpty) {
      throw const GitHubDeviceFlowException(
        'GitHub OAuth Client ID 未配置,请在 dart defines 中设置 githubOAuthClientId。',
      );
    }
    return clientId;
  }
}
