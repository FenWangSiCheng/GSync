import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_request.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_result.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/default_sync_directory_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/directory_picker_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/get_default_sync_directory.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/pick_sync_directory.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/sync_directory_to_git_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart';
import 'package:flutter_foundations/features/token_settings/domain/repositories/git_token_repository.dart';
import 'package:flutter_foundations/features/token_settings/domain/usecases/get_git_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirectorySyncBloc', () {
    late _FakeDefaultSyncDirectoryRepository defaultDirectoryRepository;
    late _FakeDirectoryPickerRepository directoryPickerRepository;
    late _FakeGitTokenRepository tokenRepository;
    late _SuccessfulGitSyncRepository gitSyncRepository;

    setUp(() {
      defaultDirectoryRepository = _FakeDefaultSyncDirectoryRepository();
      directoryPickerRepository = _FakeDirectoryPickerRepository();
      tokenRepository = _FakeGitTokenRepository();
      gitSyncRepository = _SuccessfulGitSyncRepository();
    });

    DirectorySyncBloc buildBloc({
      GitSyncRepository? gitSyncRepositoryOverride,
    }) {
      return DirectorySyncBloc(
        getDefaultDirectory: GetDefaultSyncDirectory(
          defaultDirectoryRepository,
        ),
        pickDirectory: PickSyncDirectory(directoryPickerRepository),
        getGitToken: GetGitToken(tokenRepository),
        syncDirectory: SyncDirectoryToGitRepository(
          gitSyncRepositoryOverride ?? gitSyncRepository,
        ),
      );
    }

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'loads a default directory and saved token status',
      build: () {
        tokenRepository.token = FixtureGitSyncRepository.fixtureCredential;
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DirectorySyncStarted()),
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
            .having((state) => state.hasCredential, 'hasCredential', isTrue)
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              '已使用默认同步目录。',
            ),
      ],
    );

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'picks a system directory and syncs with the saved token',
      build: () {
        tokenRepository.token = FixtureGitSyncRepository.fixtureCredential;
        return buildBloc();
      },
      seed: () => DirectorySyncState(
        selectedDirectoryPath: FixtureGitSyncRepository.fixtureDirectoryPath,
        hasCredential: true,
      ),
      act: (bloc) {
        bloc
          ..add(const DirectorySyncSystemDirectoryRequested())
          ..add(
            const DirectorySyncRemoteUrlChanged(
              FixtureGitSyncRepository.fixtureRemoteUrl,
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
              '/custom/GitSync',
            )
            .having((state) => state.statusMessage, 'statusMessage', '已选择目录。'),
        isA<DirectorySyncState>().having(
          (state) => state.remoteUrl,
          'remoteUrl',
          FixtureGitSyncRepository.fixtureRemoteUrl,
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
              '同步成功:目录已推送到远程仓库。',
            ),
      ],
      verify: (_) {
        expect(gitSyncRepository.lastRequest?.credential, 'test-token');
        expect(gitSyncRepository.lastRequest?.directoryPath, '/custom/GitSync');
      },
    );

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'reports missing GitHub authorization before syncing',
      build: buildBloc,
      seed: () => const DirectorySyncState(
        selectedDirectoryPath: '/custom/GitSync',
        remoteUrl: FixtureGitSyncRepository.fixtureRemoteUrl,
      ),
      act: (bloc) => bloc.add(const DirectorySyncRequested()),
      expect: () => [
        isA<DirectorySyncState>()
            .having(
              (state) => state.status,
              'status',
              DirectorySyncStatus.failure,
            )
            .having(
              (state) => state.statusMessage,
              'statusMessage',
              '请先在设置中完成 GitHub 授权。',
            ),
      ],
    );

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'emits a readable failure state when sync fails',
      build: () {
        tokenRepository.token = FixtureGitSyncRepository.fixtureCredential;
        return buildBloc(
          gitSyncRepositoryOverride: _FailingGitSyncRepository(),
        );
      },
      seed: () => const DirectorySyncState(
        selectedDirectoryPath: '/custom/GitSync',
        remoteUrl: FixtureGitSyncRepository.fixtureRemoteUrl,
        hasCredential: true,
      ),
      act: (bloc) => bloc.add(const DirectorySyncRequested()),
      expect: () => [
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
              '同步失败:认证被拒绝。',
            ),
      ],
    );
  });
}

class _FakeDefaultSyncDirectoryRepository
    implements DefaultSyncDirectoryRepository {
  @override
  Future<String> resolveDefaultDirectory() async {
    return FixtureGitSyncRepository.fixtureDirectoryPath;
  }
}

class _FakeDirectoryPickerRepository implements DirectoryPickerRepository {
  @override
  Future<String?> pickDirectory() async {
    return '/custom/GitSync';
  }
}

class _FakeGitTokenRepository implements GitTokenRepository {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }
}

class _SuccessfulGitSyncRepository implements GitSyncRepository {
  DirectorySyncRequest? lastRequest;

  @override
  Future<DirectorySyncResult> syncDirectory(
    DirectorySyncRequest request,
  ) async {
    lastRequest = request;
    return DirectorySyncResult.success(
      message: '同步成功:目录已推送到远程仓库。',
      commitHash: 'abc123',
    );
  }
}

class _FailingGitSyncRepository implements GitSyncRepository {
  @override
  Future<DirectorySyncResult> syncDirectory(
    DirectorySyncRequest request,
  ) async {
    return DirectorySyncResult.failure(message: '同步失败:认证被拒绝。');
  }
}
