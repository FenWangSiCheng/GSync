import '../repositories/default_sync_directory_repository.dart';

class GetDefaultSyncDirectory {
  const GetDefaultSyncDirectory(this._repository);

  final DefaultSyncDirectoryRepository _repository;

  Future<String> call() => _repository.resolveDefaultDirectory();
}
