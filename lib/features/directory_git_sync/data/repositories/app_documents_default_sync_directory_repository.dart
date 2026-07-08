import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/default_sync_directory_repository.dart';

class AppDocumentsDefaultSyncDirectoryRepository
    implements DefaultSyncDirectoryRepository {
  const AppDocumentsDefaultSyncDirectoryRepository({
    Future<Directory> Function()? getDocumentsDirectory,
  }) : _getDocumentsDirectory =
           getDocumentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _getDocumentsDirectory;

  @override
  Future<String> resolveDefaultDirectory() async {
    final documentsDirectory = await _getDocumentsDirectory();
    final syncDirectory = Directory(p.join(documentsDirectory.path, 'GitSync'));
    if (!syncDirectory.existsSync()) {
      await syncDirectory.create(recursive: true);
    }
    return syncDirectory.path;
  }
}
