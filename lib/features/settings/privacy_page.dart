<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: ListView(padding: const EdgeInsets.all(16), children: const [
        ListTile(
            title: Text('Export my data'),
            subtitle: Text('CSV/JSON (placeholder)')),
        ListTile(
            title: Text('Delete my account'),
            subtitle: Text('Two-step confirmation (placeholder)')),
      ]));
}

