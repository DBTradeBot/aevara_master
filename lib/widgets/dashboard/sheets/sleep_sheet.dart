import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/aevara_theme.dart';
import 'number_input_sheet.dart';

Future<void> showSleepSheet(
    BuildContext context, {
      required double initialHours,
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
        metricName: 'Sleep',
        metricIcon: Icons.bedtime,
        unit: 'hrs',
        initialValue: initialHours,
        min: 0,
        max: 24,
        step: 0.5,
        onChanged: onChanged,
        onSave: onSave,
        infoWhat:
        'The total amount of time you spend asleep in a 24-hour period, ideally including both nighttime sleep and any naps.',
        infoWhy:
        'Consistent, restorative sleep is one of the strongest predictors of physical health, mental wellbeing, and recovery. Poor sleep affects hormone balance, immune function, mood, and long-term health risk.',
        infoHowAffects:
        'We compare your sleep duration to recommended ranges for your age group. Too little or too much sleep reduces your recovery and healthy days score; hitting your optimal range boosts them.',
        infoWhereToFind:
        'Wearables: Apple Watch (Health app → Sleep), Fitbit (Today → Sleep), Oura (Sleep tab), Garmin (Sleep widget), WHOOP (Sleep tab), Samsung Health (Sleep).\n\n'
            'Manual/estimate: Record the time you fell asleep and the time you woke up (minus time spent awake during the night).',
      ),
    ),
  );
}
