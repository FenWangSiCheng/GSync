import 'dart:io';

import 'package:flutter_foundations/features/directory_git_sync/data/datasources/git_command_runner.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/process_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_request.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_result.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/usecases/sync_directory_to_git_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncDirectoryToGitRepository', () {
    late Directory tempDirectory;
    late _FakeGitCommandRunner runner;
    late SyncDirectoryToGitRepository useCase;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync('gitsync_test_');
      runner = _FakeGitCommandRunner();
      useCase = SyncDirectoryToGitRepository(ProcessGitSyncRepository(runner));
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('stages, commits, and pushes selected directory changes', () async {
      runner.statusOutput = 'A  note.md\n';
      runner.revParseOutput = 'abc123\n';

      final result = await useCase(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://example.com/repo.git',
          credential: 'token-123',
        ),
      );

      expect(result.type, DirectorySyncResultType.success);
      expect(result.commitHash, 'abc123');
      expect(runner.commandLines, contains('add -A'));
      expect(
        runner.commandLines,
        contains('commit -m Sync directory from GitSync'),
      );
      expect(runner.commandLines, contains('branch -M main'));
      expect(runner.commandLines, contains('push -u origin main'));
    });

    test('reports success without creating an empty commit', () async {
      runner.statusOutput = '';

      final result = await useCase(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://example.com/repo.git',
          credential: 'token-123',
        ),
      );

      expect(result.type, DirectorySyncResultType.noChanges);
      expect(
        runner.commands.any((command) => command.contains('commit')),
        isFalse,
      );
      expect(
        runner.commands.any((command) => command.contains('push')),
        isFalse,
      );
    });

    test('returns a sanitized failure when a git command fails', () async {
      runner.statusOutput = 'A  note.md\n';
      runner.failCommand = 'push -u origin main';
      runner.failureMessage = 'remote rejected token-123';

      final result = await useCase(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://example.com/repo.git',
          credential: 'token-123',
        ),
      );

      expect(result.type, DirectorySyncResultType.failure);
      expect(result.message, contains('remote rejected ********'));
      expect(result.message, isNot(contains('token-123')));
    });

    test('validates required request fields before running git', () async {
      expect(
        () => useCase(
          const DirectorySyncRequest(
            directoryPath: '',
            remoteUrl: 'https://example.com/repo.git',
            credential: 'token-123',
          ),
        ),
        throwsA(isA<SyncDirectoryValidationException>()),
      );
      expect(
        () => useCase(
          DirectorySyncRequest(
            directoryPath: tempDirectory.path,
            remoteUrl: '',
            credential: 'token-123',
          ),
        ),
        throwsA(isA<SyncDirectoryValidationException>()),
      );
      expect(
        () => useCase(
          DirectorySyncRequest(
            directoryPath: tempDirectory.path,
            remoteUrl: 'ftp://example.com/repo.git',
            credential: 'token-123',
          ),
        ),
        throwsA(isA<SyncDirectoryValidationException>()),
      );
      expect(
        () => useCase(
          DirectorySyncRequest(
            directoryPath: tempDirectory.path,
            remoteUrl: 'https://example.com/repo.git',
            credential: '',
          ),
        ),
        throwsA(isA<SyncDirectoryValidationException>()),
      );

      expect(runner.commands, isEmpty);
    });
  });
}

class _FakeGitCommandRunner implements GitCommandRunner {
  final List<List<String>> commands = [];
  String statusOutput = '';
  String revParseOutput = '';
  String failCommand = '';
  String failureMessage = '';

  List<String> get commandLines {
    return commands.map((command) => command.join(' ')).toList();
  }

  @override
  Future<GitCommandResult> run(
    List<String> arguments, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    commands.add(arguments);
    if (arguments.join(' ') == failCommand) {
      return GitCommandResult(exitCode: 1, stdout: '', stderr: failureMessage);
    }
    if (arguments.length == 2 &&
        arguments[0] == 'status' &&
        arguments[1] == '--porcelain') {
      return GitCommandResult(exitCode: 0, stdout: statusOutput, stderr: '');
    }
    if (arguments.length == 3 &&
        arguments[0] == 'rev-parse' &&
        arguments[1] == '--short' &&
        arguments[2] == 'HEAD') {
      return GitCommandResult(exitCode: 0, stdout: revParseOutput, stderr: '');
    }
    return const GitCommandResult(exitCode: 0, stdout: '', stderr: '');
  }
}
