import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: PostfolioApp()));
}

class PostfolioApp extends ConsumerWidget {
  const PostfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Postfolio',
      theme: AppTheme.lightTheme, // Apply centralized theme
      routerConfig: goRouter,
    );
  }
}
