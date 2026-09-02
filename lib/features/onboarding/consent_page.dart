// lib/features/onboarding/consent_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_profile.dart';
import '../../state/user_providers.dart';
import '../../routing/route_paths.dart';

class ConsentPage extends ConsumerStatefulWidget {
  const ConsentPage({super.key});
  @override
  ConsumerState<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends ConsumerState<ConsentPage> {
  bool _anonymized = false;
  bool _leaderboards = false;
  bool _saving = false;

  // We’ll still show a subtle progress for initial load, but do NOT block UI.
  bool _hydrating = true;

  @override
  void initState() {
    super.initState();
    _hydrateFromProfile();
  }

  Future<void> _hydrateFromProfile() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      setState(() => _hydrating = false);
      return;
    }

    try {
      final svc = ref.read(userProfileServiceProvider);
      final profile = await svc.watchProfile(uid).first; // tolerant stream
      if (!mounted) return;

      setState(() {
        _anonymized = profile?.sharing?.shareAnonymized ?? false;
        _leaderboards = profile?.sharing?.showOnLeaderboards ?? false;
      });
    } catch (_) {
      // Ignore errors; keep defaults and allow user to proceed.
    } finally {
      if (mounted) setState(() => _hydrating = false);
    }
  }

  Future<void> _saveAndContinue() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final svc = ref.read(userProfileServiceProvider);
      await svc.createOrUpdatePartial(uid: uid, data: {
        'sharing': SharingPrefs(
          shareAnonymized: _anonymized,
          showOnLeaderboards: _leaderboards,
        ).toMap(),
        'onboarding': {'consent_done': true},
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RoutePaths.connect);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    Widget sectionCard({required Widget child}) => Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );

    Widget optionTile({
      required IconData icon,
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.secondaryContainer,
              child: Icon(icon, color: cs.onSecondaryContainer, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: t.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ✅ Always interactive; we don’t gate on a _loaded flag.
                      Switch.adaptive(
                        value: value,
                        onChanged: onChanged,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.75),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Sharing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // Intro
            sectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primary.withOpacity(.12),
                    child: Icon(Icons.privacy_tip_outlined, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your data. Your call.', style: t.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Choose if we can use anonymized stats to improve models and whether your handle can appear on public leaderboards. '
                              'You can change these anytime in Profile.',
                          style:
                          t.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.8)),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, RoutePaths.aboutPrivacy),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('How we use your data'),
                          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 0)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Toggles
            sectionCard(
              child: Column(
                children: [
                  optionTile(
                    icon: Icons.auto_graph_outlined,
                    title: 'Share anonymized stats',
                    subtitle:
                    'Helps improve Aevara’s models and reference ranges. Personal identifiers are removed and data is aggregated.',
                    value: _anonymized,
                    onChanged: (v) => setState(() => _anonymized = v),
                  ),
                  const Divider(height: 20),
                  optionTile(
                    icon: Icons.emoji_events_outlined,
                    title: 'Show handle on leaderboards',
                    subtitle:
                    'Opt in to appear on public leaderboards using your handle only. '
                        'Your real name and email are never shown.',
                    value: _leaderboards,
                    onChanged: (v) => setState(() => _leaderboards = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reassurance
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What’s never shared', style: t.titleMedium),
                  const SizedBox(height: 6),
                  _bullet(t, cs, 'We never sell your data.'),
                  _bullet(t, cs, 'We never post anything without your explicit opt-in.'),
                  _bullet(t, cs, 'Device connections use official provider APIs (OAuth).'),
                  const SizedBox(height: 8),
                  Text(
                    'You can export or delete your data anytime in Profile → Data.',
                    style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.75)),
                  ),
                ],
              ),
            ),

            if (_hydrating) ...[
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('Loading your preferences…', style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _saveAndContinue,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: _saving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Text('Continue'),
          ),
        ),
      ),
    );
  }

  Widget _bullet(TextTheme t, ColorScheme cs, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.8)),
            ),
          ),
        ],
      ),
    );
  }
}
