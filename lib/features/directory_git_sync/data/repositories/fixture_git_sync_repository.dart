import '../../domain/entities/directory_sync_request.dart';
import '../../domain/entities/directory_sync_result.dart';
import '../../domain/repositories/git_sync_repository.dart';

class FixtureGitSyncRepository implements GitSyncRepository {
  const FixtureGitSyncRepository();

  static const fixtureDirectoryPath = '/fixtures/GitSync';
  static const fixtureRemoteUrl = 'https://example.invalid/gitsync-fixture.git';
  static const fixtureCredential = 'test-token';

  @override
  Future<DirectorySyncResult> syncDirectory(
    DirectorySyncRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (request.directoryPath.trim().isNotEmpty &&
        request.remoteUrl == fixtureRemoteUrl &&
        request.credential == fixtureCredential) {
      return DirectorySyncResult.success(
        message: '同步成功:已从 GitHub 下载 2 个文件到本地目录。',
        commitHash: 'fixture-sync',
      );
    }

    return DirectorySyncResult.failure(message: '同步失败:请检查目录、远程地址和凭据。');
  }
}
