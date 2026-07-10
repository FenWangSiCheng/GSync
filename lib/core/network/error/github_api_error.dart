import 'dart:convert';

String? readGitHubApiMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return null;

    final message = decoded['message'];
    return message is String && message.trim().isNotEmpty
        ? message.trim()
        : null;
  } catch (_) {
    return null;
  }
}
