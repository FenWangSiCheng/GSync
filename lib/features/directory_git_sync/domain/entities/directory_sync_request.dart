import 'package:equatable/equatable.dart';

class DirectorySyncRequest extends Equatable {
  const DirectorySyncRequest({
    required this.directoryPath,
    required this.remoteUrl,
    required this.credential,
    this.branch = 'main',
    this.commitMessage = 'Sync directory from GitSync',
  });

  final String directoryPath;
  final String remoteUrl;
  final String credential;
  final String branch;
  final String commitMessage;

  @override
  List<Object?> get props => [
    directoryPath,
    remoteUrl,
    credential,
    branch,
    commitMessage,
  ];
}
