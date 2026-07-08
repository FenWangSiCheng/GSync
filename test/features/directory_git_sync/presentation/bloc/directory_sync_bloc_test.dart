import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_request.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_result.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/directory_picker_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/pick_sync_directory.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/sync_directory_to_git_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirectorySyncBloc', () {
    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'picks a system directory and syncs successfully',
      build: () {
        return DirectorySyncBloc(
          pickDirectory: PickSyncDirectory(_FakeDirectoryPickerRepository()),
          syncDirectory: SyncDirectoryToGitRepository(
            _SuccessfulGitSyncRepository(),
          ),
        );
      },
      act: (bloc) {
        bloc
          ..add(const DirectorySyncSystemDirectoryRequested())
          ..add(
            const DirectorySyncRemoteUrlChanged(
              FixtureGitSyncRepository.fixtureRemoteUrl,
            ),
          )
          ..add(
            const DirectorySyncCredentialChanged(
              FixtureGitSyncRepository.fixtureCredential,
            ),
          )
          ..add(const DirectorySyncRequested());
      },
      expect: () => [
        isA<DirectorySyncState>().having(
          (state) => state.status,
          'status',
          DirectorySyncStatus.picking,
        ),
        isA<DirectorySyncState>()
            .having(
              (state) => state.selectedDirectoryPath,
              'selectedDirectoryPath',
              FixtureGitSyncRepository.fixtureDirectoryPath,
            )
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              'Directory selected.',
            ),
        isA<DirectorySyncState>().having(
          (state) => state.remoteUrl,
          'remoteUrl',
          FixtureGitSyncRepository.fixtureRemoteUrl,
        ),
        isA<DirectorySyncState>().having(
          (state) => state.credential,
          'credential',
          FixtureGitSyncRepository.fixtureCredential,
        ),
        isA<DirectorySyncState>().having(
          (state) => state.status,
          'status',
          DirectorySyncStatus.syncing,
        ),
        isA<DirectorySyncState>()
            .having(
              (state) => state.status,
              'status',
              DirectorySyncStatus.success,
            )
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              'Sync succeeded. Directory pushed to remote.',
            ),
      ],
    );

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'emits a readable failure state when sync fails',
      build: () {
        return DirectorySyncBloc(
          pickDirectory: PickSyncDirectory(_FakeDirectoryPickerRepository()),
          syncDirectory: SyncDirectoryToGitRepository(
            _FailingGitSyncRepository(),
          ),
        );
      },
      act: (bloc) {
        bloc
          ..add(const DirectorySyncFixtureDirectorySelected())
          ..add(
            const DirectorySyncRemoteUrlChanged(
              FixtureGitSyncRepository.fixtureRemoteUrl,
            ),
          )
          ..add(
            const DirectorySyncCredentialChanged(
              FixtureGitSyncRepository.fixtureCredential,
            ),
          )
          ..add(const DirectorySyncRequested());
      },
      expect: () => [
        isA<DirectorySyncState>().having(
          (state) => state.selectedDirectoryPath,
          'selectedDirectoryPath',
          FixtureGitSyncRepository.fixtureDirectoryPath,
        ),
        isA<DirectorySyncState>().having(
          (state) => state.remoteUrl,
          'remoteUrl',
          FixtureGitSyncRepository.fixtureRemoteUrl,
        ),
        isA<DirectorySyncState>().having(
          (state) => state.credential,
          'credential',
          FixtureGitSyncRepository.fixtureCredential,
        ),
        isA<DirectorySyncState>().having(
          (state) => state.status,
          'status',
          DirectorySyncStatus.syncing,
        ),
        isA<DirectorySyncState>()
            .having(
              (state) => state.status,
              'status',
              DirectorySyncStatus.failure,
            )
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              'Sync failed. Authentication rejected.',
            ),
      ],
    );
  });
}

class _FakeDirectoryPickerRepository implements DirectoryPickerRepository {
  @override
  Future<String?> pickDirectory() async {
    return FixtureGitSyncRepository.fixtureDirectoryPath;
  }
}

class _SuccessfulGitSyncRepository implements GitSyncRepository {
  @override
  Future<DirectorySyncResult> syncDirectory(
    DirectorySyncRequest request,
  ) async {
    return DirectorySyncResult.success(
      message: 'Sync succeeded. Directory pushed to remote.',
      commitHash: 'abc123',
    );
  }
}

class _FailingGitSyncRepository implements GitSyncRepository {
  @override
  Future<DirectorySyncResult> syncDirectory(
    DirectorySyncRequest request,
  ) async {
    return DirectorySyncResult.failure(
      message: 'Sync failed. Authentication rejected.',
    );
  }
}
