import 'package:equatable/equatable.dart';

class GitHubOAuthToken extends Equatable {
  const GitHubOAuthToken({
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
