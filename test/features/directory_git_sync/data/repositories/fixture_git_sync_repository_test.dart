import 'package:flutter_foundations/features/directory_git_sync/data/repositories/fixture_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_request.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FixtureGitSyncRepository', () {
    const repository = FixtureGitSyncRepository();

    test('returns success for the dev fixture request', () async {
      final result = await repository.syncDirectory(
        const DirectorySyncRequest(
          directoryPath: '/any/default/GitSync',
          remoteUrl: FixtureGitSyncRepository.fixtureRemoteUrl,
          credential: FixtureGitSyncRepository.fixtureCredential,
        ),
      );

      expect(result.type, DirectorySyncResultType.success);
      expect(result.commitHash, 'fixture-sync');
      expect(result.message, contains('已下载 2 个远端文件'));
    });

    test('returns failure for non-fixture credentials', () async {
      final result = await repository.syncDirectory(
        const DirectorySyncRequest(
          directoryPath: FixtureGitSyncRepository.fixtureDirectoryPath,
          remoteUrl: FixtureGitSyncRepository.fixtureRemoteUrl,
          credential: 'wrong-token',
        ),
      );

      expect(result.type, DirectorySyncResultType.failure);
      expect(result.message, contains('同步失败'));
    });
  });
}
