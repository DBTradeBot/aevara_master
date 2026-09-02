// Minimal DeeplinkService: centralizes handling if app receives a deeplink via
// platform hooks (Android intent-filter / iOS URL scheme). We keep a single
// entry point `dispatch(Uri)` you can call from platform channels later.
// No external packages required.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef DeeplinkHandler = FutureOr<void> Function(Uri uri);

class DeeplinkService {
  DeeplinkService._();
  static final DeeplinkService instance = DeeplinkService._();

  final List<DeeplinkHandler> _handlers = <DeeplinkHandler>[];

  void register(DeeplinkHandler h) {
    if (!_handlers.contains(h)) _handlers.add(h);
  }

  void unregister(DeeplinkHandler h) {
    _handlers.remove(h);
  }

  /// Call this with the incoming URI (e.g., aevara://oauth?provider=fitbit&status=ok)
  Future<void> dispatch(Uri uri) async {
    for (final h in List<DeeplinkHandler>.from(_handlers)) {
      try {
        await h(uri);
      } catch (e, st) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Deeplink handler error: $e\n$st');
        }
      }
    }
  }
}
