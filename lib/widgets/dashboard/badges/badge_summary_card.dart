import 'package:flutter/material.dart';
import '../../../data/mock_community_data.dart';

/// Compact Community Home summary:
/// - Optional inline "Congrats" chip (if something is earned)
/// - "Next up" single-line progress + small bar
/// - Shows a circular badge thumbnail with safe placeholders
class BadgeSummaryCard extends StatelessWidget {
  const BadgeSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    // recently earned (if your mock marks earned or progress>=1)
    final earned = demoBadges
        .where((b) => (b.earned == true) || (b.progress >= 1))
        .toList();
    final recent = earned.isNotEmpty ? earned.first : null;

    // nearest upcoming (highest progress thatâ€™s not yet earned)
    final pending = demoBadges
        .where((b) => !(b.earned == true || b.progress >= 1))
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final next = pending.isNotEmpty ? pending.first : demoBadges.first;

    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Badges snapshot',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/community/badges'),
                  child: const Text('View'),
                ),
              ],
            ),

            // congrats chip only if we truly have one
            if (recent != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ðŸ‘‡ badge thumbnail with placeholder
                    BadgeThumb(
                      emoji: recent.emoji, // todayâ€™s placeholder
                      // assetPath: recent.assetPath, // uncomment when you add assets to model
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Congrats! You earned â€œ${recent.name}â€',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ],

            // next badge
            const SizedBox(height: 10),
            Row(
              children: [
                // ðŸ‘‡ badge thumbnail with placeholder
                BadgeThumb(
                  emoji: next.emoji, // todayâ€™s placeholder
                  // assetPath: next.assetPath, // uncomment when available
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    next.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(next.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: next.progress.clamp(0, 1),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular badge image with robust fallbacks:
/// - If you later add `assetPath` to your BadgeModel, it will use Image.asset.
/// - Otherwise it shows the provided `emoji`.
/// - If neither is present, it shows a generic trophy icon.
class BadgeThumb extends StatelessWidget {
  final String? assetPath; // optional future-proof asset
  final String? emoji;     // current placeholder from mock
  final double size;

  const BadgeThumb({
    super.key,
    this.assetPath,
    this.emoji,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceVariant;

    Widget inner;

    // Prefer asset if provided later
    if (assetPath != null && assetPath!.isNotEmpty) {
      inner = ClipOval(
        child: Image.asset(
          assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackFromEmojiOrIcon(size),
        ),
      );
    } else {
      // Today: show emoji fallback (from mocks)
      inner = _fallbackFromEmojiOrIcon(size, emoji: emoji);
    }

    return Container(
      width: size + 10,
      height: size + 10,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: inner,
    );
  }

  Widget _fallbackFromEmojiOrIcon(double size, {String? emoji}) {
    if (emoji != null && emoji.isNotEmpty) {
      return Text(emoji, style: TextStyle(fontSize: size * 0.9));
    }
    return Icon(Icons.emoji_events, size: size * 0.9);
  }
}
