<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class PrivacyDashboardPage extends StatelessWidget {
  const PrivacyDashboardPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text(
            'Storage explainer: placeholder text about local vs cloud, deletion requests.'),
        const SizedBox(height: 8),
        FilledButton(
            onPressed: () => Navigator.pushNamed(c, '/privacy/export'),
            child: const Text('Export my data')),
        FilledButton(
            onPressed: () => Navigator.pushNamed(c, '/privacy/delete'),
            child: const Text('Delete my account')),
      ]));
}

