// lib/features/debug/debug_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final _auth = FirebaseAuth.instance;
  bool _busy = false;
  final List<String> _lines = [];

  void _log(String m) {
    setState(() => _lines.add(m));
    // ignore: avoid_print
    print('[DebugPage] $m');
  }

  Future<User> _ensureAuthed() async {
    final u = _auth.currentUser;
    if (u != null) return u;
    throw StateError('No Firebase user. Sign in before running smoke checks.');
  }

  Future<void> _runPublicRead() async {
    setState(() => _busy = true);
    try {
      _log('Public read: trying /tiers/demo (or similar public doc)');
      final doc = await FirebaseFirestore.instance.doc('tiers/demo').get();
      _log('Public read ok. exists=${doc.exists}, path=${doc.reference.path}');
    } catch (e) {
      _log('❌ Public read error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _runSmokeWrite() async {
    setState(() => _busy = true);
    try {
      final user = await _ensureAuthed();
      final uid = user.uid;
      _log('Smoke write: _smoke_write/$uid');
      await FirebaseFirestore.instance
          .doc('_smoke_write/$uid')
          .set({'ping': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      _log('Smoke write OK.');
    } catch (e) {
      _log('❌ Smoke write error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _runAuthEcho() async {
    setState(() => _busy = true);
    try {
      final user = await _ensureAuthed();
      final uid = user.uid;
      _log('Auth echo: write then read _auth_echo/$uid');
      final ref = FirebaseFirestore.instance.doc('_auth_echo/$uid');
      await ref.set({'ts': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      final got = await ref.get();
      _log('Auth echo read OK. exists=${got.exists}, data=${got.data()}');
    } catch (e) {
      _log('❌ Auth echo error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _runUsersMinimal() async {
    setState(() => _busy = true);
    try {
      final user = await _ensureAuthed();
      final uid = user.uid;

      // Minimal, rules-compliant payload
      final firstName = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : 'TestUser';
      final dob = DateTime(1990, 1, 1);

      _log('Users minimal write: users/$uid {first_name, dob: Timestamp}');
      await FirebaseFirestore.instance.doc('users/$uid').set({
        'first_name': firstName,
        'dob': Timestamp.fromDate(dob),
      }, SetOptions(merge: true));

      _log('Users minimal write OK.');
    } catch (e) {
      _log('❌ Users minimal write error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _runAll() async {
    await _runPublicRead();
    await _runSmokeWrite();
    await _runAuthEcho();
    await _runUsersMinimal();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Smoke Checks / Debug')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _busy ? null : _runPublicRead,
                    child: const Text('Public read'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy ? null : _runSmokeWrite,
                    child: const Text('_smoke_write'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy ? null : _runAuthEcho,
                    child: const Text('_auth_echo'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy ? null : _runUsersMinimal,
                    child: const Text('users minimal'),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _runAll,
                    child: const Text('Run ALL'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _lines.length,
                    itemBuilder: (_, i) => Text(
                      _lines[i],
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
