
import 'package:flutter/material.dart';
import '../../data/mock_community_data.dart';
import '../../widgets/challenge_card.dart';

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demoChallenges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => ChallengeCard(challenge: demoChallenges[i], onJoin: () {}),
      ),
    );
  }
}
