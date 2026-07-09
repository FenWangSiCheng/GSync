import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/core/router/app_router.dart';
import 'package:flutter_foundations/core/router/router_constants.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AppRouter', () {
    late AppRouter appRouter;

    setUp(() {
      appRouter = AppRouter();
    });

    test('router should not be null', () {
      expect(appRouter.router, isNotNull);
      expect(appRouter.router, isA<GoRouter>());
    });

    test('router should have routes configured', () {
      expect(appRouter.router.configuration.routes, isNotEmpty);
    });

    test('router should have home route', () {
      final routes = appRouter.router.configuration.routes;
      final homeRoute = routes.firstWhere(
        (route) => (route as GoRoute).path == RouterPaths.home,
      );
      expect(homeRoute, isNotNull);
    });

    test('router should expose app routes', () {
      final routes = appRouter.router.configuration.routes;
      expect(routes.map((route) => (route as GoRoute).path), [
        RouterPaths.home,
        RouterPaths.tokenSettings,
      ]);
    });

    test('router should have correct initial location', () {
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        RouterPaths.home,
      );
    });

    group('Multiple instances', () {
      test('should create independent router instances', () {
        final router1 = AppRouter();
        final router2 = AppRouter();

        expect(router1.router, isNot(same(router2.router)));
      });
    });
  });
}
