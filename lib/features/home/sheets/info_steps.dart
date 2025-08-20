// lib/features/home/sheets/info_steps.dart
import 'package:flutter/material.dart';

class InfoStepsSheet extends StatelessWidget {
  const InfoStepsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text('Activity 👣 — Steps', style: tt.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Daily step count represents overall movement load. We roll it into '
                    'Activity/Load and show short-term changes in Insights.',
                style: tt.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text('Where to find it (devices)', style: tt.titleLarge),
              const SizedBox(height: 8),
              Text('- Apple / Fitbit / Garmin / Oura: Steps or Activity Minutes', style: tt.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
