
import 'package:flutter/material.dart';
import '../data/mock_community_data.dart';

class BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final VoidCallback? onTap;

  const BadgeCard({super.key, required this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ringColor = badge.tier.color;
    final earned = badge.earned || badge.progress >= 1.0;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          color: Theme.of(context).colorScheme.surface,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 48, width: 48,
                  child: CircularProgressIndicator(
                    value: earned ? 1 : (badge.progress.clamp(0, 1)),
                    strokeWidth: 6,
                    color: ringColor,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                ),
                Text(badge.emoji, style: const TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(badge.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ringColor.withOpacity(.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(badge.tier.label, style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
