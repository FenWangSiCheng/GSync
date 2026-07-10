import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:native_flutter_proxy/native_flutter_proxy.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import '../config/app_config.dart';
import '../harness/harness_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'mock/mock_setup.dart';

class DioClient {
  final AppConfig _appConfig;
  late final Dio _dio;

  DioClient(this._appConfig);

  Dio get dio => _dio;

  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    HarnessLogger.event(
      'dio.initialize.start',
      fields: _appConfig.harnessContext,
    );

    _dio = Dio(_getBaseOptions());

    if (_appConfig.mockApiDataSource) {
      await _setupMockAdapter();
      HarnessLogger.event(
        'dio.mock_adapter.ready',
        fields: _appConfig.harnessContext,
      );
    } else {
      await _configureHttpClient();
      HarnessLogger.event(
        'dio.http_adapter.ready',
        fields: _appConfig.harnessContext,
      );
    }

    _dio.interceptors.addAll(_getInterceptors());
    HarnessLogger.event(
      'dio.initialize.ready',
      fields: {
        ..._appConfig.harnessContext,
        'interceptor_count': _dio.interceptors.length,
      },
    );
  }

  BaseOptions _getBaseOptions() {
    return BaseOptions(
      baseUrl: _appConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  Future<void> _configureHttpClient() async {
    final proxy = await _getSystemProxy();
    final adapter = _dio.httpClientAdapter as IOHttpClientAdapter;
    adapter.createHttpClient = () {
      final client = HttpClient();
      if (!_appConfig.isProduction && proxy.isNotEmpty) {
        client.findProxy = (uri) => proxy;
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      }
      return client;
    };
  }

  List<Interceptor> _getInterceptors() {
    return [
      const AuthInterceptor(),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ];
  }

  Future<String> _getSystemProxy() async {
    try {
      final ProxySetting settings = await NativeProxyReader.proxySetting;
      if (settings.enabled && settings.host != null && settings.port != null) {
        return 'PROXY ${settings.host}:${settings.port}';
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to get system proxy: $error');
      }
    }
    return '';
  }

  Future<void> _setupMockAdapter() async {
    final dioAdapter = DioAdapter(dio: _dio);
    _dio.httpClientAdapter = dioAdapter;
    await MockSetup.configureMockAdapter(dioAdapter);
  }
}
