import 'package:flutter/material.dart';
import '../../../theme/aevara_theme.dart';
import 'number_input_sheet.dart';

Future<void> showStressSheet(
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
        metricName: 'Stress',
        metricIcon: Icons.self_improvement_outlined,
        unit: '1â€“5',
        initialValue: initialLevel,
        min: 1,
        max: 5,
        step: 1,
        onChanged: onChanged,
        onSave: onSave,
        infoWhat: 'Perceived stress today on a 1â€“5 scale.',
        infoWhy:
        'Higher stress can reduce recovery quality and affect sleep and choices.',
        infoWhyLinkLabel: 'Learn more',
        onOpenInfoWhyLink: () {},
        infoHowAffects:
        'High stress adds a small penalty; lower stress removes it. Caps prevent large swings.',
        infoWhereToFind:
        'Manual: pick a value in the Stress sheet. Wearables: optional stress integrations later.',
      ),
    ),
  );
}
