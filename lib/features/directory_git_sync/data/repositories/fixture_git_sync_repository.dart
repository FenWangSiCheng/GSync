import '../../domain/entities/directory_sync_request.dart';
import '../../domain/entities/directory_sync_result.dart';
import '../../domain/repositories/git_sync_repository.dart';

class FixtureGitSyncRepository implements GitSyncRepository {
  const FixtureGitSyncRepository();

  static const fixtureDirectoryPath = '/fixtures/GitSync Fixture Notes';
  static const fixtureRemoteUrl = 'https://example.invalid/gitsync-fixture.git';
  static const fixtureCredential = 'test-token';

  @override
  Future<DirectorySyncResult> syncDirectory(
    DirectorySyncRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (request.directoryPath == fixtureDirectoryPath &&
        request.remoteUrl == fixtureRemoteUrl &&
        request.credential == fixtureCredential) {
      return DirectorySyncResult.success(
        message: 'Sync succeeded. Directory pushed to remote.',
        commitHash: 'fixture-sync',
      );
    }

    return DirectorySyncResult.failure(
      message: 'Sync failed. Check the directory, remote URL, and credential.',
    );
  }
}
