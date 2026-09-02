import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/today_actions.dart';

/// Wellbeing (1–5) where 1 = best, 5 = worst.
/// Writes to user_daily/{uid}/days/{YYYY-MM-DD}.wellbeing_level_1to5
/// Optional note saved to .notes_wellbeing
class InputWellbeingSheet extends ConsumerStatefulWidget {
  const InputWellbeingSheet({super.key});

  @override
  ConsumerState<InputWellbeingSheet> createState() =>
      _InputWellbeingSheetState();
}

class _InputWellbeingSheetState extends ConsumerState<InputWellbeingSheet> {
  int _value = 3; // neutral default
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
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
            // Handle
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Row(
              children: [
                Text('Wellbeing (1–5)', style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '1 = feeling great · 5 = feeling poor',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Single 1–5 control (emoji labels, 5 = worse)
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1 😄')),
                ButtonSegment(value: 2, label: Text('2 🙂')),
                ButtonSegment(value: 3, label: Text('3 😐')),
                ButtonSegment(value: 4, label: Text('4 😣')),
                ButtonSegment(value: 5, label: Text('5 🌪️')),
              ],
              selected: {_value},
              onSelectionChanged: (s) => setState(() => _value = s.first),
            ),

            const SizedBox(height: 12),

            // Optional note (stored in notes_wellbeing)
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText:
                'Want to share more? Tell Aevara what’s on your mind.',
              ),
            ),

            const SizedBox(height: 12),

            // Save
            FilledButton(
              onPressed: () async {
                await ref.read(todayActionsProvider).setWellbeingLevel(
                  value1to5: _value,
                  note: _noteCtrl.text.trim().isEmpty
                      ? null
                      : _noteCtrl.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context, {'wellbeing': _value});
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
