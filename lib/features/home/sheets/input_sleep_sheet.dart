// lib/features/home/sheets/input_sleep_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/today_actions.dart';

class InputSleepSheet extends ConsumerStatefulWidget {
  const InputSleepSheet({super.key, this.initialHours});
  final double? initialHours;

  @override
  ConsumerState<InputSleepSheet> createState() => _InputSleepSheetState();
}

class _InputSleepSheetState extends ConsumerState<InputSleepSheet> {
  double _hours = 7.0;

  @override
  void initState() {
    super.initState();
    _hours = (widget.initialHours ?? 7.0).clamp(0.0, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 4, margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Text('Add Sleep', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('${_hours.toStringAsFixed(1)} h', style: theme.textTheme.titleMedium),
              ],
            ),
            Slider(
              value: _hours,
              min: 0,
              max: 16,
              divisions: 160,
              label: _hours.toStringAsFixed(1),
              onChanged: (v) => setState(() => _hours = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await ref.read(todayActionsProvider).setSleepHours(_hours);
                if (context.mounted) Navigator.pop(context, _hours);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
