<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import '../../navigation/routes.dart';

class OnboardingAvatarPage extends StatelessWidget {
  const OnboardingAvatarPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Profile Photo (4/4)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SizedBox(height: 12),
        const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 12),
        Center(
            child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload),
                label: const Text('Upload photo'))),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: () => Navigator.pushReplacementNamed(c, Routes.obReady),
            child: const Text('Finish')),
      ]));
}

