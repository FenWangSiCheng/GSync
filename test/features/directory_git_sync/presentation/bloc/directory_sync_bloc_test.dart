import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_request.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_result.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/github_repository_selection.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/default_sync_directory_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/directory_picker_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/repositories/github_repository_catalog_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/get_default_sync_directory.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/load_github_repositories.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/load_github_repository_branches.dart';
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
    late _FakeGitHubRepositoryCatalogRepository catalogRepository;

    setUp(() {
      defaultDirectoryRepository = _FakeDefaultSyncDirectoryRepository();
      directoryPickerRepository = _FakeDirectoryPickerRepository();
      tokenRepository = _FakeGitTokenRepository();
      gitSyncRepository = _SuccessfulGitSyncRepository();
      catalogRepository = _FakeGitHubRepositoryCatalogRepository();
    });

    DirectorySyncBloc buildBloc({
      GitSyncRepository? gitSyncRepositoryOverride,
      GitHubRepositoryCatalogRepository? catalogRepositoryOverride,
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
        loadRepositories: LoadGitHubRepositories(
          catalogRepositoryOverride ?? catalogRepository,
        ),
        loadBranches: LoadGitHubRepositoryBranches(
          catalogRepositoryOverride ?? catalogRepository,
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
        isA<DirectorySyncState>().having(
          (state) => state.repositoryStatus,
          'repositoryStatus',
          GitHubRepositorySelectionStatus.loadingRepositories,
        ),
        isA<DirectorySyncState>()
            .having((state) => state.repositories, 'repositories', hasLength(2))
            .having(
              (state) => state.repositoryStatus,
              'repositoryStatus',
              GitHubRepositorySelectionStatus.loadingBranches,
            ),
        isA<DirectorySyncState>()
            .having(
              (state) => state.selectedRepository?.fullName,
              'selectedRepository',
              'octocat/gitsync-fixture',
            )
            .having(
              (state) => state.selectedBranch?.name,
              'selectedBranch',
              'main',
            )
            .having(
              (state) => state.repositoryStatus,
              'repositoryStatus',
              GitHubRepositorySelectionStatus.ready,
            ),
      ],
    );

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'picks a system directory and syncs with the selected repository and branch',
      build: () {
        tokenRepository.token = FixtureGitSyncRepository.fixtureCredential;
        return buildBloc();
      },
      seed: () => DirectorySyncState(
        selectedDirectoryPath: FixtureGitSyncRepository.fixtureDirectoryPath,
        hasCredential: true,
        repositories: catalogRepository.repositories,
        branches: catalogRepository.fixtureBranches,
        selectedRepository: catalogRepository.repositories.first,
        selectedBranch: catalogRepository.fixtureBranches.last,
        repositoryStatus: GitHubRepositorySelectionStatus.ready,
      ),
      act: (bloc) {
        bloc
          ..add(const DirectorySyncSystemDirectoryRequested())
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
        expect(
          gitSyncRepository.lastRequest?.remoteUrl,
          FixtureGitSyncRepository.fixtureRemoteUrl,
        );
        expect(gitSyncRepository.lastRequest?.branch, 'dev');
      },
    );

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'reports missing GitHub authorization before syncing',
      build: buildBloc,
      seed: () => const DirectorySyncState(
        selectedDirectoryPath: '/custom/GitSync',
        selectedRepository: _FakeGitHubRepositoryCatalogRepository.fixtureRepo,
        selectedBranch: GitHubBranchSummary(name: 'main'),
        repositoryStatus: GitHubRepositorySelectionStatus.ready,
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
        hasCredential: true,
        selectedRepository: _FakeGitHubRepositoryCatalogRepository.fixtureRepo,
        selectedBranch: GitHubBranchSummary(name: 'main'),
        repositoryStatus: GitHubRepositorySelectionStatus.ready,
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

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'selects a different repository and loads its branches',
      build: () {
        tokenRepository.token = FixtureGitSyncRepository.fixtureCredential;
        return buildBloc();
      },
      seed: () => DirectorySyncState(
        selectedDirectoryPath: '/custom/GitSync',
        hasCredential: true,
        repositories: catalogRepository.repositories,
        selectedRepository: catalogRepository.repositories.first,
        branches: catalogRepository.fixtureBranches,
        selectedBranch: catalogRepository.fixtureBranches.first,
        repositoryStatus: GitHubRepositorySelectionStatus.ready,
      ),
      act: (bloc) {
        bloc.add(
          const DirectorySyncRepositorySelected('octocat/notes-archive'),
        );
      },
      expect: () => [
        isA<DirectorySyncState>()
            .having(
              (state) => state.selectedRepository?.fullName,
              'selectedRepository',
              'octocat/notes-archive',
            )
            .having(
              (state) => state.repositoryStatus,
              'repositoryStatus',
              GitHubRepositorySelectionStatus.loadingBranches,
            ),
        isA<DirectorySyncState>()
            .having(
              (state) => state.selectedRepository?.fullName,
              'selectedRepository',
              'octocat/notes-archive',
            )
            .having(
              (state) => state.selectedBranch?.name,
              'selectedBranch',
              'main',
            )
            .having(
              (state) => state.repositoryStatus,
              'repositoryStatus',
              GitHubRepositorySelectionStatus.ready,
            ),
      ],
    );

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'selects a different branch from the loaded branch list',
      build: buildBloc,
      seed: () => DirectorySyncState(
        selectedDirectoryPath: '/custom/GitSync',
        hasCredential: true,
        repositories: catalogRepository.repositories,
        selectedRepository: catalogRepository.repositories.first,
        branches: catalogRepository.fixtureBranches,
        selectedBranch: catalogRepository.fixtureBranches.first,
        repositoryStatus: GitHubRepositorySelectionStatus.ready,
      ),
      act: (bloc) => bloc.add(const DirectorySyncBranchSelected('dev')),
      expect: () => [
        isA<DirectorySyncState>()
            .having(
              (state) => state.selectedBranch?.name,
              'selectedBranch',
              'dev',
            )
            .having(
              (state) => state.repositoryStatusMessage,
              'repositoryStatusMessage',
              contains('octocat/gitsync-fixture / dev'),
            ),
      ],
    );

    blocTest<DirectorySyncBloc, DirectorySyncState>(
      'reports an empty repository catalog after authorization',
      build: () {
        tokenRepository.token = FixtureGitSyncRepository.fixtureCredential;
        return buildBloc(
          catalogRepositoryOverride: _EmptyGitHubRepositoryCatalogRepository(),
        );
      },
      act: (bloc) => bloc.add(const DirectorySyncTokenStatusRequested()),
      expect: () => [
        isA<DirectorySyncState>().having(
          (state) => state.hasCredential,
          'hasCredential',
          isTrue,
        ),
        isA<DirectorySyncState>().having(
          (state) => state.repositoryStatus,
          'repositoryStatus',
          GitHubRepositorySelectionStatus.loadingRepositories,
        ),
        isA<DirectorySyncState>()
            .having(
              (state) => state.repositoryStatus,
              'repositoryStatus',
              GitHubRepositorySelectionStatus.failure,
            )
            .having(
              (state) => state.repositoryStatusMessage,
              'repositoryStatusMessage',
              '没有找到可同步的 GitHub 仓库。',
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

class _FakeGitHubRepositoryCatalogRepository
    implements GitHubRepositoryCatalogRepository {
  static const fixtureRepo = GitHubRepositorySummary(
    owner: 'octocat',
    name: 'gitsync-fixture',
    fullName: 'octocat/gitsync-fixture',
    defaultBranch: 'main',
    htmlUrl: FixtureGitSyncRepository.fixtureRemoteUrl,
    isPrivate: false,
  );

  final repositories = const [
    fixtureRepo,
    GitHubRepositorySummary(
      owner: 'octocat',
      name: 'notes-archive',
      fullName: 'octocat/notes-archive',
      defaultBranch: 'main',
      htmlUrl: 'https://github.com/octocat/notes-archive',
      isPrivate: true,
    ),
  ];

  final fixtureBranches = const [
    GitHubBranchSummary(name: 'main'),
    GitHubBranchSummary(name: 'dev'),
  ];

  @override
  Future<List<GitHubRepositorySummary>> fetchRepositories(String token) async {
    return repositories;
  }

  @override
  Future<List<GitHubBranchSummary>> fetchBranches({
    required GitHubRepositorySummary repository,
    required String token,
  }) async {
    if (repository.fullName == fixtureRepo.fullName) {
      return fixtureBranches;
    }
    return const [GitHubBranchSummary(name: 'main')];
  }
}

class _EmptyGitHubRepositoryCatalogRepository
    implements GitHubRepositoryCatalogRepository {
  @override
  Future<List<GitHubRepositorySummary>> fetchRepositories(String token) async {
    return const [];
  }

  @override
  Future<List<GitHubBranchSummary>> fetchBranches({
    required GitHubRepositorySummary repository,
    required String token,
  }) async {
    return const [];
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
