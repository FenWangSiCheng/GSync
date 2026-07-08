import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foundations/core/injection/injection.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart';
import 'package:flutter_foundations/features/directory_git_sync/presentation/pages/directory_sync_page.dart';
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
          create: (_) => getIt<DirectorySyncBloc>(),
          child: const DirectorySyncPage(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RouterPaths.home),
              child: const Text('Go to GitSync'),
            ),
          ],
        ),
      ),
    ),
  );
}
