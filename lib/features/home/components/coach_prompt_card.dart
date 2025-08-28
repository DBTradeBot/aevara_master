// lib/features/home/components/coach_prompt_card.dart
//
// CoachPromptCard — simple evening nudge (placeholder; wire to provider later).
// Style follows design tokens (card radius 16, spacing 12/16).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aevara_app/state/user_providers.dart';

class CoachPromptCard extends ConsumerWidget {
  const CoachPromptCard({super.key});

  String _timeGreeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String? _firstFromProfile(dynamic profile) {
    if (profile == null) return null;
    try {
      final candidates = <String?>[
        profile.firstName as String?,
        profile.givenName as String?,
        profile.name as String?,
        profile.displayName as String?,
      ];
      for (final c in candidates) {
        final v = (c ?? '').trim();
        if (v.isNotEmpty) return _cap(v.split(RegExp(r'[ \._-]+')).first);
      }
    } catch (_) {}
    return null;
  }

  String _firstFromAuth({required String? displayName, required String? email}) {
    final dn = (displayName ?? '').trim();
    if (dn.isNotEmpty) return _cap(dn.split(RegExp(r'[ \._-]+')).first);
    final em = (email ?? '').trim();
    if (em.contains('@')) {
      final local = em.split('@').first;
      final token = local.split(RegExp(r'[ \._-]+')).first;
      if (token.isNotEmpty) return _cap(token);
    }
    return 'friend';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authUserProvider).value;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    final dayPart = _timeGreeting(DateTime.now());
    final name = _firstFromProfile(profile) ??
        _firstFromAuth(displayName: auth?.displayName, email: auth?.email);

    // Starter coach copy (we'll swap to data-driven soon)
    final msg = switch (dayPart) {
      'morning'   => "Morning, $name. Aim for steady steps today—short walks count.",
      'afternoon' => "Nice work so far, $name. A 10‑minute reset walk can boost recovery.",
      _           => "Good evening, $name. Keep bedtime consistent—~7.5h tonight is a win."
    };

    final cardBg = theme.colorScheme.surface;
    final cardBorder = theme.dividerColor.withOpacity(
      theme.brightness == Brightness.dark ? 0.08 : 0.10,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            if (theme.brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.tips_and_updates, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
