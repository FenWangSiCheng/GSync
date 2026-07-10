import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/github_repository_selection.dart';

class GitHubRepositoryCatalogApi {
  const GitHubRepositoryCatalogApi(this._client);

  final http.Client _client;

  Future<List<GitHubRepositorySummary>> fetchRepositories({
    required String token,
  }) async {
    final repositories = <GitHubRepositorySummary>[];
    var page = 1;

    while (true) {
      final response = await _client.get(
        Uri.https('api.github.com', '/user/repos', {
          'affiliation': 'owner,collaborator,organization_member',
          'sort': 'updated',
          'per_page': '100',
          'page': '$page',
        }),
        headers: _headers(token),
      );

      if (response.statusCode != HttpStatus.ok) {
        throw GitHubRepositoryCatalogApiException(_failureMessage(response));
      }

      final pageItems = _parseRepositories(jsonDecode(response.body));
      repositories.addAll(pageItems);
      if (pageItems.length < 100) break;
      page += 1;
    }

    return repositories;
  }

  Future<List<GitHubBranchSummary>> fetchBranches({
    required GitHubRepositorySummary repository,
    required String token,
  }) async {
    final branches = <GitHubBranchSummary>[];
    var page = 1;

    while (true) {
      final response = await _client.get(
        Uri.https('api.github.com', '/repos/${repository.fullName}/branches', {
          'per_page': '100',
          'page': '$page',
        }),
        headers: _headers(token),
      );

      if (response.statusCode != HttpStatus.ok) {
        throw GitHubRepositoryCatalogApiException(_failureMessage(response));
      }

      final pageItems = _parseBranches(jsonDecode(response.body));
      branches.addAll(pageItems);
      if (pageItems.length < 100) break;
      page += 1;
    }

    return branches;
  }

  List<GitHubRepositorySummary> _parseRepositories(Object? decoded) {
    if (decoded is! List<Object?>) return const [];
    return decoded
        .whereType<Map<String, Object?>>()
        .map(_repositoryFromJson)
        .where((repo) => repo.fullName.isNotEmpty && repo.htmlUrl.isNotEmpty)
        .toList(growable: false);
  }

  GitHubRepositorySummary _repositoryFromJson(Map<String, Object?> json) {
    final owner = switch (json['owner']) {
      {'login': String login} => login,
      _ => '',
    };
    final name = switch (json['name']) {
      String value => value,
      _ => '',
    };
    final fullName = switch (json['full_name']) {
      String value => value,
      _ when owner.isNotEmpty && name.isNotEmpty => '$owner/$name',
      _ => '',
    };
    return GitHubRepositorySummary(
      owner: owner,
      name: name,
      fullName: fullName,
      defaultBranch: switch (json['default_branch']) {
        String value when value.trim().isNotEmpty => value,
        _ => 'main',
      },
      htmlUrl: switch (json['html_url']) {
        String value => value,
        _ when fullName.isNotEmpty => 'https://github.com/$fullName',
        _ => '',
      },
      isPrivate: switch (json['private']) {
        bool value => value,
        _ => false,
      },
    );
  }

  List<GitHubBranchSummary> _parseBranches(Object? decoded) {
    if (decoded is! List<Object?>) return const [];
    return decoded
        .whereType<Map<String, Object?>>()
        .map(
          (json) => switch (json['name']) {
            String name when name.trim().isNotEmpty => GitHubBranchSummary(
              name: name,
            ),
            _ => null,
          },
        )
        .nonNulls
        .toList(growable: false);
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
      HttpStatus.forbidden => 'GitHub 认证失败,请重新授权后再试。',
      HttpStatus.notFound => '找不到 GitHub 仓库,请检查授权权限。',
      _ when bodyMessage != null =>
        'GitHub 仓库读取失败(${response.statusCode}):$bodyMessage',
      _ => 'GitHub 仓库读取失败(${response.statusCode})。',
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

class GitHubRepositoryCatalogApiException implements Exception {
  const GitHubRepositoryCatalogApiException(this.message);

  final String message;
}
