import 'dart:io';

import 'package:flutter_foundations/features/directory_git_sync/data/repositories/app_documents_default_sync_directory_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AppDocumentsDefaultSyncDirectoryRepository', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'gitsync_default_directory_test_',
      );
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('creates and returns the app GitSync directory', () async {
      final repository = AppDocumentsDefaultSyncDirectoryRepository(
        getDocumentsDirectory: () async => tempDirectory,
      );

      final path = await repository.resolveDefaultDirectory();

      expect(path, p.join(tempDirectory.path, 'GitSync'));
      expect(Directory(path).existsSync(), isTrue);
    });
  });
}
