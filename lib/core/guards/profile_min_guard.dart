// lib/core/guards/profile_min_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/user_providers.dart';

/// Simple gate: if profile is null, keep user in onboarding stack.
/// Use as a wrapper or before pushing app shell.
class ProfileMinGuard extends ConsumerWidget {
  final Widget child;
  const ProfileMinGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prof = ref.watch(currentUserProfileProvider).value;
    if (prof == null) {
      // Stay in onboarding (Navigator stack owns the screen).
      return const SizedBox.shrink();
    }
    return child;
  }
}
