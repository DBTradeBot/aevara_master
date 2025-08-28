// lib/features/home/sheets/input_steps_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/today_actions.dart';

class InputStepsSheet extends ConsumerStatefulWidget {
  const InputStepsSheet({super.key, this.initialSteps});
  final int? initialSteps;

  @override
  ConsumerState<InputStepsSheet> createState() => _InputStepsSheetState();
}

class _InputStepsSheetState extends ConsumerState<InputStepsSheet> {
  int _steps = 6000;

  @override
  void initState() {
    super.initState();
    _steps = (widget.initialSteps ?? 6000).clamp(0, 50000);
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
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Text('Add Steps', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('$_steps', style: theme.textTheme.titleMedium),
              ],
            ),
            Slider(
              value: _steps.toDouble(),
              min: 0,
              max: 50000,
              divisions: 500,
              label: '$_steps',
              onChanged: (v) => setState(() => _steps = v.round()),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await ref.read(todayActionsProvider).setSteps(_steps);
                if (context.mounted) Navigator.pop(context, _steps);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
