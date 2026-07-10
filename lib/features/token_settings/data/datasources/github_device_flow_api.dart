import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/github_device_authorization.dart';
import '../../domain/entities/github_device_token_poll_result.dart';
import '../../domain/repositories/github_device_flow_repository.dart';

class GitHubDeviceFlowApi {
  const GitHubDeviceFlowApi(this._client);

  static const _deviceGrantType =
      'urn:ietf:params:oauth:grant-type:device_code';

  final http.Client _client;

  Future<GitHubDeviceAuthorization> requestDeviceCode({
    required String clientId,
    required String scope,
  }) async {
    final body = <String, String>{'client_id': clientId};
    if (scope.trim().isNotEmpty) {
      body['scope'] = scope.trim();
    }

    final response = await _client.post(
      Uri.https('github.com', '/login/device/code'),
      headers: _headers,
      body: body,
    );
    final decoded = _decodeResponse(response);

    if (response.statusCode == HttpStatus.ok &&
        decoded is Map<String, Object?>) {
      if (decoded['error'] case final String error) {
        throw GitHubDeviceFlowException(_oauthErrorMessage(error, decoded));
      }
      return _authorizationFromJson(decoded);
    }

    throw GitHubDeviceFlowException(_failureMessage(response, decoded));
  }

  Future<GitHubDeviceTokenPollResult> pollToken({
    required String clientId,
    required String deviceCode,
  }) async {
    final response = await _client.post(
      Uri.https('github.com', '/login/oauth/access_token'),
      headers: _headers,
      body: {
        'client_id': clientId,
        'device_code': deviceCode,
        'grant_type': _deviceGrantType,
      },
    );
    final decoded = _decodeResponse(response);

    if (response.statusCode == HttpStatus.ok &&
        decoded is Map<String, Object?>) {
      if (decoded['access_token'] case final String token
          when token.trim().isNotEmpty) {
        return GitHubDeviceTokenAuthorized(
          accessToken: token,
          tokenType: _stringValue(decoded['token_type']) ?? 'bearer',
          scope: _stringValue(decoded['scope']) ?? '',
        );
      }
      if (decoded['error'] case final String error) {
        return _pollErrorResult(error, decoded);
      }
    }

    throw GitHubDeviceFlowException(_failureMessage(response, decoded));
  }

  Map<String, String> get _headers => const {
    HttpHeaders.acceptHeader: 'application/json',
  };

  GitHubDeviceAuthorization _authorizationFromJson(Map<String, Object?> json) {
    final deviceCode = _requiredString(json, 'device_code');
    final userCode = _requiredString(json, 'user_code');
    final verificationUri = Uri.tryParse(
      _requiredString(json, 'verification_uri'),
    );
    if (verificationUri == null) {
      throw const GitHubDeviceFlowException('GitHub 返回了无效的授权地址。');
    }
    return GitHubDeviceAuthorization(
      deviceCode: deviceCode,
      userCode: userCode,
      verificationUri: verificationUri,
      expiresIn: Duration(seconds: _requiredInt(json, 'expires_in')),
      interval: Duration(seconds: _intValue(json['interval']) ?? 5),
    );
  }

  GitHubDeviceTokenPollResult _pollErrorResult(
    String error,
    Map<String, Object?> json,
  ) {
    return switch (error) {
      'authorization_pending' => const GitHubDeviceTokenPending(),
      'slow_down' => GitHubDeviceTokenSlowDown(
        Duration(seconds: _intValue(json['interval']) ?? 10),
      ),
      'expired_token' || 'token_expired' => const GitHubDeviceTokenExpired(),
      'access_denied' => const GitHubDeviceTokenDenied(),
      _ => throw GitHubDeviceFlowException(_oauthErrorMessage(error, json)),
    };
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
    return 'GitHub 授权请求失败(${response.statusCode})。';
  }

  String _oauthErrorMessage(String error, Map<String, Object?> json) {
    final description = _stringValue(json['error_description']);
    if (description != null && description.trim().isNotEmpty) {
      return 'GitHub 授权失败:$description';
    }
    return switch (error) {
      'incorrect_client_credentials' => 'GitHub OAuth Client ID 无效。',
      'device_flow_disabled' => 'GitHub OAuth App 未启用 Device Flow。',
      'incorrect_device_code' => 'GitHub 设备码无效,请重新授权。',
      'unsupported_grant_type' => 'GitHub Device Flow grant type 不受支持。',
      _ => 'GitHub 授权失败:$error',
    };
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final value = _stringValue(json[key]);
    if (value == null || value.trim().isEmpty) {
      throw GitHubDeviceFlowException('GitHub 授权响应缺少 $key。');
    }
    return value;
  }

  int _requiredInt(Map<String, Object?> json, String key) {
    final value = _intValue(json[key]);
    if (value == null) {
      throw GitHubDeviceFlowException('GitHub 授权响应缺少 $key。');
    }
    return value;
  }

  String? _stringValue(Object? value) {
    return switch (value) {
      String s => s,
      _ => null,
    };
  }

  int? _intValue(Object? value) {
    return switch (value) {
      int i => i,
      double d => d.toInt(),
      String s => int.tryParse(s),
      _ => null,
    };
  }
}
