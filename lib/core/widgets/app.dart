import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Banner, BannerLocation, Colors;
import 'package:flutter_localizations/flutter_localizations.dart';
import '../config/app_config.dart';
import '../injection/injection.dart';
import '../router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = getIt<AppConfig>();
    final appRouter = getIt<AppRouter>();

    return CupertinoApp.router(
      title: appConfig.appName,
      locale: const Locale('zh'),
      supportedLocales: const <Locale>[Locale('zh')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      routerConfig: appRouter.router,
      builder: (context, child) {
        return _flavorBanner(
          child: child ?? const SizedBox(),
          show: kDebugMode,
          appName: appConfig.appName,
        );
      },
    );
  }

  Widget _flavorBanner({
    required Widget child,
    required String appName,
    bool show = true,
  }) => show
      ? Banner(
          location: BannerLocation.topStart,
          message: appName,
          color: Colors.green.withValues(alpha: 0.6),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.0,
            letterSpacing: 1.0,
          ),
          textDirection: TextDirection.ltr,
          child: child,
        )
      : child;
}
