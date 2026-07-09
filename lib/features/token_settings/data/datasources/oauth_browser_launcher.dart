import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract interface class OAuthBrowserLauncher {
  Future<void> open(Uri url);
}

class ChromeSafariOAuthBrowserLauncher implements OAuthBrowserLauncher {
  const ChromeSafariOAuthBrowserLauncher({
    Future<bool> Function()? isAvailable,
    Future<void> Function(Uri url)? openUrl,
  }) : _isAvailable = isAvailable ?? ChromeSafariBrowser.isAvailable,
       _openUrl = openUrl ?? _openWithChromeSafariBrowser;

  final Future<bool> Function() _isAvailable;
  final Future<void> Function(Uri url) _openUrl;

  @override
  Future<void> open(Uri url) async {
    if (!await _isAvailable()) {
      throw const OAuthBrowserLaunchException('无法打开 GitHub 授权页面。');
    }
    await _openUrl(url);
  }
}

class OAuthBrowserLaunchException implements Exception {
  const OAuthBrowserLaunchException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<void> _openWithChromeSafariBrowser(Uri url) {
  return ChromeSafariBrowser().open(url: WebUri(url.toString()));
}
