import 'package:flutter/material.dart';

class InputMoodSheet extends StatefulWidget {
  const InputMoodSheet({super.key});

  @override
  State<InputMoodSheet> createState() => _InputMoodSheetState();
}

class _InputMoodSheetState extends State<InputMoodSheet> {
  int _value = 3; // 1 good … 5 bad (we'll invert upstream into wellbeing if needed)

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mood (1–5)', style: tt.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1 🙂')),
                ButtonSegment(value: 2, label: Text('2 🙂')),
                ButtonSegment(value: 3, label: Text('3 😐')),
                ButtonSegment(value: 4, label: Text('4 🙁')),
                ButtonSegment(value: 5, label: Text('5 😖')),
              ],
              selected: {_value},
              onSelectionChanged: (s) => setState(() => _value = s.first),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                // TODO: write to `user_daily/{uid}/days/{YYYY-MM-DD}.mood_level_1to5 = _value`
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
