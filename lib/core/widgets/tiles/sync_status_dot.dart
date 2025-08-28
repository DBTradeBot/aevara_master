import 'package:flutter/material.dart';

/// Canonical sync status used across app.
enum SyncStatus { connected, stale, disconnected, none }

class SyncStatusDot extends StatelessWidget {
  final SyncStatus status;
  final double size;
  final EdgeInsets? padding;
  final String? tooltip;
  final String? semanticLabel;

  const SyncStatusDot({
    super.key,
    required this.status,
    this.size = 12,
    this.padding,
    this.tooltip,
    this.semanticLabel,
  });

  Color _colorFor(BuildContext context) {
    // Typical traffic-light set; align with design tokens if needed.
    switch (status) {
      case SyncStatus.connected:    return const Color(0xFF2ECC71); // true green
      case SyncStatus.stale:        return const Color(0xFFF1C40F); // true yellow
      case SyncStatus.disconnected: return const Color(0xFFE74C3C); // true red
      case SyncStatus.none:         return const Color(0xFF9E9E9E); // neutral grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _colorFor(context),
        shape: BoxShape.circle,
      ),
    );

    Widget dot = Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: dotCore,
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      dot = Tooltip(message: tooltip!, child: dot);
    }

    return Semantics(
      label: semanticLabel ?? 'Sync status',
      value: switch (status) {
        SyncStatus.connected => 'Connected',
        SyncStatus.stale => 'Stale',
        SyncStatus.disconnected => 'Disconnected',
        SyncStatus.none => 'Not connected',
      },
      child: dot,
    );
  }
}
