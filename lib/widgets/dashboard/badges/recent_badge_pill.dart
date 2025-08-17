import 'package:flutter/material.dart';
import '../../../data/mock_community_data.dart';

class RecentBadgePill extends StatelessWidget {
  const RecentBadgePill({super.key});

  @override
  Widget build(BuildContext context) {
    // Pick first earned badge (fallback to first)
    final earned = demoBadges.where((b) => b.earned || b.progress >= 1).toList();
    final b = earned.isNotEmpty ? earned.first : demoBadges.first;

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(b.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            'Congrats! You earned “${b.name}”',
            style: Theme.of(context).textTheme.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }
}
