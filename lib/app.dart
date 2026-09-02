// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/routes.dart';
import 'routing/route_paths.dart';
import 'theme/aevara_theme.dart';
import 'state/theme_providers.dart';

// Global navigator key
import 'core/navigation/app_navigator.dart';

// 🔽 add this
import 'features/sync/startup_sync.dart';

/// Root widget for Aevara. Exports AevaraApp.
class AevaraApp extends ConsumerWidget {
  const AevaraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Aevara',
      debugShowCheckedModeBanner: false,
      theme: AevaraTheme.light(),
      darkTheme: AevaraTheme.dark(),
      themeMode: themeMode,

      navigatorKey: appNavigatorKey,

      // Start on the app shell; the AuthGuard in routes will redirect to /auth/signin if needed.
      initialRoute: RoutePaths.home,

      onGenerateRoute: onGenerateRoute,

      // ✅ Ensure the app tree is wrapped so 30-day compute runs when connected.
      builder: (ctx, child) => StartupSync(child: child ?? const SizedBox()),
    );
  }
}
