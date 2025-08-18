<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});
  Widget _post(String user, String text) => Card(
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(child: Text(user[0])),
              const SizedBox(width: 8),
              Text(user, style: const TextStyle(fontWeight: FontWeight.w600))
            ]),
            const SizedBox(height: 8),
            Text(text),
            const SizedBox(height: 8),
            Row(children: [
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.favorite_border)),
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline))
            ])
          ])));
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Community Feed')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _post('Alex', 'earned a Sleep Streak badge (7 days).'),
        _post('Sam', 'joined the 10% Steps challenge.'),
        _post('Jules', 'completed +30 min Sleep experiment.'),
      ]));
}

