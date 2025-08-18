// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class ChallengeDetailPage extends StatelessWidget {
  const ChallengeDetailPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Challenge Detail')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Rules: keep daily steps above target for 7 days.'),
        const SizedBox(height: 8),
        FilledButton(onPressed: () {}, child: const Text('Join (placeholder)')),
      ]));
}

