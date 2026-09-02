// lib/features/about/privacy_page.dart
import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    Widget blurb(String title, String body) => Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              style:
              t.bodyMedium!.copyWith(color: cs.onSurface.withOpacity(.75)),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & data use')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.primary.withOpacity(.15),
                      child: Icon(Icons.privacy_tip_outlined, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Radical transparency', style: t.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            "We show formulas, drivers, and confidence. You control what’s stored. "
                                "Your data is kept private and never shared with anyone.",
                            style: t.bodyMedium!
                                .copyWith(color: cs.onSurface.withOpacity(.75)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Setup specifics reflecting latest onboarding rules
            blurb(
              'What we ask in setup',
              '• First name — required (min 2 characters): used for a personal touch in the app.\n'
                  '• Last name — optional.\n'
                  '• Date of birth — required (must be 13+): used to personalize reference ranges.\n'
                  '• Gender — optional but recommended: improves accuracy of ranges.\n'
                  '• Height & weight — optional but recommended: used for normalization and derived metrics. '
                  'Unit selector uses “kgs” / “lbs” in the UI (stored canonically as kg/lb).\n'
                  '• Profile photo — optional.\n'
                  '\nYou can edit these later in Profile.',
            ),

            blurb(
              'Optional connections',
              'Apple Health, Google Fit, Garmin, WHOOP, Oura. Connecting lets us compute trends across devices. '
                  'You can connect or disconnect anytime in Settings → Connections.',
            ),

            blurb(
              'What we store',
              'Your account ID (UID), handle, first/last name (if provided), date of birth, optional gender, optional height/weight, '
                  'your unit preferences (length and weight), and optional sharing preferences. '
                  'For device connections, we use provider OAuth/official APIs and do not store raw credentials.',
            ),

            blurb(
              'What we don’t do',
              'We do not sell your data. We never post anything publicly without explicit opt-in '
                  '(e.g., optional leaderboards show handle only).',
            ),

            blurb(
              'Controls',
              '• Privacy toggles live under Profile.\n'
                  '• Export or delete your data any time (Profile → Data).',
            ),

            blurb(
              'Security',
              'Data is stored in Firebase with rules scoped to your account. '
                  'Device connections use provider OAuth/official APIs.',
            ),

            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // stub for future doc link
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Full policy coming soon.')),
                );
              },
              icon: const Icon(Icons.description_outlined),
              label: const Text('View full privacy policy'),
            ),
          ],
        ),
      ),
    );
  }
}
