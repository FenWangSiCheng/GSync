part of 'directory_sync_bloc.dart';

enum DirectorySyncStatus { idle, picking, syncing, success, failure }

enum GitHubRepositorySelectionStatus {
  idle,
  loadingRepositories,
  loadingBranches,
  ready,
  failure,
}

class DirectorySyncState extends Equatable {
  const DirectorySyncState({
    this.selectedDirectoryPath = '',
    this.remoteUrl = '',
    this.hasCredential = false,
    this.repositories = const [],
    this.branches = const [],
    this.selectedRepository,
    this.selectedBranch,
    this.repositoryStatus = GitHubRepositorySelectionStatus.idle,
    this.repositoryStatusMessage = '完成 GitHub 授权后会显示仓库。',
    this.status = DirectorySyncStatus.idle,
    this.statusMessage = '正在准备默认同步目录。',
  });

  final String selectedDirectoryPath;
  final String remoteUrl;
  final bool hasCredential;
  final List<GitHubRepositorySummary> repositories;
  final List<GitHubBranchSummary> branches;
  final GitHubRepositorySummary? selectedRepository;
  final GitHubBranchSummary? selectedBranch;
  final GitHubRepositorySelectionStatus repositoryStatus;
  final String repositoryStatusMessage;
  final DirectorySyncStatus status;
  final String statusMessage;

  bool get canSync {
    return selectedDirectoryPath.trim().isNotEmpty &&
        selectedRepository != null &&
        selectedBranch != null &&
        hasCredential &&
        repositoryStatus == GitHubRepositorySelectionStatus.ready &&
        status != DirectorySyncStatus.syncing &&
        status != DirectorySyncStatus.picking;
  }

  DirectorySyncState copyWith({
    String? selectedDirectoryPath,
    String? remoteUrl,
    bool? hasCredential,
    List<GitHubRepositorySummary>? repositories,
    List<GitHubBranchSummary>? branches,
    GitHubRepositorySummary? selectedRepository,
    GitHubBranchSummary? selectedBranch,
    bool clearSelectedRepository = false,
    bool clearSelectedBranch = false,
    GitHubRepositorySelectionStatus? repositoryStatus,
    String? repositoryStatusMessage,
    DirectorySyncStatus? status,
    String? statusMessage,
  }) {
    return DirectorySyncState(
      selectedDirectoryPath:
          selectedDirectoryPath ?? this.selectedDirectoryPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      hasCredential: hasCredential ?? this.hasCredential,
      repositories: repositories ?? this.repositories,
      branches: branches ?? this.branches,
      selectedRepository: clearSelectedRepository
          ? null
          : selectedRepository ?? this.selectedRepository,
      selectedBranch: clearSelectedBranch
          ? null
          : selectedBranch ?? this.selectedBranch,
      repositoryStatus: repositoryStatus ?? this.repositoryStatus,
      repositoryStatusMessage:
          repositoryStatusMessage ?? this.repositoryStatusMessage,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedDirectoryPath,
    remoteUrl,
    hasCredential,
    repositories,
    branches,
    selectedRepository,
    selectedBranch,
    repositoryStatus,
    repositoryStatusMessage,
    status,
    statusMessage,
  ];
}
