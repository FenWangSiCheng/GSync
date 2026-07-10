import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_request.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_result.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/github_repository_selection.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Directory sync entities', () {
    test('request defaults to main branch and standard commit message', () {
      const request = DirectorySyncRequest(
        directoryPath: '/notes',
        remoteUrl: 'git@example.com:notes.git',
        credential: '',
      );

      expect(request.branch, 'main');
      expect(request.commitMessage, 'Sync directory from GitSync');
      expect(request.props, [
        '/notes',
        'git@example.com:notes.git',
        '',
        'main',
        'Sync directory from GitSync',
      ]);
      expect(
        request,
        equals(
          const DirectorySyncRequest(
            directoryPath: '/notes',
            remoteUrl: 'git@example.com:notes.git',
            credential: '',
          ),
        ),
      );
    });

    test('result factories expose success and failure state', () {
      final success = DirectorySyncResult.success(
        message: 'Synced',
        commitHash: 'abc123',
      );
      final noChanges = DirectorySyncResult.noChanges(
        message: 'No local changes',
      );
      final failure = DirectorySyncResult.failure(message: 'Failed');

      expect(success.isSuccess, isTrue);
      expect(success.type, DirectorySyncResultType.success);
      expect(success.commitHash, 'abc123');
      expect(noChanges.isSuccess, isTrue);
      expect(noChanges.type, DirectorySyncResultType.noChanges);
      expect(failure.isSuccess, isFalse);
      expect(failure.type, DirectorySyncResultType.failure);
    });

    test('state tracks whether sync can run', () {
      const empty = DirectorySyncState();
      final ready = empty.copyWith(
        selectedDirectoryPath: '/notes',
        hasCredential: true,
        selectedRepository: const GitHubRepositorySummary(
          owner: 'octocat',
          name: 'notes',
          fullName: 'octocat/notes',
          defaultBranch: 'main',
          htmlUrl: 'https://github.com/octocat/notes',
          isPrivate: false,
        ),
        selectedBranch: const GitHubBranchSummary(name: 'main'),
        repositoryStatus: GitHubRepositorySelectionStatus.ready,
      );
      final syncing = ready.copyWith(status: DirectorySyncStatus.syncing);

      expect(empty.canSync, isFalse);
      expect(ready.canSync, isTrue);
      expect(syncing.canSync, isFalse);
      expect(ready.statusMessage, '正在准备默认同步目录。');
    });

    test('events expose value props', () {
      expect(const DirectorySyncStarted().props, isEmpty);
      expect(const DirectorySyncSystemDirectoryRequested().props, isEmpty);
      expect(const DirectorySyncTokenStatusRequested().props, isEmpty);
      expect(
        const DirectorySyncRemoteUrlChanged(
          'https://example.com/repo.git',
        ).props,
        ['https://example.com/repo.git'],
      );
      expect(const DirectorySyncRepositorySelected('octocat/notes').props, [
        'octocat/notes',
      ]);
      expect(const DirectorySyncBranchSelected('main').props, ['main']);
      expect(const DirectorySyncRequested().props, isEmpty);
    });
  });
}
