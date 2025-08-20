// lib/features/home/components/ai_insights_bubble.dart
// Minimal stub: prompts user to check in; opens wellbeing sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sheets/input_wellbeing_sheet.dart';

class AiInsightsBubble extends ConsumerWidget {
  const AiInsightsBubble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: ListTile(
        title: const Text('How are you feeling today?'),
        subtitle: const Text('Tap to check in — mood & stress'),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const InputWellbeingSheet(),
        ),
      ),
    );
  }
}
