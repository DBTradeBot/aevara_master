// lib/features/auth/verify_email_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../routing/route_paths.dart';
import '../onboarding/onboarding_next.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _busy = false;
  String? _info;

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _info = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.sendEmailVerification();
      setState(() => _info = 'Verification email sent.');
    } catch (e) {
      setState(() => _info = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _iveVerified() async {
    setState(() {
      _busy = true;
      _info = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      final fresh = FirebaseAuth.instance.currentUser;
      if (fresh?.emailVerified == true) {
        final uid = fresh!.uid;
        final route = await nextRouteAfterAuth(uid, FirebaseFirestore.instance);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, route);
      } else {
        setState(() => _info = 'Not verified yet. Check your inbox.');
      }
    } catch (e) {
      setState(() => _info = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Almost there', style: t.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'We sent a verification link to:\n${user?.email ?? 'your email'}',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _iveVerified,
              child: const Text("I've verified"),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _resend,
              child: const Text('Resend email'),
            ),
            if (_info != null) ...[
              const SizedBox(height: 12),
              Text(_info!, style: t.bodySmall),
            ],
            const SizedBox(height: 24),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.pushReplacementNamed(
                      context, RoutePaths.signin),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
