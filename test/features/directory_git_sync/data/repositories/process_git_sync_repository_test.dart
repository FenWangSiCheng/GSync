import 'dart:io';

import 'package:flutter_foundations/features/directory_git_sync/data/datasources/git_command_runner.dart';
import 'package:flutter_foundations/features/directory_git_sync/data/repositories/process_git_sync_repository.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_request.dart';
import 'package:flutter_foundations/features/directory_git_sync/domain/entities/directory_sync_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcessGitSyncRepository', () {
    late Directory tempDirectory;
    late _RecordingGitCommandRunner runner;
    late ProcessGitSyncRepository repository;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'gitsync_process_repository_test_',
      );
      runner = _RecordingGitCommandRunner()
        ..statusOutput = 'A  note.md\n'
        ..revParseOutput = 'abc123\n';
      repository = ProcessGitSyncRepository(runner);
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('stores a clean remote URL and uses askpass for HTTP push', () async {
      final result = await repository.syncDirectory(
        DirectorySyncRequest(
          directoryPath: tempDirectory.path,
          remoteUrl: 'https://example.com/repo.git',
          credential: 'token-123',
        ),
      );

      expect(result.type, DirectorySyncResultType.success);
      expect(
        runner.commandLines,
        contains('remote add origin https://example.com/repo.git'),
      );
      expect(
        runner.commandLines.any((line) => line.contains('token-123')),
        isFalse,
      );

      final pushCall = runner.calls.singleWhere(
        (call) => call.arguments.join(' ') == 'push -u origin main',
      );
      expect(pushCall.environment?['GIT_TERMINAL_PROMPT'], '0');
      expect(pushCall.environment?['GIT_ASKPASS'], isNotEmpty);
    });
  });
}

class _RecordingGitCommandRunner implements GitCommandRunner {
  final List<_GitCall> calls = [];
  String statusOutput = '';
  String revParseOutput = '';

  List<String> get commandLines {
    return calls.map((call) => call.arguments.join(' ')).toList();
  }

  @override
  Future<GitCommandResult> run(
    List<String> arguments, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    calls.add(
      _GitCall(
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: environment,
      ),
    );
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

class _GitCall {
  const _GitCall({
    required this.arguments,
    required this.workingDirectory,
    required this.environment,
  });

  final List<String> arguments;
  final String workingDirectory;
  final Map<String, String>? environment;
}
