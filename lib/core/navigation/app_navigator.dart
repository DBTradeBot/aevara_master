// lib/core/navigation/app_navigator.dart
import 'package:flutter/material.dart';

/// Global navigator key the whole app shares.
/// Use this instead of `Navigator.of(context)` when your widget is not
/// under the app's Navigator (e.g., MaterialApp.builder overlays).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

NavigatorState? get nav => appNavigatorKey.currentState;
BuildContext? get navContext => appNavigatorKey.currentContext;

/// Convenience helpers (optional)
Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) {
  return nav!.pushNamed<T>(routeName, arguments: arguments);
}

Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
  String routeName, {
  TO? result,
  Object? arguments,
}) {
  return nav!.pushReplacementNamed<T, TO>(routeName,
      result: result, arguments: arguments);
}

void pop<T extends Object?>([T? result]) => nav?.pop<T>(result);

void gotoHomeAndClear(String homeRouteName) {
  nav?.pushNamedAndRemoveUntil(homeRouteName, (r) => false);
}
