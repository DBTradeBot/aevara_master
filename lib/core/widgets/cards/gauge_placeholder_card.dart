// lib/core/widgets/cards/gauge_placeholder_card.dart
//
// Placeholder shown when Vitality Age is gated off.
// Use in the hero area where the gauge would normally appear.

import 'package:flutter/material.dart';

class GaugePlaceholderCard extends StatelessWidget {
  final String title;
  final String? message;

  const GaugePlaceholderCard({
    super.key,
    this.title = 'Vitality Age will appear once today’s data is in',
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty, size: 28, color: theme.colorScheme.outline),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          if (message != null && message!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
