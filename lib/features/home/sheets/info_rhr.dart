// lib/features/home/sheets/info_rhr.dart
import 'package:flutter/material.dart';

class InfoRhrSheet extends StatelessWidget {
  const InfoRhrSheet({super.key});

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
              Text('Resting HR 🫀 — bpm', style: tt.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Lowest sustained heart rate at rest. Lower generally indicates better '
                    'cardio fitness and recovery. We combine it with HRV + Sleep for Readiness.',
                style: tt.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text('Where to find it (devices)', style: tt.titleLarge),
              const SizedBox(height: 8),
              Text('- Apple / Garmin / Fitbit / WHOOP: Resting HR / RHR', style: tt.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
