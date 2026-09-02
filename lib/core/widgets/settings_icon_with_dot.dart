// lib/core/widgets/settings_icon_with_dot.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/notifications_providers.dart';

/// A settings icon that shows a small red dot when there are unread notifications.
/// Use anywhere you render a gear icon, e.g. in AppBar actions:
///   SettingsIconWithDot(onPressed: _openSettings)
class SettingsIconWithDot extends ConsumerWidget {
  const SettingsIconWithDot({
    super.key,
    this.onPressed,
    this.icon = Icons.settings_outlined,
    this.tooltip = 'Settings',
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).asData?.value ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFBF4A4A), // red dot
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}
