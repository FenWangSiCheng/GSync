import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foundations/core/injection/injection.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/pages/directory_sync_page.dart';
import 'package:flutter_foundations/features/token_settings/presentation/bloc/token_settings_bloc.dart';
import 'package:flutter_foundations/features/token_settings/presentation/pages/token_settings_page.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'router_constants.dart';

@lazySingleton
class AppRouter {
  GoRouter get router => _router;

  final GoRouter _router = GoRouter(
    initialLocation: RouterPaths.home,
    routes: [
      GoRoute(
        path: RouterPaths.home,
        builder: (context, state) => BlocProvider(
          create: (_) =>
              getIt<DirectorySyncBloc>()..add(const DirectorySyncStarted()),
          child: const DirectorySyncPage(),
        ),
      ),
      GoRoute(
        path: RouterPaths.tokenSettings,
        builder: (context, state) => BlocProvider(
          create: (_) =>
              getIt<TokenSettingsBloc>()..add(const TokenSettingsStarted()),
          child: const TokenSettingsPage(),
        ),
      ),
    ],
    errorBuilder: (context, state) => CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('错误'),
        backgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.destructiveRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '找不到页面:${state.matchedLocation}',
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: () => context.go(RouterPaths.home),
                child: const Text('返回 GitSync'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
