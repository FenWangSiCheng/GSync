part of 'directory_sync_bloc.dart';

enum DirectorySyncStatus { idle, picking, syncing, success, failure }

class DirectorySyncState extends Equatable {
  const DirectorySyncState({
    this.selectedDirectoryPath = '',
    this.remoteUrl = '',
    this.credential = '',
    this.status = DirectorySyncStatus.idle,
    this.statusMessage = '请先选择一个目录。',
  });

  final String selectedDirectoryPath;
  final String remoteUrl;
  final String credential;
  final DirectorySyncStatus status;
  final String statusMessage;

  bool get canSync {
    return selectedDirectoryPath.trim().isNotEmpty &&
        remoteUrl.trim().isNotEmpty &&
        credential.trim().isNotEmpty &&
        status != DirectorySyncStatus.syncing &&
        status != DirectorySyncStatus.picking;
  }

  DirectorySyncState copyWith({
    String? selectedDirectoryPath,
    String? remoteUrl,
    String? credential,
    DirectorySyncStatus? status,
    String? statusMessage,
  }) {
    return DirectorySyncState(
      selectedDirectoryPath:
          selectedDirectoryPath ?? this.selectedDirectoryPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      credential: credential ?? this.credential,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedDirectoryPath,
    remoteUrl,
    credential,
    status,
    statusMessage,
  ];
}
