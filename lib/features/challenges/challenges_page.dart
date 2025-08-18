<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: ListView(children: [
        Card(
            child: ListTile(
                title: const Text('10% Steps (Friends)'),
                subtitle: const Text('7 days Ã¢â‚¬Â¢ Join now'),
                trailing:
                    FilledButton(onPressed: () {}, child: const Text('Join')))),
        Card(
            child: ListTile(
                title: const Text('+30 min Sleep'),
                subtitle: const Text('14 days Ã¢â‚¬Â¢ Starts Monday'),
                trailing: FilledButton(
                    onPressed: () {}, child: const Text('Notify')))),
      ]));
}

