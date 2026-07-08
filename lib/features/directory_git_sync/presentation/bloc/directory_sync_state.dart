part of 'directory_sync_bloc.dart';

enum DirectorySyncStatus { idle, picking, syncing, success, failure }

class DirectorySyncState extends Equatable {
  const DirectorySyncState({
    this.selectedDirectoryPath = '',
    this.remoteUrl = '',
    this.hasCredential = false,
    this.status = DirectorySyncStatus.idle,
    this.statusMessage = '正在准备默认同步目录。',
  });

  final String selectedDirectoryPath;
  final String remoteUrl;
  final bool hasCredential;
  final DirectorySyncStatus status;
  final String statusMessage;

  bool get canSync {
    return selectedDirectoryPath.trim().isNotEmpty &&
        remoteUrl.trim().isNotEmpty &&
        hasCredential &&
        status != DirectorySyncStatus.syncing &&
        status != DirectorySyncStatus.picking;
  }

  DirectorySyncState copyWith({
    String? selectedDirectoryPath,
    String? remoteUrl,
    bool? hasCredential,
    DirectorySyncStatus? status,
    String? statusMessage,
  }) {
    return DirectorySyncState(
      selectedDirectoryPath:
          selectedDirectoryPath ?? this.selectedDirectoryPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      hasCredential: hasCredential ?? this.hasCredential,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedDirectoryPath,
    remoteUrl,
    hasCredential,
    status,
    statusMessage,
  ];
}
