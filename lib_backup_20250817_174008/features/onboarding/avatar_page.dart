// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../core/widgets/avatar.dart';

class OnboardingAvatarPage extends StatelessWidget {
  const OnboardingAvatarPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Profile Photo (3/3)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Center(child: Avatar(size: 90)),
        const SizedBox(height: 8),
        Center(
            child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload),
                label: const Text('Upload photo'))),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: () => Navigator.pushReplacementNamed(c, Routes.ready),
            child: const Text('Finish')),
      ]));
}
