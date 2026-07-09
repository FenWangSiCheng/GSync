import 'package:equatable/equatable.dart';

class GitHubDeviceAuthorization extends Equatable {
  const GitHubDeviceAuthorization({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  final String deviceCode;
  final String userCode;
  final Uri verificationUri;
  final Duration expiresIn;
  final Duration interval;

  @override
  List<Object?> get props => [
    deviceCode,
    userCode,
    verificationUri,
    expiresIn,
    interval,
  ];
}
