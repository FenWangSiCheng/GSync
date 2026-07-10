import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../token_settings/domain/usecases/get_git_token.dart';
import '../../domain/entities/directory_sync_request.dart';
import '../../domain/entities/github_repository_selection.dart';
import '../../domain/usecases/get_default_sync_directory.dart';
import '../../domain/usecases/load_github_repositories.dart';
import '../../domain/usecases/load_github_repository_branches.dart';
import '../../domain/usecases/pick_sync_directory.dart';
import '../../domain/usecases/sync_directory_to_git_repository.dart';

part 'directory_sync_event.dart';
part 'directory_sync_state.dart';

class DirectorySyncBloc extends Bloc<DirectorySyncEvent, DirectorySyncState> {
  DirectorySyncBloc({
    required GetDefaultSyncDirectory getDefaultDirectory,
    required PickSyncDirectory pickDirectory,
    required GetGitToken getGitToken,
    required SyncDirectoryToGitRepository syncDirectory,
    required LoadGitHubRepositories loadRepositories,
    required LoadGitHubRepositoryBranches loadBranches,
  }) : _getDefaultDirectory = getDefaultDirectory,
       _pickDirectory = pickDirectory,
       _getGitToken = getGitToken,
       _syncDirectory = syncDirectory,
       _loadRepositories = loadRepositories,
       _loadBranches = loadBranches,
       super(const DirectorySyncState()) {
    on<DirectorySyncStarted>(_onStarted);
    on<DirectorySyncSystemDirectoryRequested>(_onSystemDirectoryRequested);
    on<DirectorySyncTokenStatusRequested>(_onTokenStatusRequested);
    on<DirectorySyncRemoteUrlChanged>(_onRemoteUrlChanged);
    on<DirectorySyncRepositorySelected>(_onRepositorySelected);
    on<DirectorySyncBranchSelected>(_onBranchSelected);
    on<DirectorySyncRequested>(_onSyncRequested);
  }

  final GetDefaultSyncDirectory _getDefaultDirectory;
  final PickSyncDirectory _pickDirectory;
  final GetGitToken _getGitToken;
  final SyncDirectoryToGitRepository _syncDirectory;
  final LoadGitHubRepositories _loadRepositories;
  final LoadGitHubRepositoryBranches _loadBranches;

  Future<void> _onStarted(
    DirectorySyncStarted event,
    Emitter<DirectorySyncState> emit,
  ) async {
    emit(state.copyWith(status: DirectorySyncStatus.picking));
    try {
      final directoryPath = await _getDefaultDirectory();
      final token = await _getGitToken();
      final nextState = state.copyWith(
        selectedDirectoryPath: directoryPath,
        hasCredential: token != null,
        status: DirectorySyncStatus.idle,
        statusMessage: '已使用默认同步目录。',
      );
      emit(nextState);
      if (token != null) {
        await _loadRepositoryCatalog(token, emit);
      }
    } catch (_) {
      final token = await _readTokenSafely();
      emit(
        state.copyWith(
          hasCredential: token != null,
          status: DirectorySyncStatus.failure,
          statusMessage: '默认目录不可用,请手动选择目录。',
        ),
      );
      if (token != null) {
        await _loadRepositoryCatalog(token, emit);
      }
    }
  }

  Future<void> _onSystemDirectoryRequested(
    DirectorySyncSystemDirectoryRequested event,
    Emitter<DirectorySyncState> emit,
  ) async {
    emit(state.copyWith(status: DirectorySyncStatus.picking));
    final directoryPath = await _pickDirectory();
    emit(
      state.copyWith(
        selectedDirectoryPath: directoryPath ?? state.selectedDirectoryPath,
        status: DirectorySyncStatus.idle,
        statusMessage: directoryPath == null ? '已取消选择目录。' : '已选择目录。',
      ),
    );
  }

  Future<void> _onTokenStatusRequested(
    DirectorySyncTokenStatusRequested event,
    Emitter<DirectorySyncState> emit,
  ) async {
    final token = await _readTokenSafely();
    emit(state.copyWith(hasCredential: token != null));
    if (token != null) {
      await _loadRepositoryCatalog(token, emit);
    }
  }

  void _onRemoteUrlChanged(
    DirectorySyncRemoteUrlChanged event,
    Emitter<DirectorySyncState> emit,
  ) {
    emit(state.copyWith(remoteUrl: event.value));
  }

  Future<void> _onRepositorySelected(
    DirectorySyncRepositorySelected event,
    Emitter<DirectorySyncState> emit,
  ) async {
    final repository = state.repositories.where((repo) {
      return repo.fullName == event.fullName;
    }).firstOrNull;
    if (repository == null) return;

    emit(
      state.copyWith(
        selectedRepository: repository,
        clearSelectedBranch: true,
        branches: const [],
        repositoryStatus: GitHubRepositorySelectionStatus.loadingBranches,
        repositoryStatusMessage: '正在读取 ${repository.fullName} 的分支…',
      ),
    );

    final token = await _getGitToken();
    if (token == null) {
      emit(
        state.copyWith(
          hasCredential: false,
          repositoryStatus: GitHubRepositorySelectionStatus.failure,
          repositoryStatusMessage: '请先在设置中完成 GitHub 授权。',
        ),
      );
      return;
    }
    await _loadRepositoryBranches(
      repository: repository,
      token: token,
      emit: emit,
    );
  }

