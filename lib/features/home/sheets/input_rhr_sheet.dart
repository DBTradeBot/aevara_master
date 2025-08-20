// lib/features/home/sheets/input_rhr_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/today_actions.dart';

class InputRhrSheet extends ConsumerStatefulWidget {
  const InputRhrSheet({super.key, this.initialBpm});
  final int? initialBpm;

  @override
  ConsumerState<InputRhrSheet> createState() => _InputRhrSheetState();
}

class _InputRhrSheetState extends ConsumerState<InputRhrSheet> {
  int _bpm = 60;

  @override
  void initState() {
    super.initState();
    _bpm = (widget.initialBpm ?? 60).clamp(30, 110);
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
                Text('Add Resting HR', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('$_bpm bpm', style: theme.textTheme.titleMedium),
              ],
            ),
            Slider(
              value: _bpm.toDouble(),
              min: 30, max: 110,
              divisions: 80,
              label: '$_bpm',
              onChanged: (v) => setState(() => _bpm = v.round()),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await ref.read(todayActionsProvider).setRhr(_bpm);
                if (context.mounted) Navigator.pop(context, _bpm);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
