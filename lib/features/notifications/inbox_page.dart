<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(children: const [
        ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Welcome to Aevara!'),
            subtitle: Text('Thanks for signing up.')),
        ListTile(
            leading: Icon(Icons.bolt_outlined),
            title: Text('Experiment reminder'),
            subtitle: Text('Tonight: +30 min Sleep')),
      ]));
}

