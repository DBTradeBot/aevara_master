// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../core/widgets/chip_filters.dart';

class OnboardingGoalsPage extends StatelessWidget {
  const OnboardingGoalsPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Goals (2/3)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Pick your goals'),
        const SizedBox(height: 8),
        const ChipFilters(labels: [
          'Sleep',
          'Recovery',
          'Steps',
          'Stress',
          'Weight',
          'Mindfulness',
          'Nutrition'
        ]),
        const SizedBox(height: 16),
        const Text('Activity level'),
        Slider(value: 0.5, onChanged: (_) => {}),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: () => Navigator.pushNamed(c, Routes.onboardingAvatar),
            child: const Text('Next: Profile Photo')),
      ]));
}
