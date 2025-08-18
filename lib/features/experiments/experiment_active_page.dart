<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import '../../core/widgets/ae_progress_ring.dart';
import '../../navigation/routes.dart';

class ExperimentActivePage extends StatelessWidget {
  const ExperimentActivePage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Active experiment')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Row(children: [
          AeProgressRing(value: .42, label: 'Progress'),
          SizedBox(width: 12),
          Expanded(
              child: ListTile(
                  title: Text('Day 6 of 14'), subtitle: Text('Keep going!')))
        ]),
        CheckboxListTile(
            value: false,
            onChanged: (_) {},
            title: const Text('Meet sleep target')),
        CheckboxListTile(
            value: false,
            onChanged: (_) {},
            title: const Text('Do morning breathing')),
        FilledButton(
            onPressed: () => Navigator.pushNamed(c, Routes.expProgress),
            child: const Text('View progress')),
      ]));
}

