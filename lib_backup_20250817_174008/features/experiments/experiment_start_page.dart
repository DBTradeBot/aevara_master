// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../navigation/routes.dart';

class ExperimentStartPage extends StatelessWidget {
  const ExperimentStartPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Configure experiment')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const ListTile(title: Text('Start date'), subtitle: Text('Today')),
        const ListTile(title: Text('Duration'), subtitle: Text('14 days')),
        SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Daily reminders')),
        FilledButton(
            onPressed: () => Navigator.pushNamed(c, Routes.expActive),
            child: const Text('Begin')),
      ]));
}
