import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/fixture_git_sync_repository.dart';
import '../../domain/entities/directory_sync_request.dart';
import '../../domain/usecases/pick_sync_directory.dart';
import '../../domain/usecases/sync_directory_to_git_repository.dart';

part 'directory_sync_event.dart';
part 'directory_sync_state.dart';

class DirectorySyncBloc extends Bloc<DirectorySyncEvent, DirectorySyncState> {
  DirectorySyncBloc({
    required PickSyncDirectory pickDirectory,
    required SyncDirectoryToGitRepository syncDirectory,
  }) : _pickDirectory = pickDirectory,
       _syncDirectory = syncDirectory,
       super(const DirectorySyncState()) {
    on<DirectorySyncSystemDirectoryRequested>(_onSystemDirectoryRequested);
    on<DirectorySyncFixtureDirectorySelected>(_onFixtureDirectorySelected);
    on<DirectorySyncRemoteUrlChanged>(_onRemoteUrlChanged);
    on<DirectorySyncCredentialChanged>(_onCredentialChanged);
    on<DirectorySyncRequested>(_onSyncRequested);
  }

  final PickSyncDirectory _pickDirectory;
  final SyncDirectoryToGitRepository _syncDirectory;

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
        statusMessage: directoryPath == null
            ? 'Directory selection cancelled.'
            : 'Directory selected.',
      ),
    );
  }

  void _onFixtureDirectorySelected(
    DirectorySyncFixtureDirectorySelected event,
    Emitter<DirectorySyncState> emit,
  ) {
    emit(
      state.copyWith(
        selectedDirectoryPath: FixtureGitSyncRepository.fixtureDirectoryPath,
        status: DirectorySyncStatus.idle,
        statusMessage: 'Directory selected.',
      ),
    );
  }

  void _onRemoteUrlChanged(
    DirectorySyncRemoteUrlChanged event,
    Emitter<DirectorySyncState> emit,
  ) {
    emit(state.copyWith(remoteUrl: event.value));
  }

  void _onCredentialChanged(
    DirectorySyncCredentialChanged event,
    Emitter<DirectorySyncState> emit,
  ) {
    emit(state.copyWith(credential: event.value));
  }

  Future<void> _onSyncRequested(
    DirectorySyncRequested event,
    Emitter<DirectorySyncState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DirectorySyncStatus.syncing,
        statusMessage: 'Syncing selected directory...',
      ),
    );

    try {
      final result = await _syncDirectory(
        DirectorySyncRequest(
          directoryPath: state.selectedDirectoryPath,
          remoteUrl: state.remoteUrl,
          credential: state.credential,
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
}
