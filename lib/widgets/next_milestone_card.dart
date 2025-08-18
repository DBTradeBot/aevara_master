<<<<<<< Updated upstream
import 'package:flutter/material.dart';
=======
﻿import 'package:flutter/material.dart';
>>>>>>> Stashed changes
import '../data/mock_community_data.dart';

class NextMilestoneCard extends StatelessWidget {
  final BadgeModel? badge;
  final VoidCallback? onTap;
  const NextMilestoneCard({super.key, required this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
if (badge == null) return const SizedBox.shrink()
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: Row(
          children: [
            Text(badge!.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your next milestone',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
<<<<<<< Updated upstream
                  Text('${badge!.name} â€¢ ${(badge!.progress * 100).round()}%',
=======
                  Text('${badge!.name} Ã¢â‚¬Â¢ ${(badge!.progress * 100).round()}%',
>>>>>>> Stashed changes
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}


