// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class WellbeingPromptSheet extends StatelessWidget {
  const WellbeingPromptSheet({super.key});
  @override
  Widget build(BuildContext c) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(c).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          const Text('Today\'s check-in',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Mood'),
            const SizedBox(width: 8),
            Expanded(
                child: Slider(
                    value: 3, min: 1, max: 5, onChanged: (_) {}, divisions: 4))
          ]),
          Row(children: [
            const Text('Stress'),
            const SizedBox(width: 8),
            Expanded(
                child: Slider(
                    value: 3, min: 1, max: 5, onChanged: (_) {}, divisions: 4))
          ]),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              children: ['late workout', 'travel', 'alcohol', 'poor sleep']
                  .map((t) => FilterChip(
                      label: Text(t), onSelected: (_) {}, selected: false))
                  .toList()),
          const SizedBox(height: 8),
          const TextField(
              maxLines: 3, decoration: InputDecoration(labelText: 'Notes')),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () => Navigator.pop(c), child: const Text('Save')),
          const SizedBox(height: 8),
          const ListTile(
              title: Text('Insight'),
              subtitle: Text(
                  'Your HRV is near baseline; consider a light day if stress feels high.'))
        ]));
  }
}
