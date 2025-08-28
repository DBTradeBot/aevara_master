// lib/features/home/components/chevron_symbol.dart
//
// ChevronSymbol — bigger, easier tap target (56x56) with circular splash.
// Opens the Vitality Info Sheet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sheets/vitality_info_sheet.dart';

class ChevronSymbol extends StatelessWidget {
  const ChevronSymbol({
    super.key,
    this.vitalityAge,
    this.chronologicalAge,
    this.healthyYears,
    this.confidence,
    this.constants,
    this.size = 24, // icon glyph size
  });

  final double? vitalityAge;
  final double? chronologicalAge;
  final double? healthyYears;
  final int? confidence;
  final Map<String, num>? constants;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;

    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            VitalityInfoSheet.show(
              context,
              vitalityAge: vitalityAge,
              chronologicalAge: chronologicalAge,
              healthyYears: healthyYears,
              confidence: confidence,
              constants: constants,
            );
          },
          icon: Icon(Icons.expand_more, color: color, size: size),
          padding: EdgeInsets.zero,
          splashRadius: 28, // big circular splash, easier to see/tap
          constraints: const BoxConstraints.tightFor(width: 56, height: 56),
          tooltip: 'Vitality details',
        ),
      ),
    );
  }
}
