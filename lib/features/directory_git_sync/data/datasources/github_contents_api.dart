import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/github_repository_target.dart';

class GitHubContentsApi {
  const GitHubContentsApi(this._client);

  final http.Client _client;

  Future<String?> fetchFileSha({
    required GitHubRepositoryTarget target,
    required String path,
    required String token,
  }) async {
    final response = await _client.get(
      _contentsUri(target, path, queryParameters: {'ref': target.branch}),
      headers: _headers(token),
    );

    if (response.statusCode == HttpStatus.ok) {
      final body = _decodeObject(response.body);
      final sha = body['sha'];
      return sha is String && sha.isNotEmpty ? sha : null;
    }
    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }

    throw GitHubContentsApiException(_failureMessage(response));
  }

  Future<void> putFile({
    required GitHubRepositoryTarget target,
    required String path,
    required String contentBase64,
    required String message,
    required String token,
    String? sha,
  }) async {
    final body = <String, String>{
      'message': message,
      'content': contentBase64,
      'branch': target.branch,
    };
    if (sha != null) {
      body['sha'] = sha;
    }

    final response = await _client.put(
      _contentsUri(target, path),
      headers: {
        ..._headers(token),
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      return;
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

  Map<String, Object?> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, Object?>) return decoded;
    return const {};
  }

  String _failureMessage(http.Response response) {
    final bodyMessage = _tryReadMessage(response.body);
    if (response.statusCode == HttpStatus.unauthorized ||
        response.statusCode == HttpStatus.forbidden) {
      return 'GitHub 认证失败,请检查访问令牌权限。';
    }
    if (response.statusCode == HttpStatus.notFound) {
      return '找不到 GitHub 仓库或目标路径,请检查地址和令牌权限。';
    }
    if (bodyMessage != null) {
      return 'GitHub API 请求失败(${response.statusCode}):$bodyMessage';
    }
    return 'GitHub API 请求失败(${response.statusCode})。';
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
