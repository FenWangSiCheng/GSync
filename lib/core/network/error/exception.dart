class ApiException implements Exception {
  const ApiException(this.message, {this.errorCode, this.details});

  final String message;
  final int? errorCode;
  final Map<String, dynamic>? details;

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (errorCode != null) {
      buffer.write(' (Code: $errorCode)');
    }
    return buffer.toString();
  }

  factory ApiException.withCode(String message, int errorCode) =>
      ApiException(message, errorCode: errorCode);

  factory ApiException.withDetails(
    String message, {
    int? errorCode,
    Map<String, dynamic>? details,
  }) => ApiException(message, errorCode: errorCode, details: details);
}