  void _onBranchSelected(
    DirectorySyncBranchSelected event,
    Emitter<DirectorySyncState> emit,
  ) {
    final branch = state.branches.where((item) {
      return item.name == event.name;
    }).firstOrNull;
    if (branch == null) return;
    emit(
      state.copyWith(
        selectedBranch: branch,
        repositoryStatus: GitHubRepositorySelectionStatus.ready,
        repositoryStatusMessage:
            '已选择 ${state.selectedRepository?.fullName} / ${branch.name}。',
      ),
    );
  }

  Future<void> _onSyncRequested(
    DirectorySyncRequested event,
    Emitter<DirectorySyncState> emit,
  ) async {
    final token = await _getGitToken();
    if (token == null) {
      emit(
        state.copyWith(
          hasCredential: false,
          status: DirectorySyncStatus.failure,
          statusMessage: '请先在设置中完成 GitHub 授权。',
        ),
      );
      return;
    }

    final repository = state.selectedRepository;
    final branch = state.selectedBranch;
    if (repository == null || branch == null) {
      emit(
        state.copyWith(
          status: DirectorySyncStatus.failure,
          statusMessage: '请先选择要同步的 GitHub 仓库和分支。',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        hasCredential: true,
        status: DirectorySyncStatus.syncing,
        statusMessage: '正在从 ${repository.fullName}/${branch.name} 同步到本地目录…',
      ),
    );

    try {
      final result = await _syncDirectory(
        DirectorySyncRequest(
          directoryPath: state.selectedDirectoryPath,
          remoteUrl: repository.htmlUrl,
          credential: token,
          branch: branch.name,
        ),
      );
      emit(
        state.copyWith(
          status: result.isSuccess
              ? DirectorySyncStatus.success
              : DirectorySyncStatus.failure,
          statusMessage: result.message,
        ),
      );
    } on SyncDirectoryValidationException catch (error) {
      emit(
        state.copyWith(
          status: DirectorySyncStatus.failure,
          statusMessage: error.message,
        ),
      );
    }
  }

  Future<String?> _readTokenSafely() async {
    try {
      return _getGitToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRepositoryCatalog(
    String token,
    Emitter<DirectorySyncState> emit,
  ) async {
    emit(
      state.copyWith(
        repositoryStatus: GitHubRepositorySelectionStatus.loadingRepositories,
        repositoryStatusMessage: '正在读取 GitHub 仓库…',
        repositories: const [],
        branches: const [],
        clearSelectedRepository: true,
        clearSelectedBranch: true,
      ),
    );

    try {
      final repositories = await _loadRepositories(token);
      if (repositories.isEmpty) {
        emit(
          state.copyWith(
            repositories: const [],
            branches: const [],
            clearSelectedRepository: true,
            clearSelectedBranch: true,
            repositoryStatus: GitHubRepositorySelectionStatus.failure,
            repositoryStatusMessage: '没有找到可同步的 GitHub 仓库。',
          ),
        );
        return;
      }

      final selectedRepository = repositories.first;
      emit(
        state.copyWith(
          repositories: repositories,
          selectedRepository: selectedRepository,
          branches: const [],
          clearSelectedBranch: true,
          repositoryStatus: GitHubRepositorySelectionStatus.loadingBranches,
          repositoryStatusMessage: '已读取 ${repositories.length} 个仓库,正在读取分支…',
        ),
      );
      await _loadRepositoryBranches(
        repository: selectedRepository,
        token: token,
        emit: emit,
      );
    } catch (error) {
      emit(
        state.copyWith(
          repositoryStatus: GitHubRepositorySelectionStatus.failure,
          repositoryStatusMessage: 'GitHub 仓库读取失败:${error.toString()}',
        ),
      );
    }
  }

  Future<void> _loadRepositoryBranches({
    required GitHubRepositorySummary repository,
    required String token,
    required Emitter<DirectorySyncState> emit,
  }) async {
    try {
      final branches = await _loadBranches(
        repository: repository,
        token: token,
      );
      if (branches.isEmpty) {
        emit(
          state.copyWith(
            branches: const [],
            clearSelectedBranch: true,
            repositoryStatus: GitHubRepositorySelectionStatus.failure,
            repositoryStatusMessage: '${repository.fullName} 没有可同步的分支。',
          ),
        );
        return;
      }

      final defaultBranch = branches.firstWhere(
        (branch) => branch.name == repository.defaultBranch,
        orElse: () => branches.first,
      );
      emit(
        state.copyWith(
          branches: branches,
          selectedBranch: defaultBranch,
          repositoryStatus: GitHubRepositorySelectionStatus.ready,
          repositoryStatusMessage:
              '已选择 ${repository.fullName} / ${defaultBranch.name}。',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          branches: const [],
          clearSelectedBranch: true,
          repositoryStatus: GitHubRepositorySelectionStatus.failure,
          repositoryStatusMessage: 'GitHub 分支读取失败:${error.toString()}',
        ),
      );
    }
  }
}
