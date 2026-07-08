import 'dart:io';

import '../../domain/entities/directory_sync_request.dart';
import '../../domain/entities/directory_sync_result.dart';
import '../../domain/repositories/git_sync_repository.dart';
import '../datasources/git_command_runner.dart';

class ProcessGitSyncRepository implements GitSyncRepository {
  const ProcessGitSyncRepository(this._runner);

  final GitCommandRunner _runner;

  @override
  Future<DirectorySyncResult> syncDirectory(
    DirectorySyncRequest request,
  ) async {
    final directory = Directory(request.directoryPath);
    if (!directory.existsSync()) {
      return DirectorySyncResult.failure(message: '同步失败:所选目录不存在。');
    }

    final remoteUrl = _remoteUrlWithCredential(
      request.remoteUrl,
      request.credential,
    );

    try {
      if (!Directory('${directory.path}/.git').existsSync()) {
        await _run(['init'], request);
      }

      await _runAllowFailure(['remote', 'remove', 'origin'], request);
      await _run(['remote', 'add', 'origin', remoteUrl], request);
      await _run(['config', 'user.name', 'GitSync'], request);
      await _run(['config', 'user.email', 'gitsync@example.invalid'], request);
      await _run(['add', '-A'], request);

      final status = await _run(['status', '--porcelain'], request);
      if (status.stdout.trim().isEmpty) {
        return DirectorySyncResult.noChanges(message: '同步成功:没有需要提交的本地变更。');
      }

      await _run(['commit', '-m', request.commitMessage], request);
      await _run(['branch', '-M', request.branch], request);
      await _run(['push', '-u', 'origin', request.branch], request);

      final rev = await _run(['rev-parse', '--short', 'HEAD'], request);
      return DirectorySyncResult.success(
        message: '同步成功:目录已推送到远程仓库。',
        commitHash: rev.stdout.trim().isEmpty ? null : rev.stdout.trim(),
      );
    } on _GitCommandException catch (error) {
      return DirectorySyncResult.failure(
        message: _sanitize('同步失败:${error.message}', request.credential),
      );
    }
  }

  Future<GitCommandResult> _run(
    List<String> arguments,
    DirectorySyncRequest request,
  ) async {
    final result = await _runner.run(
      arguments,
      workingDirectory: request.directoryPath,
    );
    if (result.succeeded) return result;

    final details = result.stderr.trim().isEmpty
        ? result.stdout.trim()
        : result.stderr.trim();
    throw _GitCommandException(
      details.isEmpty
          ? 'Git command failed: git ${arguments.join(' ')}'
          : details,
    );
  }

  Future<void> _runAllowFailure(
    List<String> arguments,
    DirectorySyncRequest request,
  ) async {
    await _runner.run(arguments, workingDirectory: request.directoryPath);
  }

  String _remoteUrlWithCredential(String remoteUrl, String credential) {
    if (credential.isEmpty) return remoteUrl;
    final uri = Uri.tryParse(remoteUrl);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return remoteUrl;
    }
    return uri.replace(userInfo: 'x-access-token:$credential').toString();
  }

  String _sanitize(String message, String credential) {
    if (credential.isEmpty) return message;
    return message.replaceAll(credential, '********');
  }
}

class _GitCommandException implements Exception {
  const _GitCommandException(this.message);

  final String message;
}
