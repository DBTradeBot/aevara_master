import 'package:flutter/material.dart';

class RecentBadgePill extends StatelessWidget {
  const RecentBadgePill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.emoji_events, size: 20, color: Colors.amber),
          SizedBox(width: 8),
          Text("Congrats! You earned a badge"),
        ],
      ),
    );
  }
}
