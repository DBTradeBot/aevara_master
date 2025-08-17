
import 'package:flutter/material.dart';
import '../data/mock_community_data.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback? onJoin;
  const ChallengeCard({super.key, required this.challenge, this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Text(challenge.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(challenge.title),
        subtitle: Text('${challenge.subtitle} • ${challenge.category}'),
        trailing: FilledButton(onPressed: onJoin, child: const Text('Join')),
      ),
    );
  }
}
