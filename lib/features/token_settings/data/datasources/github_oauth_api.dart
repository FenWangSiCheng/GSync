import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/github_oauth_token.dart';
import '../../domain/repositories/github_oauth_redirect_repository.dart';

class GitHubOAuthApi {
  const GitHubOAuthApi(this._client);

  final http.Client _client;

  Future<GitHubOAuthToken> exchangeCode({
    required String clientId,
    required String code,
    required Uri redirectUri,
    required String codeVerifier,
  }) async {
    final response = await _client.post(
      Uri.https('github.com', '/login/oauth/access_token'),
      headers: const {HttpHeaders.acceptHeader: 'application/json'},
      body: {
        'client_id': clientId,
        'code': code,
        'redirect_uri': redirectUri.toString(),
        'code_verifier': codeVerifier,
      },
    );
    final decoded = _decodeResponse(response);

    if (response.statusCode == HttpStatus.ok &&
        decoded is Map<String, Object?>) {
      if (decoded['access_token'] case final String token
          when token.trim().isNotEmpty) {
        return GitHubOAuthToken(
          accessToken: token,
          tokenType: _stringValue(decoded['token_type']) ?? 'bearer',
          scope: _stringValue(decoded['scope']) ?? '',
        );
      }
      if (decoded['error'] case final String error) {
        throw GitHubOAuthRedirectException(_oauthErrorMessage(error, decoded));
      }
    }

    throw GitHubOAuthRedirectException(_failureMessage(response, decoded));
  }

  Object? _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  String _failureMessage(http.Response response, Object? decoded) {
    if (decoded is Map<String, Object?>) {
      final error = decoded['error'];
      if (error is String) {
        return _oauthErrorMessage(error, decoded);
      }
    }
    return 'GitHub 授权换取令牌失败(${response.statusCode})。';
  }

  String _oauthErrorMessage(String error, Map<String, Object?> json) {
    final description = _stringValue(json['error_description']);
    if (description != null && description.trim().isNotEmpty) {
      return 'GitHub 授权失败:$description';
    }
    return switch (error) {
      'bad_verification_code' => 'GitHub 授权 code 无效,请重新授权。',
      'incorrect_client_credentials' => 'GitHub OAuth Client ID 无效。',
      'redirect_uri_mismatch' => 'GitHub OAuth 回调地址不匹配。',
      _ => 'GitHub 授权失败:$error',
    };
  }

  String? _stringValue(Object? value) {
    return switch (value) {
      String s => s,
      _ => null,
    };
  }
}
