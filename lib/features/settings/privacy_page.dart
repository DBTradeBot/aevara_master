import 'package:flutter/material.dart';
class PrivacyPage extends StatelessWidget{ const PrivacyPage({super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Privacy & Data')), body: ListView(padding: const EdgeInsets.all(16), children:[
    const ListTile(title: Text('Export my data'), subtitle: Text('CSV/JSON (placeholder)')),
    const ListTile(title: Text('Delete my account'), subtitle: Text('Two-step confirmation (placeholder)')),
  ]));
}
