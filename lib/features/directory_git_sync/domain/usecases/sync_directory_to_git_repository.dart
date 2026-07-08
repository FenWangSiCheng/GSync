import '../entities/directory_sync_request.dart';
import '../entities/directory_sync_result.dart';
import '../repositories/git_sync_repository.dart';

class SyncDirectoryValidationException implements Exception {
  const SyncDirectoryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SyncDirectoryToGitRepository {
  const SyncDirectoryToGitRepository(this._repository);

  final GitSyncRepository _repository;

  Future<DirectorySyncResult> call(DirectorySyncRequest request) {
    final directoryPath = request.directoryPath.trim();
    final remoteUrl = request.remoteUrl.trim();
    final credential = request.credential.trim();

    if (directoryPath.isEmpty) {
      throw const SyncDirectoryValidationException('Choose a directory first.');
    }
    if (remoteUrl.isEmpty) {
      throw const SyncDirectoryValidationException('Enter a Git remote URL.');
    }
    if (!_isSupportedRemoteUrl(remoteUrl)) {
      throw const SyncDirectoryValidationException(
        'Enter an HTTP(S) or SSH Git remote URL.',
      );
    }
    if (credential.isEmpty && remoteUrl.startsWith('http')) {
      throw const SyncDirectoryValidationException(
        'Enter an authentication token.',
      );
    }

    return _repository.syncDirectory(
      DirectorySyncRequest(
        directoryPath: directoryPath,
        remoteUrl: remoteUrl,
        credential: credential,
        branch: request.branch.trim().isEmpty ? 'main' : request.branch.trim(),
        commitMessage: request.commitMessage.trim().isEmpty
            ? 'Sync directory from GitSync'
            : request.commitMessage.trim(),
      ),
    );
  }

  bool _isSupportedRemoteUrl(String value) {
    if (value.startsWith('git@')) return true;
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http' || uri.scheme == 'ssh');
  }
}
