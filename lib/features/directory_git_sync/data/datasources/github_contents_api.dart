import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/github_repository_target.dart';

class GitHubContentsApi {
  const GitHubContentsApi(this._client);

  final http.Client _client;

  Future<List<GitHubContentEntry>> fetchDirectoryEntries({
    required GitHubRepositoryTarget target,
    required String path,
    required String token,
  }) async {
    final response = await _client.get(
      _contentsUri(target, path, queryParameters: {'ref': target.branch}),
      headers: _headers(token),
    );

    if (response.statusCode == HttpStatus.ok) {
      return _parseEntries(jsonDecode(response.body));
    }

    throw GitHubContentsApiException(_failureMessage(response));
  }

  List<GitHubContentEntry> _parseEntries(Object? decoded) {
    final entries = switch (decoded) {
      List<Object?> list => list.whereType<Map<String, Object?>>().map(
        GitHubContentEntry.fromJson,
      ),
      Map<String, Object?> map => [GitHubContentEntry.fromJson(map)],
      _ => const <GitHubContentEntry>[],
    };
    return entries
        .where((entry) => entry.isFile || entry.isDirectory)
        .toList(growable: false);
  }

  Future<List<int>> fetchFileBytes({
    required GitHubRepositoryTarget target,
    required String path,
    required String token,
  }) async {
    final response = await _client.get(
      _contentsUri(target, path, queryParameters: {'ref': target.branch}),
      headers: _headers(token),
    );

    if (response.statusCode == HttpStatus.ok) {
      if (jsonDecode(response.body) case {
        'content': String content,
        'encoding': 'base64',
      }) {
        return base64Decode(content.replaceAll(RegExp(r'\s+'), ''));
      }
    }

    throw GitHubContentsApiException(_failureMessage(response));
  }

  Uri _contentsUri(
    GitHubRepositoryTarget target,
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final contentSegments = path
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    return Uri.https('api.github.com', '', queryParameters).replace(
      pathSegments: [
        'repos',
        target.owner,
        target.repo,
        'contents',
        ...contentSegments,
      ],
    );
  }

  Map<String, String> _headers(String token) {
    return {
      HttpHeaders.acceptHeader: 'application/vnd.github+json',
      HttpHeaders.authorizationHeader: 'Bearer $token',
      'X-GitHub-Api-Version': '2022-11-28',
    };
  }

  String _failureMessage(http.Response response) {
    final bodyMessage = _tryReadMessage(response.body);
    return switch (response.statusCode) {
      HttpStatus.unauthorized ||
      HttpStatus.forbidden => 'GitHub 认证失败,请检查访问令牌权限。',
      HttpStatus.notFound => '找不到 GitHub 仓库或目标路径,请检查地址和令牌权限。',
      _ when bodyMessage != null =>
        'GitHub API 请求失败(${response.statusCode}):$bodyMessage',
      _ => 'GitHub API 请求失败(${response.statusCode})。',
    };
  }

  String? _tryReadMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class GitHubContentsApiException implements Exception {
  const GitHubContentsApiException(this.message);

  final String message;
}

class GitHubContentEntry {
  const GitHubContentEntry({required this.path, required this.type});

  factory GitHubContentEntry.fromJson(Map<String, Object?> json) {
    return GitHubContentEntry(
      path: switch (json['path']) {
        String s => s,
        _ => '',
      },
      type: switch (json['type']) {
        String s => s,
        _ => '',
      },
    );
  }

  final String path;
  final String type;

  bool get isFile => type == 'file';

  bool get isDirectory => type == 'dir';
}
