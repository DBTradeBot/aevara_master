import 'package:flutter/material.dart';
class InboxPage extends StatelessWidget{ const InboxPage({super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Notifications')), body: ListView(children:[
    ListTile(leading: const Icon(Icons.notifications), title: const Text('Welcome to Aevara!'), subtitle: const Text('Thanks for signing up.')),
    ListTile(leading: const Icon(Icons.bolt_outlined), title: const Text('Experiment reminder'), subtitle: const Text('Tonight: +30 min Sleep')),
  ]));
}
