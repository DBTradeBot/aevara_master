// lib/features/home/components/hero_header.dart
//
// HeroHeader — VitalityHeader ABOVE the gauge.
// Chevron sits BOTTOM-RIGHT, close to the gauge rim.
// ConfidenceChip removed from header (info lives in the sheet).
//
// Passes `todayFresh` to HealthyDaysMiniBar so today's bar is blank unless fresh.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
import '../../../state/daily_providers.dart';

// Widgets
import 'healthy_days_mini_bar.dart';
import '../sheets/vitality_info_sheet.dart';
import 'vitality_header.dart';
import 'chevron_symbol.dart';
import 'vitality_gauge_block.dart';

class HeroHeader extends ConsumerWidget {
  const HeroHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final vmAsync = ref.watch(vitalityGaugeVMProvider);

    final Color heroBgColor = theme.scaffoldBackgroundColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: heroBgColor,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: vmAsync.when(
            loading: () => const _HeaderBody(
              hasVitality: false,
              showTodayScore: false,
            ),
            error: (e, st) => const _HeaderBody(
              hasVitality: false,
              showTodayScore: false,
            ),
            data: (vm) => _HeaderBody(
              hasVitality: vm.hasVitality,
              showTodayScore: vm.showTodayScore,
              vitalityAge:
              (vm.hasVitality && vm.showTodayScore) ? vm.vitalityAge : null,
              chronoAge:
              (vm.hasVitality && vm.showTodayScore) ? vm.chronoAge : null,
              scores: vm.scores,
              weightsUsed: vm.weightsUsed,
              staleDays: vm.staleDays,
              confidence: vm.confidence,
              constants: vm.constants,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBody extends StatelessWidget {
  const _HeaderBody({
    required this.hasVitality,
    required this.showTodayScore,
    this.vitalityAge,
    this.chronoAge,
    this.scores,
    this.weightsUsed,
    this.staleDays,
    this.confidence,
    this.constants,
  });

  final bool hasVitality;
  final bool showTodayScore;

  final double? vitalityAge;
  final double? chronoAge;

  final Map<String, int>? scores;
  final Map<String, double>? weightsUsed;
  final Map<String, int>? staleDays;
  final int? confidence;
  final Map<String, num>? constants;

  @override
  Widget build(BuildContext context) {
    final ready = hasVitality && showTodayScore;

    final size = MediaQuery.of(context).size;
    final double gaugeSize = _responsiveGaugeSize(size.width);

    void openInfo() {
      HapticFeedback.lightImpact();
      VitalityInfoSheet.show(
        context,
        vitalityAge: ready ? vitalityAge : null,
        chronologicalAge: ready ? chronoAge : null,
        healthyYears: (ready && vitalityAge != null && chronoAge != null)
            ? (chronoAge! - vitalityAge!)
            : null,
        scores: scores,
        weightsUsed: weightsUsed,
        staleDays: staleDays,
        confidence: confidence,
        constants: constants,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VitalityHeader(),

        // Gauge wrapped in GestureDetector for tap → info sheet
        GestureDetector(
          onTap: openInfo,
          behavior: HitTestBehavior.opaque,
          child: VitalityGaugeBlock(
            size: gaugeSize,
            gap: 22.0,
            verticalLift: 0.36,
            rightBottom: ChevronSymbol(
              size: 24,
              vitalityAge: ready ? vitalityAge : null,
              chronologicalAge: ready ? chronoAge : null,
              healthyYears:
              (ready && vitalityAge != null && chronoAge != null)
                  ? (chronoAge! - vitalityAge!)
                  : null,
              constants: constants,
            ),
          ),
        ),

        const SizedBox(height: 12),

        HealthyDaysMiniBar(
          todayFresh: ready,
          dim: !ready,
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  double _responsiveGaugeSize(double width) {
    if (width < 360) return 136;
    if (width < 420) return 146;
    return 154;
  }
}
