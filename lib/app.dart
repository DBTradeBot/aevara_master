// lib/app.dart
import 'package:flutter/material.dart';
import 'routing/routes.dart';
import 'routing/route_paths.dart';
import 'core/debug/route_logging_observer.dart';
import 'core/widgets/dev_fab_overlay.dart';
import 'core/navigation/app_navigator.dart';

class AevaraApp extends StatelessWidget {
  const AevaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aevara',
      debugShowCheckedModeBanner: false,
      initialRoute: RoutePaths.signin,
      onGenerateRoute: onGenerateRoute,
      navigatorKey: appNavigatorKey,                // <-- global key
      navigatorObservers: [RouteLoggingObserver()], // logs PUSH/POP/REPLACE
      // Overlay Dev FAB across the whole app (hidden in release builds)
      builder: (context, child) => DevFabOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
      // theme: AppTheme.light,
      // darkTheme: AppTheme.dark,
    );
  }
}
