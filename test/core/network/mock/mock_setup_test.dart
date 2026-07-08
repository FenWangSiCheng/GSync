import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:flutter_foundations/core/network/mock/mock_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://mock.api'));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
  });

  test('configureMockAdapter is ready for project endpoints', () async {
    await MockSetup.configureMockAdapter(adapter);

    expect(dio.httpClientAdapter, same(adapter));
  });
}
