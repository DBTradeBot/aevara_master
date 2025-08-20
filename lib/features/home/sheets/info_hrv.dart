// lib/features/home/sheets/info_hrv.dart
import 'package:flutter/material.dart';

class InfoHrvSheet extends StatelessWidget {
  const InfoHrvSheet({super.key});

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
              Text('HRV 💓 — RMSSD (ms)', style: tt.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Root Mean Square of Successive Differences (RMSSD). Higher usually means '
                    'better recovery—used in readiness scoring with Sleep and Resting HR.',
                style: tt.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text('Where to find it (devices)', style: tt.titleLarge),
              const SizedBox(height: 8),
              Text('- Apple / Garmin: “HRV (RMSSD)” nightly', style: tt.bodyLarge),
              Text('- WHOOP: “Recovery HRV”', style: tt.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
