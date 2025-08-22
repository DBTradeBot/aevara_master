import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../state/user_providers.dart';

/// Privacy controls for profile visibility & communications.
/// Writes to user_profiles/{uid}.sharing.* and receive_product_emails.
class PrivacyDashboardPage extends ConsumerStatefulWidget {
  const PrivacyDashboardPage({super.key});

  @override
  ConsumerState<PrivacyDashboardPage> createState() =>
      _PrivacyDashboardPageState();
}

class _PrivacyDashboardPageState
    extends ConsumerState<PrivacyDashboardPage> {
  bool? _shareAnonymized;
  bool? _showOnLeaderboards;
  bool? _receiveProductEmails;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prime local state one time from the currently loaded profile (if any).
    final p = ref.read(currentUserProfileProvider).value;
    // Use fully null-aware chains (sharing may be null in older docs).
    _shareAnonymized ??= p?.sharing?.shareAnonymized ?? true;
    _showOnLeaderboards ??= p?.sharing?.showOnLeaderboards ?? false;
    _receiveProductEmails ??= p?.sharing?.receiveProductEmails ?? false;
  }

  Future<void> _save() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final svc = ref.read(userProfileServiceProvider);

    setState(() => _saving = true);
    try {
      await svc.createOrUpdatePartial(uid: uid, data: {
        'sharing': {
          'share_anonymized': _shareAnonymized ?? true,
          'show_on_leaderboards': _showOnLeaderboards ?? false,
          'receive_product_emails': _receiveProductEmails ?? false,
        },
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & data controls')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Visibility', style: text.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Share anonymized data to improve Aevara'),
              subtitle: const Text(
                  'Helps us tune models. Never sold; opt out anytime.'),
              value: _shareAnonymized ?? true,
              onChanged: (v) => setState(() => _shareAnonymized = v),
            ),
            SwitchListTile(
              title: const Text('Show my handle on public leaderboards'),
              subtitle: const Text('If off, you appear as “Anonymous”.'),
              value: _showOnLeaderboards ?? false,
              onChanged: (v) => setState(() => _showOnLeaderboards = v),
            ),
            const SizedBox(height: 16),
            Text('Emails', style: text.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Product tips & updates'),
              value: _receiveProductEmails ?? false,
              onChanged: (v) => setState(() => _receiveProductEmails = v),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can export your data or delete your account from Settings. '
                            'We keep an audit of privacy changes for transparency.',
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Save'),
          ),
        ),
      ),
    );
  }
}
