// lib/core/debug/route_logging_observer.dart
import 'package:flutter/material.dart';

class RouteLoggingObserver extends NavigatorObserver {
  RouteLoggingObserver(); // non-const (fix for const super issue)

  void _log(String what, Route<dynamic>? r) {
    debugPrint('🧭 $what: ${r?.settings.name}');
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _log('PUSH', route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _log('REPLACE', newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _log('POP to', previousRoute);
    super.didPop(route, previousRoute);
  }
}
