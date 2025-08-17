import 'package:flutter/material.dart';
class HelpPage extends StatelessWidget{ const HelpPage({super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Help & Support')), body: ListView(padding: const EdgeInsets.all(16), children:[
    const ExpansionTile(title: Text('Connecting devices'), children:[Padding(padding: EdgeInsets.all(12), child: Text('Use Devices page and follow prompts (placeholder).'))]),
    const ExpansionTile(title: Text('Exporting data'), children:[Padding(padding: EdgeInsets.all(12), child: Text('Use Privacy page (placeholder).'))]),
  ]));
}
