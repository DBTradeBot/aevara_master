<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Groups & Clubs')),
      body: ListView(children: [
        Card(
            child: ListTile(
                title: const Text('Aevara Crew'),
<<<<<<< Updated upstream
                subtitle: const Text('12 members â€¢ Weekly steps challenge'),
=======
                subtitle:
                    const Text('12 members Ã¢â‚¬Â¢ Weekly steps challenge'),
>>>>>>> Stashed changes
                trailing:
                    FilledButton(onPressed: () {}, child: const Text('Join')))),
        Card(
            child: ListTile(
                title: const Text('Sleep Boosters'),
<<<<<<< Updated upstream
                subtitle: const Text('8 members â€¢ Sleep streak challenge'),
=======
                subtitle:
                    const Text('8 members Ã¢â‚¬Â¢ Sleep streak challenge'),
>>>>>>> Stashed changes
                trailing:
                    FilledButton(onPressed: () {}, child: const Text('Join')))),
      ]));
}


