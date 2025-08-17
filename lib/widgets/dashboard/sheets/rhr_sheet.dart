import 'package:flutter/material.dart';
import '../../../theme/aevara_theme.dart';
import 'number_input_sheet.dart';

Future<void> showRhrSheet(
    BuildContext context, {
      required double initialBpm,
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
        boxShadow: [BoxShadow(color: a.shadow, blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: NumberInputSheet(
        metricName: 'Resting HR',
        metricIcon: Icons.favorite_outline,
        unit: 'bpm',
        initialValue: initialBpm,
        min: 10,
        max: 160,
        step: 1,
        onChanged: onChanged,
        onSave: onSave,
        infoWhat:
        'Your heart rate when you are at complete rest, typically measured in beats per minute upon waking or during deep sleep.',
        infoWhy:
        'Lower RHR generally indicates better cardiovascular fitness. Elevated RHR can signal stress, fatigue, illness, or overtraining.',
        infoHowAffects:
        'We factor RHR alongside HRV in your recovery score. High RHR relative to your baseline may reduce your healthy days; lower-than-usual can improve them.',
        infoWhereToFind:
        'Wearables: Apple Watch (Health → Heart → Resting Rate), Fitbit (Today → Heart Rate → Resting), Garmin (Heart Rate → Resting), Oura (Readiness).\n\n'
            'Manual/estimate: Measure your pulse for 60 seconds right after waking, before getting out of bed.',
      ),
    ),
  );
}
