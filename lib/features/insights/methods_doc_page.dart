// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../core/navigation/app_shell.dart';

class MethodsDocPage extends StatelessWidget {
  const MethodsDocPage({super.key});
  @override
  Widget build(BuildContext c) => AppShell(
      currentIndex: 0,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Methods & Transparency',
            style: Theme.of(c).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
            'Inputs, weighting concept, missing data handling, calibration, change caps, privacy & data flow, model version.'),
      ]));
}

