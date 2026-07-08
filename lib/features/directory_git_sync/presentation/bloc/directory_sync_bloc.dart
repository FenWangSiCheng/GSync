import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../token_settings/domain/usecases/get_git_token.dart';
import '../../domain/entities/directory_sync_request.dart';
import '../../domain/usecases/get_default_sync_directory.dart';
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
  }) : _getDefaultDirectory = getDefaultDirectory,
       _pickDirectory = pickDirectory,
       _getGitToken = getGitToken,
       _syncDirectory = syncDirectory,
       super(const DirectorySyncState()) {
    on<DirectorySyncStarted>(_onStarted);
    on<DirectorySyncSystemDirectoryRequested>(_onSystemDirectoryRequested);
    on<DirectorySyncTokenStatusRequested>(_onTokenStatusRequested);
    on<DirectorySyncRemoteUrlChanged>(_onRemoteUrlChanged);
    on<DirectorySyncRequested>(_onSyncRequested);
  }

  final GetDefaultSyncDirectory _getDefaultDirectory;
  final PickSyncDirectory _pickDirectory;
  final GetGitToken _getGitToken;
  final SyncDirectoryToGitRepository _syncDirectory;

  Future<void> _onStarted(
    DirectorySyncStarted event,
    Emitter<DirectorySyncState> emit,
  ) async {
    emit(state.copyWith(status: DirectorySyncStatus.picking));
    try {
      final directoryPath = await _getDefaultDirectory();
      final token = await _getGitToken();
      emit(
        state.copyWith(
          selectedDirectoryPath: directoryPath,
          hasCredential: token != null,
          status: DirectorySyncStatus.idle,
          statusMessage: '已使用默认同步目录。',
        ),
      );
    } catch (_) {
      final token = await _readTokenSafely();
      emit(
        state.copyWith(
          hasCredential: token != null,
          status: DirectorySyncStatus.failure,
          statusMessage: '默认目录不可用,请手动选择目录。',
        ),
      );
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
  }

  void _onRemoteUrlChanged(
    DirectorySyncRemoteUrlChanged event,
    Emitter<DirectorySyncState> emit,
  ) {
    emit(state.copyWith(remoteUrl: event.value));
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
          statusMessage: '请先在令牌设置中保存访问令牌。',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        hasCredential: true,
        status: DirectorySyncStatus.syncing,
        statusMessage: '正在从 GitHub 同步到本地目录…',
      ),
    );

    try {
      final result = await _syncDirectory(
        DirectorySyncRequest(
          directoryPath: state.selectedDirectoryPath,
          remoteUrl: state.remoteUrl,
          credential: token,
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
}
