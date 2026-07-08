import 'dart:io';

import 'package:flutter_foundations/features/directory_git_sync/data/datasources/git_command_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcessGitCommandRunner', () {
    test('runs git commands in the requested working directory', () async {
      final directory = Directory.systemTemp.createTempSync('gitsync_git_');
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      const runner = ProcessGitCommandRunner();
      final result = await runner.run(const [
        '--version',
      ], workingDirectory: directory.path);

      expect(result.succeeded, isTrue);
      expect(result.stdout, contains('git version'));
      expect(result.stderr, isEmpty);
    });
  });
}
