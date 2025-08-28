import 'package:flutter/material.dart';

class InputStressSheet extends StatefulWidget {
  const InputStressSheet({super.key});

  @override
  State<InputStressSheet> createState() => _InputStressSheetState();
}

class _InputStressSheetState extends State<InputStressSheet> {
  int _value = 3; // 1 = low stress (good), 5 = high stress (bad)

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stress (1–5)', style: tt.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1 😌')),
                ButtonSegment(value: 2, label: Text('2 🙂')),
                ButtonSegment(value: 3, label: Text('3 😐')),
                ButtonSegment(value: 4, label: Text('4 😣')),
                ButtonSegment(value: 5, label: Text('5 🌪️')),
              ],
              selected: {_value},
              onSelectionChanged: (s) => setState(() => _value = s.first),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                // TODO: write to `user_daily/{uid}/days/{YYYY-MM-DD}.stress_level_1to5 = _value`
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
