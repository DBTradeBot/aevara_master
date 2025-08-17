import 'package:flutter/material.dart';
import '../../../data/mock_community_data.dart';

class ClubCard extends StatelessWidget {
  final ClubModel club;
  final VoidCallback? onTap;
  final double? width;

  const ClubCard({
    super.key,
    required this.club,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 420),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(club.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  club.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 64),
                child: FilledButton.tonal(
                  onPressed: onTap,
                  child: const Text('View'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            club.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.group, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${club.members} members',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return width != null ? SizedBox(width: width, child: card) : card;
  }
}
