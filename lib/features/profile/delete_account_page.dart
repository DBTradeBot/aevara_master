import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routing/route_paths.dart';

/// Permanently deletes the user account after reauthentication.
/// WARNING: Deleting the auth user does not automatically delete Firestore data.
/// If you have a backend cleanup (Functions), trigger it there.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController(); // type DELETE to enable
  bool _working = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_confirmCtrl.text.trim().toUpperCase() != 'DELETE') {
      setState(() => _error = "Type DELETE to confirm.");
      return;
    }

    setState(() {
      _working = true;
      _error = null;
    });

    try {
      // If email/password account, reauth with password
      final email = user.email;
      if (email != null && email.isNotEmpty) {
        final cred = EmailAuthProvider.credential(
          email: email,
          password: _passwordCtrl.text.trim(),
        );
        await user.reauthenticateWithCredential(cred);
      }
      await user.delete();

      if (!mounted) return;
      // Back to sign-in screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        RoutePaths.signin,
            (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This permanently deletes your account. '
                            'If you signed up with email/password, you must re-enter your password.',
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password (if applicable)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCtrl,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _working ? null : _delete,
          child: _working
              ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Delete account'),
          ),
        ),
      ),
    );
  }
}
