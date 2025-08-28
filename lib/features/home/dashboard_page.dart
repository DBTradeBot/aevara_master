// lib/features/home/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
import '../../state/user_providers.dart' as user_state;
import '../../state/app_providers.dart' as app_state;
import '../../state/daily_providers.dart';
import '../../state/healthy_days_providers.dart';

// Widgets
import 'components/hero_header.dart';

// Sheets that exist in your tree:
import 'sheets/input_sleep_sheet.dart';
import 'sheets/input_hrv_sheet.dart';
import 'sheets/input_steps_sheet.dart';
import 'sheets/input_mood_sheet.dart';
import 'sheets/input_stress_sheet.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(user_state.currentUserIdProvider);

    // 1) Ask backend to compute (if endpoint configured)
    if (uid != null) {
      await ref.read(app_state.computeServiceProvider).computeTodayFor(uid);
    }

    // 2) Invalidate key Riverpod streams so UI re-reads fresh data
    ref.invalidate(vitalityGaugeVMProvider);
    ref.invalidate(healthyDaysCountProvider);

    // Optional: small delay so RefreshIndicator shows for a beat
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ensure rebuild on auth change
    ref.watch(user_state.currentUserIdProvider);

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context, ref),
      edgeOffset: 0,
      displacement: 36,
      child: ListView(
        padding: EdgeInsets.zero,
        children: const [
          // Hero card (centered gauge + healthy days)
          HeroHeader(),
          SizedBox(height: 16),

          // Quick inputs
          _QuickInputsSection(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuickInputsSection extends StatelessWidget {
  const _QuickInputsSection();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick inputs', style: tt.titleLarge),
          const SizedBox(height: 8),
          Wrap(
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
                label: 'Mood check-in',
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const InputMoodSheet(),
                ),
              ),
              _ActionChipButton(
                label: 'Stress check-in',
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const InputStressSheet(),
                ),
              ),
            ],
          ),
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
