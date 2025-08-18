import 'package:flutter/material.dart';
import 'package:aevara_app/theme/aevara_theme.dart';
import 'number_input_sheet.dart';

Future<void> showStepsSheet(
  BuildContext context, {
  required double initialSteps,
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
        metricName: 'Steps',
        metricIcon: Icons.directions_walk,
        unit: 'steps',
        initialValue: initialSteps,
        min: 0,
        max: 100000,
        step: 100,
        onChanged: onChanged,
        onSave: onSave,
        infoWhat:
            'The total number of steps you take in a day, including all walking and running.',
        infoWhy:
            'Regular movement supports cardiovascular health, metabolic function, mood, and healthy aging. Even light activity throughout the day reduces sedentary health risks.',
        infoHowAffects:
            'We score steps based on dose-response benefits for mortality risk. Higher activity boosts healthy days; low activity may reduce them.',
        infoWhereToFind:
            'Wearables/phones: Apple Health (Steps), Fitbit, Garmin Connect, WHOOP (Activity), Samsung Health.\n\n'
            'Manual/estimate: Use your phoneâ€™s pedometer or estimate from known distances and time spent walking.',
      ),
    ),
  );
}
