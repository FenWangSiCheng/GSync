import 'package:equatable/equatable.dart';

class GitHubOAuthAuthorizationSession extends Equatable {
  const GitHubOAuthAuthorizationSession({
    required this.authorizationUrl,
    required this.redirectUri,
    required this.state,
    required this.codeVerifier,
  });

  final Uri authorizationUrl;
  final Uri redirectUri;
  final String state;
  final String codeVerifier;

  @override
  List<Object?> get props => [
    authorizationUrl,
    redirectUri,
    state,
    codeVerifier,
  ];
}
