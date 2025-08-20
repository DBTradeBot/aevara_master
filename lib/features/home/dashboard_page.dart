// lib/features/home/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_providers.dart';


import 'components/hero_header.dart';
import 'components/vitality_age_gauge.dart';
import 'components/healthy_days_mini_bar.dart';

import 'sheets/input_sleep_sheet.dart';
import 'sheets/input_hrv_sheet.dart';
import 'sheets/input_steps_sheet.dart';
import 'sheets/input_rhr_sheet.dart';
import 'sheets/input_wellbeing_sheet.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ensure rebuild on auth change
    ref.watch(currentUserIdProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const HeroHeader(),
          const SizedBox(height: 12),

          // Row 1: Vitality age gauge (solo card)
          const VitalityAgeGauge(),
          const SizedBox(height: 12),

          // Row 2: Healthy days mini bar (solo card)
          const HealthyDaysMiniBar(),
          const SizedBox(height: 16),

          // Quick inputs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Quick inputs', style: tt.titleLarge),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionChipButton(
                  label: 'Add Sleep',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const InputSleepSheet(),
                  ),
                ),
                _ActionChipButton(
                  label: 'Add HRV',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const InputHrvSheet(),
                  ),
                ),
                _ActionChipButton(
                  label: 'Add Steps',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const InputStepsSheet(),
                  ),
                ),
                _ActionChipButton(
                  label: 'Add RHR',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const InputRhrSheet(),
                  ),
                ),
                _ActionChipButton(
                  label: 'Wellbeing check-in',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const InputWellbeingSheet(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onTap, child: Text(label));
  }
}
