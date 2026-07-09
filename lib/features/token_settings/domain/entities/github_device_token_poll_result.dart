import 'package:equatable/equatable.dart';

sealed class GitHubDeviceTokenPollResult extends Equatable {
  const GitHubDeviceTokenPollResult();

  @override
  List<Object?> get props => [];
}

class GitHubDeviceTokenAuthorized extends GitHubDeviceTokenPollResult {
  const GitHubDeviceTokenAuthorized({
    required this.accessToken,
    required this.tokenType,
    required this.scope,
  });

  final String accessToken;
  final String tokenType;
  final String scope;

  @override
  List<Object?> get props => [accessToken, tokenType, scope];
}

class GitHubDeviceTokenPending extends GitHubDeviceTokenPollResult {
  const GitHubDeviceTokenPending();
}

class GitHubDeviceTokenSlowDown extends GitHubDeviceTokenPollResult {
  const GitHubDeviceTokenSlowDown(this.interval);

  final Duration interval;

  @override
  List<Object?> get props => [interval];
}

class GitHubDeviceTokenExpired extends GitHubDeviceTokenPollResult {
  const GitHubDeviceTokenExpired();
}

class GitHubDeviceTokenDenied extends GitHubDeviceTokenPollResult {
  const GitHubDeviceTokenDenied();
}
