import 'package:flutter/material.dart';
import '../../../data/mock_community_data.dart';

class NextBadgeCard extends StatelessWidget {
  const NextBadgeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = demoBadges
        .where((b) => !(b.earned || b.progress >= 1))
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final b = pending.isNotEmpty ? pending.first : demoBadges.first;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(b.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(b.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    b.tier.name.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(b.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: b.progress.clamp(0, 1)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${(b.progress * 100).toStringAsFixed(0)}%'),
                const Spacer(),
                const Text('Keep it up!'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
