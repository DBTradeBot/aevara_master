<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import '../../core/utils/snack.dart';

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text(
            'Deleting your account will remove your data. This is a placeholder confirmation screen.'),
        const SizedBox(height: 8),
        FilledButton(
            onPressed: () {
              snack(c, 'Deletion requested (placeholder)');
            },
            child: const Text('Request deletion')),
      ]));
}

