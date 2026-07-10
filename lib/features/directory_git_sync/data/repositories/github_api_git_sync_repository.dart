import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/directory_sync_request.dart';
import '../../domain/entities/directory_sync_result.dart';
import '../../domain/repositories/git_sync_repository.dart';
import '../datasources/directory_access_scope.dart';
import '../datasources/github_contents_api.dart';
import '../models/github_repository_target.dart';

class GithubApiGitSyncRepository implements GitSyncRepository {
  const GithubApiGitSyncRepository(
    this._api, {
    DirectoryAccessScope directoryAccessScope =
        const NoopDirectoryAccessScope(),
  }) : _directoryAccessScope = directoryAccessScope;

  final GitHubContentsApi _api;
  final DirectoryAccessScope _directoryAccessScope;

  @override
  Future<DirectorySyncResult> syncDirectory(
    DirectorySyncRequest request,
  ) async {
    final directory = Directory(request.directoryPath);
    if (!directory.existsSync()) {
      return DirectorySyncResult.failure(message: '同步失败:所选目录不存在。');
    }

    try {
      final target = _targetFor(request);
      final mirror = await _directoryAccessScope.runWithWriteAccess(
        directoryPath: directory.path,
        action: () => _mirrorRemoteDirectory(
          target: target,
          remotePath: target.targetPath,
          localDirectory: directory,
          token: request.credential,
        ),
      );

      if (mirror.downloadedFileCount == 0 && mirror.removedEntryCount == 0) {
        return DirectorySyncResult.noChanges(message: '同步完成:本地目录已与远端一致。');
      }

      return DirectorySyncResult.success(
        message:
            '同步成功:已下载 ${mirror.downloadedFileCount} 个远端文件,清理 ${mirror.removedEntryCount} 个本地残留项目。',
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

  Future<_LocalMirrorResult> _mirrorRemoteDirectory({
    required GitHubRepositoryTarget target,
    required String remotePath,
    required Directory localDirectory,
    required String token,
  }) async {
    final remoteFiles = await _readRemoteFiles(
      target: target,
      remotePath: remotePath,
      token: token,
    );
    final expectedPaths = remoteFiles.map((file) => file.relativePath).toSet();
    if (expectedPaths.length != remoteFiles.length) {
      throw const FormatException('远端目录包含重复的本地目标路径。');
    }

    var removedEntryCount = 0;
    for (final remoteFile in remoteFiles) {
      removedEntryCount += await _writeRemoteFile(
        localDirectory: localDirectory,
        remoteFile: remoteFile,
      );
    }
    removedEntryCount += await _removeLocalEntriesNotIn(
      localDirectory: localDirectory,
      expectedFilePaths: expectedPaths,
    );

    return _LocalMirrorResult(
      downloadedFileCount: remoteFiles.length,
      removedEntryCount: removedEntryCount,
    );
  }

  Future<List<_RemoteFile>> _readRemoteFiles({
    required GitHubRepositoryTarget target,
    required String remotePath,
    required String token,
  }) async {
    final remoteFiles = <_RemoteFile>[];
    final entries = await _api.fetchDirectoryEntries(
      target: target,
      path: remotePath,
      token: token,
    );

    for (final entry in entries) {
      if (entry.isDirectory) {
        remoteFiles.addAll(
          await _readRemoteFiles(
            target: target,
            remotePath: entry.path,
            token: token,
          ),
        );
        continue;
      }

      if (!entry.isFile) continue;

      remoteFiles.add(
        _RemoteFile(
          relativePath: _localRelativePath(target, entry.path),
          bytes: await _api.fetchFileBytes(
            target: target,
            path: entry.path,
            token: token,
          ),
        ),
      );
    }

    return remoteFiles;
  }

  Future<int> _writeRemoteFile({
    required Directory localDirectory,
    required _RemoteFile remoteFile,
  }) async {
    final destination = File(
      p.join(localDirectory.path, remoteFile.relativePath),
    );
    var removedEntryCount = await _ensureDirectory(
      localDirectory: localDirectory,
      directory: destination.parent,
    );
    final type = await FileSystemEntity.type(
      destination.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.directory) {
      removedEntryCount += await _deleteEntity(Directory(destination.path));
    } else if (type == FileSystemEntityType.link) {
      removedEntryCount += await _deleteEntity(Link(destination.path));
    }

    await destination.writeAsBytes(remoteFile.bytes, flush: true);
    return removedEntryCount;
  }

  Future<int> _ensureDirectory({
    required Directory localDirectory,
    required Directory directory,
  }) async {
    final rootPath = p.normalize(localDirectory.path);
    final directoryPath = p.normalize(directory.path);
    if (directoryPath != rootPath && !p.isWithin(rootPath, directoryPath)) {
      throw const FormatException('远端文件路径超出所选本地目录。');
    }

    var currentPath = rootPath;
    var removedEntryCount = 0;
    final relativePath = p.relative(directoryPath, from: rootPath);
    for (final segment in p.split(relativePath)) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') {
        throw const FormatException('远端文件路径超出所选本地目录。');
      }

      currentPath = p.join(currentPath, segment);
      final type = await FileSystemEntity.type(currentPath, followLinks: false);
      if (type == FileSystemEntityType.directory) continue;
      if (type == FileSystemEntityType.file) {
        removedEntryCount += await _deleteEntity(File(currentPath));
      } else if (type == FileSystemEntityType.link) {
        removedEntryCount += await _deleteEntity(Link(currentPath));
      }
      await Directory(currentPath).create();
    }
    return removedEntryCount;
  }

  Future<int> _removeLocalEntriesNotIn({
    required Directory localDirectory,
    required Set<String> expectedFilePaths,
  }) async {
    final expectedDirectoryPaths = _expectedDirectoryPaths(expectedFilePaths);
    final entries = await localDirectory
        .list(recursive: true, followLinks: false)
        .toList();
    entries.sort(
      (a, b) => p.split(b.path).length.compareTo(p.split(a.path).length),
    );

    var removedEntryCount = 0;
    for (final entry in entries) {
      final relativePath = _localPathWithinDirectory(
        localDirectory: localDirectory,
        entity: entry,
      );
      final type = await FileSystemEntity.type(entry.path, followLinks: false);
      final isExpected = type == FileSystemEntityType.directory
          ? expectedDirectoryPaths.contains(relativePath)
          : expectedFilePaths.contains(relativePath);
      if (!isExpected) {
        removedEntryCount += await _deleteEntity(entry);
      }
    }

    return removedEntryCount;
  }

  Set<String> _expectedDirectoryPaths(Set<String> expectedFilePaths) {
    final directories = <String>{};
    for (final filePath in expectedFilePaths) {
      var directory = p.dirname(filePath);
      while (directory.isNotEmpty && directory != '.') {
        directories.add(directory);
        directory = p.dirname(directory);
      }
    }
    return directories;
  }

  String _localPathWithinDirectory({
    required Directory localDirectory,
    required FileSystemEntity entity,
  }) {
    final rootPath = p.normalize(localDirectory.path);
    final entityPath = p.normalize(entity.path);
    if (!p.isWithin(rootPath, entityPath)) {
      throw const FormatException('本地清理路径超出所选目录。');
    }
    return p.relative(entityPath, from: rootPath);
  }

  Future<int> _deleteEntity(FileSystemEntity entity) async {
    final descendants = entity is Directory
        ? await entity.list(recursive: true, followLinks: false).length
        : 0;
    await entity.delete(recursive: entity is Directory);
    return descendants + 1;
  }

  GitHubRepositoryTarget _targetFor(DirectorySyncRequest request) {
    final target = GitHubRepositoryTarget.parse(request.remoteUrl);
    final selectedBranch = request.branch.trim();
    if (selectedBranch.isEmpty || request.remoteUrl.contains('/tree/')) {
      return target;
    }
    return target.copyWith(branch: selectedBranch);
  }

  String _localRelativePath(GitHubRepositoryTarget target, String contentPath) {
    final normalizedContentPath = _normalizeRemotePath(contentPath);
    if (target.targetPath.isEmpty) {
      return _toLocalRelativePath(normalizedContentPath);
    }

    final normalizedTargetPath = _normalizeRemotePath(target.targetPath);
    if (normalizedContentPath == normalizedTargetPath) {
      return _toLocalRelativePath(p.posix.basename(normalizedContentPath));
    }

    final prefix = '$normalizedTargetPath/';
    if (normalizedContentPath.startsWith(prefix)) {
      return _toLocalRelativePath(
        normalizedContentPath.substring(prefix.length),
      );
    }

    return _toLocalRelativePath(normalizedContentPath);
  }

  String _normalizeRemotePath(String path) {
    final segments = path
        .split('/')
        .where((segment) => segment.trim().isNotEmpty && segment != '.')
        .toList(growable: false);
    if (segments.contains('..')) {
      throw const FormatException('远端文件路径不能包含上级目录。');
    }
    return segments.join('/');
  }

  String _toLocalRelativePath(String path) {
    if (path.isEmpty) {
      throw const FormatException('远端文件缺少相对路径。');
    }
    return p.joinAll(path.split('/'));
  }

  String _sanitize(String message, String credential) {
    if (credential.isEmpty) return message;
    return message.replaceAll(credential, '********');
  }
}

class _RemoteFile {
  const _RemoteFile({required this.relativePath, required this.bytes});

  final String relativePath;
  final List<int> bytes;
}

class _LocalMirrorResult {
  const _LocalMirrorResult({
    required this.downloadedFileCount,
    required this.removedEntryCount,
  });

  final int downloadedFileCount;
  final int removedEntryCount;
}
