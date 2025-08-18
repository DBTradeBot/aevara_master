import 'package:flutter/material.dart';
import 'routing/route_paths.dart';
import 'shell/app_shell.dart';
import 'theme/aevara_theme.dart';

class AevaraApp extends StatelessWidget {
  const AevaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aevara',
      debugShowCheckedModeBanner: false,
      theme: buildAevaraTheme(brightness: Brightness.light),
      darkTheme: buildAevaraTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      initialRoute: RoutePaths.appShell,
      routes: {
        RoutePaths.appShell: (_) => const AppShell(),
      },
    );
  }
}
