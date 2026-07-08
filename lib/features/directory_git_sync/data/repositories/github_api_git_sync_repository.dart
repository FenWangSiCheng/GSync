import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/directory_sync_request.dart';
import '../../domain/entities/directory_sync_result.dart';
import '../../domain/repositories/git_sync_repository.dart';
import '../datasources/github_contents_api.dart';
import '../models/github_repository_target.dart';

class GithubApiGitSyncRepository implements GitSyncRepository {
  const GithubApiGitSyncRepository(this._api);

  final GitHubContentsApi _api;

  @override
  Future<DirectorySyncResult> syncDirectory(
    DirectorySyncRequest request,
  ) async {
    final directory = Directory(request.directoryPath);
    if (!directory.existsSync()) {
      return DirectorySyncResult.failure(message: '同步失败:所选目录不存在。');
    }

    try {
      final target = GitHubRepositoryTarget.parse(request.remoteUrl);
      final downloadedCount = await _downloadRemoteDirectory(
        target: target,
        remotePath: target.targetPath,
        localDirectory: directory,
        token: request.credential,
      );

      if (downloadedCount == 0) {
        return DirectorySyncResult.noChanges(message: '同步完成:远程目录没有可下载的文件。');
      }

      return DirectorySyncResult.success(
        message: '同步成功:已从 GitHub 下载 $downloadedCount 个文件到本地目录。',
      );
    } on GitHubRepositoryTargetFormatException {
      return DirectorySyncResult.failure(
        message:
            '同步失败:请输入 GitHub 仓库地址,例如 https://github.com/owner/repo/tree/main/notes。',
      );
    } on GitHubContentsApiException catch (error) {
      return DirectorySyncResult.failure(
        message: _sanitize('同步失败:${error.message}', request.credential),
      );
    } catch (error) {
      return DirectorySyncResult.failure(
        message: _sanitize('同步失败:${error.toString()}', request.credential),
      );
    }
  }

  Future<int> _downloadRemoteDirectory({
    required GitHubRepositoryTarget target,
    required String remotePath,
    required Directory localDirectory,
    required String token,
  }) async {
    var downloadedCount = 0;
    final entries = await _api.fetchDirectoryEntries(
      target: target,
      path: remotePath,
      token: token,
    );

    for (final entry in entries) {
      if (entry.isDirectory) {
        downloadedCount += await _downloadRemoteDirectory(
          target: target,
          remotePath: entry.path,
          localDirectory: localDirectory,
          token: token,
        );
        continue;
      }

      if (!entry.isFile) continue;

      final relativePath = _localRelativePath(target, entry.path);
      final destination = File(p.join(localDirectory.path, relativePath));
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(
        await _api.fetchFileBytes(
          target: target,
          path: entry.path,
          token: token,
        ),
        flush: true,
      );
      downloadedCount += 1;
    }

    return downloadedCount;
  }

  String _localRelativePath(GitHubRepositoryTarget target, String contentPath) {
    final normalizedContentPath = _normalizeRemotePath(contentPath);
    if (target.targetPath.isEmpty) return normalizedContentPath;

    final normalizedTargetPath = _normalizeRemotePath(target.targetPath);
    if (normalizedContentPath == normalizedTargetPath) {
      return p.posix.basename(normalizedContentPath);
    }

    final prefix = '$normalizedTargetPath/';
    if (normalizedContentPath.startsWith(prefix)) {
      return normalizedContentPath.substring(prefix.length);
    }

    return normalizedContentPath;
  }

  String _normalizeRemotePath(String path) {
    return path
        .split('/')
        .where((segment) => segment.trim().isNotEmpty && segment != '.')
        .join('/');
  }

  String _sanitize(String message, String credential) {
    if (credential.isEmpty) return message;
    return message.replaceAll(credential, '********');
  }
}
