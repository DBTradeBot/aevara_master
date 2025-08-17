import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aevara_app/theme/aevara_theme.dart';

class SyncTile extends StatelessWidget {
  final bool isConnected;
  final DateTime? lastSyncUtc; // null = never synced
  final bool syncError;
  final VoidCallback onTap;

  /// Shrinks the Sync card horizontally inside its slot (keeps it visually smaller).
  /// We no longer scale height fractionally to avoid infinite-height constraints.
  final double innerScale;

  const SyncTile({
    super.key,
    required this.isConnected,
    this.lastSyncUtc,
    this.syncError = false,
    required this.onTap,
    this.innerScale = 0.90,
  });

  Color _statusColor() {
    if (syncError) return const Color(0xFFE74C3C);            // red
    if (!isConnected) return const Color(0xFF9AA3AF);         // grey
    if (lastSyncUtc == null) return const Color(0xFF9AA3AF);  // grey
    final now = DateTime.now().toUtc();
    final age = now.difference(lastSyncUtc!);
    if (age.inHours <= 24) return const Color(0xFF27AE60);    // fresh green
    return const Color(0xFFF2994A);                           // stale amber
  }

  double _clamp(double v, double minV, double maxV) =>
      math.max(minV, math.min(maxV, v));

  @override
  Widget build(BuildContext context) {
    final aev = Theme.of(context).extension<AevaraTheme>();
    final radius = aev?.radius ?? 16.0;

    return LayoutBuilder(
      builder: (context, c) {
        // If height is unconstrained, fall back to a compact default.
        final h = (c.maxHeight.isFinite && c.maxHeight > 0) ? c.maxHeight : 74.0;

        // Adaptive padding & badge sizing
        final padV = _clamp(h * 0.08, 4, 10);
        final double badgeOuter = _clamp(h * 0.30, 22.0, 28.0);
        final double badgeGlyph = _clamp(badgeOuter * 0.70, 14.0, 20.0);

        return Center(
          // Only fraction width; give an explicit, finite height.
          child: FractionallySizedBox(
            widthFactor: innerScale,         // âœ… fraction width
            // heightFactor: âŒ removed to avoid infinite height issues
            child: SizedBox(
              height: h * innerScale,        // explicit finite height
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: Colors.black12.withOpacity(0.08),
                    width: 1,
                  ),
                  // same elevation as metric cards
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: padV),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(radius),
                  child: Center(
                    child: Container(
                      width: badgeOuter,
                      height: badgeOuter,
                      decoration: BoxDecoration(
                        color: _statusColor().withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.sync_rounded,
                        size: badgeGlyph,
                        color: _statusColor(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
