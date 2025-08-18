// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class ExperimentProgressPage extends StatelessWidget {
  const ExperimentProgressPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(c).dividerColor),
                borderRadius: BorderRadius.circular(12)),
            child: const Text('Sleep change chart')),
        const SizedBox(height: 8),
        Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(c).dividerColor),
                borderRadius: BorderRadius.circular(12)),
            child: const Text('Steps change chart')),
      ]));
}
