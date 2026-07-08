import 'dart:convert';
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
      final files = await _listFiles(directory);
      if (files.isEmpty) {
        return DirectorySyncResult.noChanges(message: '同步成功:没有需要上传的本地文件。');
      }

      for (final file in files) {
        final relativePath = _relativePosixPath(directory, file);
        final contentPath = target.contentPathFor(relativePath);
        final sha = await _api.fetchFileSha(
          target: target,
          path: contentPath,
          token: request.credential,
        );
        await _api.putFile(
          target: target,
          path: contentPath,
          contentBase64: base64Encode(await file.readAsBytes()),
          message: request.commitMessage,
          token: request.credential,
          sha: sha,
        );
      }

      return DirectorySyncResult.success(
        message: '同步成功:已通过 GitHub API 上传 ${files.length} 个文件。',
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

  Future<List<File>> _listFiles(Directory directory) async {
    final files = <File>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      if (_isInsideGitDirectory(directory, entity)) continue;
      files.add(entity);
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  bool _isInsideGitDirectory(Directory root, File file) {
    final relative = _relativePosixPath(root, file);
    return relative == '.git' || relative.startsWith('.git/');
  }

  String _relativePosixPath(Directory root, File file) {
    final relative = p.relative(file.path, from: root.path);
    return p.split(relative).join('/');
  }

  String _sanitize(String message, String credential) {
    if (credential.isEmpty) return message;
    return message.replaceAll(credential, '********');
  }
}
