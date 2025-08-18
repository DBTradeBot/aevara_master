import 'package:flutter/material.dart';
import '../../../services/reaction_store.dart';

/// Compact emoji reactions row. Use only on Friends tab.
class BadgeReactionsRow extends StatelessWidget {
  final String badgeId;
  final Map<String, int>? seedCounts;

  const BadgeReactionsRow({
    super.key,
    required this.badgeId,
    this.seedCounts,
  });

  @override
  Widget build(BuildContext context) {
    ReactionStore.I.seed(badgeId, initial: seedCounts);

    return AnimatedBuilder(
      animation: ReactionStore.I,
      builder: (context, _) {
        final counts = ReactionStore.I.getCounts(badgeId);
        final mine = ReactionStore.I.getUserEmoji(badgeId);
        final entries = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final chips = entries.isNotEmpty
            ? entries.take(3).map((e) => _EmojiChip(
                  emoji: e.key,
                  count: e.value,
                  selected: mine == e.key,
                  onTap: () => ReactionStore.I.toggle(badgeId, e.key),
                ))
            : [
                for (final e in const ['Ã°Å¸â€˜Â', 'Ã°Å¸â€Â¥', 'Ã°Å¸â€™Âª'])
                  _EmojiChip(
                    emoji: e,
                    count: 0,
                    selected: mine == e,
                    onTap: () => ReactionStore.I.toggle(badgeId, e),
                  )
              ];

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...chips,
            _AddEmojiChip(
                onPick: (emoji) => ReactionStore.I.toggle(badgeId, emoji)),
          ],
        );
      },
    );
  }
}

class _EmojiChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _EmojiChip({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
if (count > 0) { ...[
            const SizedBox(width: 6),
            Text('$count', style: Theme.of(context).textTheme.labelSmall),
          ],
        ]),
      ),
    ); }
  }
}

class _AddEmojiChip extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _AddEmojiChip({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => _EmojiPickerSheet(onPick: onPick),
        );
if (picked != null) { onPick(picked); }
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: cs.surfaceContainerHighest,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_reaction, size: 18),
          const SizedBox(width: 6),
          Text('React', style: Theme.of(context).textTheme.labelSmall),
        ]),
      ),
    );
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _EmojiPickerSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final options = [
      'Ã°Å¸â€˜Â',
      'Ã°Å¸â€Â¥',
      'Ã°Å¸â€™Âª',
      'Ã°Å¸â„¢Å’',
      'Ã°Å¸ËœÂ',
      'Ã°Å¸Â¤Â¯',
      'Ã°Å¸Å½â€°',
      'Ã°Å¸Ââ€ ',
      'Ã°Å¸â€™Â¯',
      'Ã°Å¸ËœÅ ',
      'Ã°Å¸Â«Â¡',
      'Ã°Å¸Â¤Â'
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in options)
            InkWell(
              onTap: () => Navigator.of(context).pop(e),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            ),
        ],
      ),
    );
  }
}

