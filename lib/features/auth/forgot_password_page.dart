<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import '../../core/inputs/text_input.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const TextInput(label: 'Email'),
        const SizedBox(height: 12),
        FilledButton(onPressed: () {}, child: const Text('Send reset link')),
      ]));
}

