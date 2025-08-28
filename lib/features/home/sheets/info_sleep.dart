// lib/features/home/sheets/info_sleep.dart
import 'package:flutter/material.dart';

class InfoSleepSheet extends StatelessWidget {
  const InfoSleepSheet({super.key});

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
              Text('Sleep 💤 — What & Why', style: tt.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Total sleep hours for the last night. We use this in recovery/readiness '
                'and long-term healthy-days trends. You can estimate without a device '
                'by entering your time-asleep (not just time-in-bed).',
                style: tt.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text('Where to find it (devices)', style: tt.titleLarge),
              const SizedBox(height: 8),
              Text('- Apple Health / Oura / Fitbit: “Sleep Duration”',
                  style: tt.bodyLarge),
              Text('- WHOOP: Sleep session duration', style: tt.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
