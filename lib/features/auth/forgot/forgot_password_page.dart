<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Enter your email to receive a reset link.'),
        const SizedBox(height: 8),
        const TextField(
            decoration: InputDecoration(
                labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
        const SizedBox(height: 12),
        FilledButton(onPressed: () {}, child: const Text('Send reset link')),
      ]));
}

