// lib/features/home/sheets/input_hrv_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/today_actions.dart';

class InputHrvSheet extends ConsumerStatefulWidget {
  const InputHrvSheet({super.key, this.initialMs});
  final double? initialMs;

  @override
  ConsumerState<InputHrvSheet> createState() => _InputHrvSheetState();
}

class _InputHrvSheetState extends ConsumerState<InputHrvSheet> {
  double _rmssd = 40;

  @override
  void initState() {
    super.initState();
    _rmssd = (widget.initialMs ?? 40).clamp(5, 250);
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
                Text('Add HRV (rMSSD)', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('${_rmssd.toStringAsFixed(0)} ms', style: theme.textTheme.titleMedium),
              ],
            ),
            Slider(
              value: _rmssd,
              min: 5, max: 250,
              divisions: 245,
              label: _rmssd.toStringAsFixed(0),
              onChanged: (v) => setState(() => _rmssd = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await ref.read(todayActionsProvider).setHrv(_rmssd);
                if (context.mounted) Navigator.pop(context, _rmssd);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
