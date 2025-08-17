import 'package:flutter/material.dart';

/// Community RankTile (emoji/URL-aware).
/// Keep this at: lib/features/community/widgets/rank_tile.dart
class RankTile extends StatelessWidget {
  final int rank;
  final String name;
  final String? avatarEmoji; // preferred for your mocks
  final String? avatarUrl;   // optional if you switch to images later
  final String scoreLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RankTile({
    super.key,
    required this.rank,
    required this.name,
    required this.scoreLabel,
    this.avatarEmoji,
    this.avatarUrl,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar;
    if ((avatarEmoji ?? '').isNotEmpty) {
      avatar = CircleAvatar(child: Text(avatarEmoji!));
    } else if ((avatarUrl ?? '').isNotEmpty) {
      avatar = CircleAvatar(backgroundImage: NetworkImage(avatarUrl!));
    } else {
      avatar = const CircleAvatar(child: Icon(Icons.person));
    }

    return ListTile(
      onTap: onTap,
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.surfaceVariant,
            ),
            child: Text('#$rank', style: theme.textTheme.labelSmall),
          ),
        ],
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing ?? Text(scoreLabel, style: theme.textTheme.bodyMedium),
    );
  }
}
