import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aevara_app/theme/aevara_theme.dart';
import 'package:aevara_app/tiles/sync_tile.dart';

// Icon accent colors for the metric badges
const _sleepIcon = Color(0xFF3F87A6);
const _hrvIcon = Color(0xFF8E66B6);
const _stepsIcon = Color(0xFFF6A04A);

class MetricsRow extends StatelessWidget {
  final double? sleepHours; // e.g., 6.0
  final double? hrvRmssdMs; // e.g., 45.0
  final int? stepsCount; // e.g., 6500
  final bool isAnyProviderConnected; // passed to SyncTile

  final VoidCallback onSleepTap;
  final VoidCallback onHRVTap;
  final VoidCallback onStepsTap;
  final VoidCallback onSyncTap;

  // For Sync status color (just forwarded)
  final DateTime? lastSyncUtc; // null => disconnected/never
  final bool syncError; // true => red

  final EdgeInsetsGeometry padding;
  final double spacing;

  const MetricsRow({
    super.key,
    this.sleepHours,
    this.hrvRmssdMs,
    this.stepsCount,
    this.isAnyProviderConnected = false,
    required this.onSleepTap,
    required this.onHRVTap,
    required this.onStepsTap,
    required this.onSyncTap,
    this.lastSyncUtc,
    this.syncError = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.spacing = 8,
  });

  // ---- Format helpers (NO SPACES in units) ----
  String? _fmtSleep(double? v) =>
      v == null ? null : '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}h';
  String? _fmtMs(double? v) => v == null ? null : '${v.toStringAsFixed(0)}ms';
  String? _fmtSteps(int? v) => v == null ? null : _compact(v);
  static String _compact(int n) {
<<<<<<< Updated upstream
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
=======
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
>>>>>>> Stashed changes
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final radius = Theme.of(context).extension<AevaraTheme>()?.radius ?? 16.0;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onSleepTap,
              borderRadius: BorderRadius.circular(radius),
              child: _AdaptiveMetricCard(
                icon: Icons.bedtime_rounded,
                iconColor: _sleepIcon,
                label: 'Sleep',
                valueOrPrompt: _fmtSleep(sleepHours) ?? 'Tap to add',
                hasValue: _fmtSleep(sleepHours) != null,
                radius: radius,
              ),
            ),
          ),
          SizedBox(width: spacing),

          Expanded(
            child: InkWell(
              onTap: onHRVTap,
              borderRadius: BorderRadius.circular(radius),
              child: _AdaptiveMetricCard(
                icon: Icons.monitor_heart,
                iconColor: _hrvIcon,
                label: 'HRV',
                valueOrPrompt: _fmtMs(hrvRmssdMs) ?? 'Tap to add',
                hasValue: _fmtMs(hrvRmssdMs) != null,
                radius: radius,
              ),
            ),
          ),
          SizedBox(width: spacing),

          Expanded(
            child: InkWell(
              onTap: onStepsTap,
              borderRadius: BorderRadius.circular(radius),
              child: _AdaptiveMetricCard(
                icon: Icons.directions_walk_rounded,
                iconColor: _stepsIcon,
                label: 'Steps',
                valueOrPrompt: _fmtSteps(stepsCount) ?? 'Tap to add',
                hasValue: _fmtSteps(stepsCount) != null,
                radius: radius,
              ),
            ),
          ),
          SizedBox(width: spacing),

          // SYNC (kept slightly smaller inside via innerScale; has same elevation)
          Expanded(
            child: SyncTile(
              isConnected: isAnyProviderConnected,
              lastSyncUtc: lastSyncUtc,
              syncError: syncError,
              onTap: onSyncTap,
              innerScale: 0.90,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fully adaptive metric card that **never overflows**.
class _AdaptiveMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String valueOrPrompt;
  final bool hasValue;
  final double radius;

  const _AdaptiveMetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.valueOrPrompt,
    required this.hasValue,
    required this.radius,
  });

  double _clamp(double v, double minV, double maxV) =>
      math.max(minV, math.min(maxV, v));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // If unconstrained, use a sensible default height.
        final h =
            (c.maxHeight.isFinite && c.maxHeight > 0) ? c.maxHeight : 74.0;

        // Vertical padding
        final padV = _clamp(h * 0.08, 4, 10);

        // Icon sizes
        final iconOuter = _clamp(h * 0.34, 18, 32);
        final iconGlyph = _clamp(iconOuter * 0.66, 12, 20);

        // Font sizes (make missing-value prompt smaller so it never clips)
        final valueFsPresent = _clamp(h * 0.24, 15, 20);
        final valueFsMissing =
<<<<<<< Updated upstream
            _clamp(h * 0.16, 10, 12); // smaller for â€œTap to addâ€
=======
            _clamp(h * 0.16, 10, 12); // smaller for Ã¢â‚¬Å“Tap to addÃ¢â‚¬Â
>>>>>>> Stashed changes
        final labelFs = _clamp(h * 0.18, 12, 14.5);

        // Flex proportions
        const iconFlex = 340;
        const spacerFlex = 60;
        const valueFlex = 300;
        const labelFlex = 220;

        return Container(
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border:
                Border.all(color: Colors.black12.withOpacity(0.08), width: 1),
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
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Icon
              Expanded(
                flex: iconFlex,
                child: Center(
                  child: Container(
                    width: iconOuter,
                    height: iconOuter,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: iconGlyph, color: iconColor),
                  ),
                ),
              ),

              const Expanded(flex: spacerFlex, child: SizedBox.shrink()),

              // Value / "Tap to add" (scale down if tight)
              Expanded(
                flex: valueFlex,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      valueOrPrompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.w500,
                        fontSize: hasValue ? valueFsPresent : valueFsMissing,
                        fontStyle:
                            hasValue ? FontStyle.normal : FontStyle.italic,
                        color: hasValue ? Colors.black87 : Colors.black54,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),

              const Expanded(flex: spacerFlex, child: SizedBox.shrink()),

              // Label
              Expanded(
                flex: labelFlex,
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: labelFs,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
