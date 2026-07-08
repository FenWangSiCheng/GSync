import 'dart:io';

class GitCommandResult {
  const GitCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get succeeded => exitCode == 0;
}

abstract class GitCommandRunner {
  Future<GitCommandResult> run(
    List<String> arguments, {
    required String workingDirectory,
  });
}

class ProcessGitCommandRunner implements GitCommandRunner {
  const ProcessGitCommandRunner();

  @override
  Future<GitCommandResult> run(
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: workingDirectory,
    );
    return GitCommandResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }
}
