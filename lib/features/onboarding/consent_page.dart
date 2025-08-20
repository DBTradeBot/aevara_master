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
  bool _productEmails = false;
  bool _saving = false;

  Future<void> _save() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final svc = ref.read(userProfileServiceProvider);
      final profile = await svc.watchProfile(uid).first;
      final updated = (profile ??
          UserProfile(
            uid: uid,
            email: '',
            username: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ))
          .copyWith(
        sharing: SharingPrefs(
          shareAnonymized: _anonymized,
          showOnLeaderboards: _leaderboards,
          receiveProductEmails: _productEmails,
        ),
        updatedAt: DateTime.now(),
      );
      await svc.createOrUpdate(updated);
      if (mounted) Navigator.pushNamed(context, RoutePaths.connect);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Sharing')),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          children: [
            CheckboxListTile(
              value: _anonymized,
              onChanged: (v) => setState(() => _anonymized = v ?? false),
              title: const Text('Share anonymized stats to improve models'),
            ),
            CheckboxListTile(
              value: _leaderboards,
              onChanged: (v) => setState(() => _leaderboards = v ?? false),
              title: const Text('Show handle on public leaderboards'),
            ),
            CheckboxListTile(
              value: _productEmails,
              onChanged: (v) => setState(() => _productEmails = v ?? false),
              title: const Text('Receive important product emails'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator() : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
