import 'package:flutter/material.dart';
import '../../../theme/aevara_theme.dart';
import 'number_input_sheet.dart';

Future<void> showMoodSheet(
    BuildContext context, {
      required double initialLevel, // 1â€“5
      ValueChanged<double>? onSave,
      ValueChanged<double>? onChanged,
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
        metricName: 'Mood',
        metricIcon: Icons.emoji_emotions_outlined,
        unit: '1â€“5',
        initialValue: initialLevel,
        min: 1,
        max: 5,
        step: 1,
        onChanged: onChanged,
        onSave: onSave,
        infoWhat: 'How you feel today overall on a 1â€“5 scale.',
        infoWhy:
        'Mood trends tie into stress, recovery, and behavior change readiness.',
        infoWhyLinkLabel: 'Learn more',
        onOpenInfoWhyLink: () {},
        infoHowAffects:
        'Very low mood adds a small penalty; neutral to positive mood removes it. Caps prevent large swings.',
        infoWhereToFind:
        'Manual: pick a value in the Mood sheet. Wearables: optional journaling integrations later.',
      ),
    ),
  );
}
