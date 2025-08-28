// lib/shell/home_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/guards/auth_guard.dart';
import 'app_shell.dart';

/// Wraps the tabbed AppShell in guards.
/// - AuthGuard: redirects to /auth/signin if there is no Firebase user.
/// - (Future) add ProfileMinGuard, SubscriptionGuard, CalibrationGuard here if needed.
class HomeGate extends ConsumerWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      child: const AppShell(), // your bottom-nav + tabs live inside AppShell
    );
  }
}
