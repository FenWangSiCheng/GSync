import '../entities/directory_sync_request.dart';
import '../entities/directory_sync_result.dart';

abstract class GitSyncRepository {
  Future<DirectorySyncResult> syncDirectory(DirectorySyncRequest request);
}
