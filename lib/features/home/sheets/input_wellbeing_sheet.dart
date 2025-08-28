// lib/features/home/sheets/input_wellbeing_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/today_actions.dart';

class InputWellbeingSheet extends ConsumerStatefulWidget {
  const InputWellbeingSheet({super.key});
  @override
  ConsumerState<InputWellbeingSheet> createState() =>
      _InputWellbeingSheetState();
}

class _InputWellbeingSheetState extends ConsumerState<InputWellbeingSheet> {
  int _mood = 3;
  int _stress = 3;
  final _moodCtrl = TextEditingController();

  @override
  void dispose() {
    _moodCtrl.dispose();
    super.dispose();
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
                Text('Wellbeing check‑in', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Mood', style: theme.textTheme.bodyMedium),
                const Spacer(),
                DropdownButton<int>(
                  value: _mood,
                  items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                          value: i + 1, child: Text('${i + 1}'))),
                  onChanged: (v) => setState(() => _mood = v ?? 3),
                ),
              ],
            ),
            Row(
              children: [
                Text('Stress', style: theme.textTheme.bodyMedium),
                const Spacer(),
                DropdownButton<int>(
                  value: _stress,
                  items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                          value: i + 1, child: Text('${i + 1}'))),
                  onChanged: (v) => setState(() => _stress = v ?? 3),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _moodCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText:
                    'Want to share more? Tell Aevara what’s on your mind.',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await ref.read(todayActionsProvider).setWellbeing(
                      mood1to5: _mood,
                      stress1to5: _stress,
                      notesMood: _moodCtrl.text.isEmpty ? null : _moodCtrl.text,
                    );
                if (context.mounted)
                  Navigator.pop(context, {'mood': _mood, 'stress': _stress});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
