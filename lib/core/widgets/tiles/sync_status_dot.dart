import 'package:flutter/material.dart';

/// Canonical sync status used across app.
/// Keep this enum here so all widgets import a single source.
enum SyncStatus { connected, stale, disconnected, none }

/// Small circular LED-like dot with subtle 3D appearance.
/// Use inside lists/tiles or wrap with [SyncStatusIcon] for tap-to-legend.
class SyncStatusDot extends StatelessWidget {
  final SyncStatus status;
  final double size;
  final EdgeInsets? padding;
  final String? semanticLabel;

  const SyncStatusDot({
    super.key,
    required this.status,
    this.size = 14,
    this.padding,
    this.semanticLabel,
  });

  // Aevara tokens (aligned to design system)
  // Success: #24A699, Warning: #F6B56B, Error: #BF4A4A, Neutral grey fallback.
  Color _baseColor() {
    switch (status) {
      case SyncStatus.connected:
        return const Color(0xFF24A699);
      case SyncStatus.stale:
        return const Color(0xFFF6B56B);
      case SyncStatus.disconnected:
        return const Color(0xFFBF4A4A);
      case SyncStatus.none:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _baseColor();

    return Semantics(
      label: semanticLabel ?? 'Sync status',
      value: switch (status) {
        SyncStatus.connected => 'Connected',
        SyncStatus.stale => 'Needs refresh',
        SyncStatus.disconnected => 'Disconnected',
        SyncStatus.none => 'Never synced',
      },
      child: Padding(
        padding: padding ?? const EdgeInsets.all(6),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Radial highlight for a glossy/3D look.
            gradient: RadialGradient(
              center: const Alignment(-0.28, -0.28),
              radius: 0.92,
              colors: [
                base.withOpacity(0.96), // bright highlight
                base,                   // body
                base.withOpacity(0.82), // edge
              ],
              stops: const [0.18, 0.68, 1.0],
            ),
            // Thin edge to sharpen against light/dark backgrounds.
            border: Border.all(
              color: Colors.black.withOpacity(0.12),
              width: 0.5,
            ),
            // Shadow for light elevation (like a tiny LED).
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 2,
                spreadRadius: 0.25,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
