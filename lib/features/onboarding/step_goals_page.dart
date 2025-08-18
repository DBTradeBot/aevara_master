<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import '../../navigation/routes.dart';

class OnboardingGoalsPage extends StatelessWidget {
  const OnboardingGoalsPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Goals (3/4)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Pick your goals'),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            children: [
              'Sleep',
              'Recovery',
              'Steps',
              'Stress',
              'Weight',
              'Mindfulness',
              'Nutrition'
            ]
                .map((t) => FilterChip(
                      label: Text(t),
                      selected: true,
                      onSelected: (_) {},
                    ))
                .toList()),
        const SizedBox(height: 16),
        const Text('Activity level'),
        Slider(value: 0.5, onChanged: (_) => {}),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: () => Navigator.pushNamed(c, Routes.obAvatar),
            child: const Text('Next: Profile Photo')),
      ]));
}

