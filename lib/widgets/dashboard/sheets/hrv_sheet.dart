import 'package:flutter/material.dart';
import 'package:aevara_app/theme/aevara_theme.dart';
import 'number_input_sheet.dart';

Future<void> showHrvSheet(
  BuildContext context, {
  required double initialMs,
  ValueChanged<double>? onChanged,
  ValueChanged<double>? onSave,
}) {
  final a = context.aevara;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: a.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(a.radius)),
        boxShadow: [
          BoxShadow(
              color: a.shadow, blurRadius: 24, offset: const Offset(0, -6))
        ],
      ),
      child: NumberInputSheet(
        metricName: 'HRV',
        metricIcon: Icons.monitor_heart,
        unit: 'ms',
        initialValue: initialMs,
        min: 10, // sensible UI bounds
        max: 200,
        step: 1,
        onChanged: onChanged,
        onSave: onSave,
        infoWhat:
            'A measure of the variation in time between heartbeats, usually measured in milliseconds (rMSSD). Higher values generally indicate better recovery and adaptability.',
        infoWhy:
            'HRV reflects your autonomic nervous system balance. Itâ€™s a strong indicator of stress resilience, cardiovascular fitness, and recovery status.',
        infoHowAffects:
            'We compare your HRV to age/sex norms and your personal baseline. A low HRV may increase your Vitality Age and reduce healthy days; above-baseline HRV can improve your scores.',
        infoWhereToFind:
            'Wearables: Apple Watch (Health â†’ Heart â†’ HRV), WHOOP (Recovery), Oura (Readiness), Garmin (Stress/HRV), Polar (Nightly Recharge).\n\n'
            'Manual/estimate: Use a chest strap + HRV app (e.g., Elite HRV, HRV4Training) upon waking, seated and relaxed.',
      ),
    ),
  );
}
