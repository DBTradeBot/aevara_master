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
                Text(body,
                    style: t.bodyMedium!
                        .copyWith(color: cs.onSurface.withOpacity(.75))),
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
                      child:
                          Icon(Icons.privacy_tip_outlined, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Radical transparency', style: t.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            "We show formulas, drivers and confidence. You control what’s stored and shared.",
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
            blurb(
                'What we ask in setup',
                '• Name (optional), date of birth, gender: used to personalize reference ranges.\n'
                    '• Height and weight + units: used for normalization and derived metrics.\n'
                    'You can edit these later in Profile.'),
            blurb('Optional connections',
                'Apple Health, Google Fit, Garmin, WHOOP, Oura. Connecting lets us compute trends across devices. You can connect/disconnect later in Settings → Connections.'),
            blurb('What we store',
                'An account ID (UID), your handle, the fields above, your unit preferences, and optional sharing preferences. We do not store raw credentials for any device providers.'),
            blurb('What we don’t do',
                'We don’t sell your data. We don’t post anything publicly without an explicit opt-in (e.g., leaderboards by handle only).'),
            blurb(
                'Controls',
                '• Privacy toggles live under Profile.\n'
                    '• Export or delete your data any time (Profile → Data).'),
            blurb('Security',
                'Data is stored in Firebase with rules scoped to your account. Device connections use provider OAuth/official APIs.'),
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
