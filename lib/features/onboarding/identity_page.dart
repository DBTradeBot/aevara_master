// lib/features/onboarding/identity_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../routing/route_paths.dart';
import '../../data/adapters/firestore/user_profile_service_fs.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/models/user_profile.dart'; // NEW: to evaluate profile fields

class IdentityPage extends StatefulWidget {
  const IdentityPage({super.key});

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  final _usernameCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;

  // Firestore-backed profile service
  late final UserProfileService _profiles =
  UserProfileServiceFs(FirebaseFirestore.instance);

  bool _checking = false;
  bool? _available;
  String? _statusMsg;
  Timer? _debouncer;

  // Leaderboards toggle
  bool _showOnBoards = false;

  @override
  void initState() {
    super.initState();
    _rerouteIfDemographicsIncomplete();
  }

  // If demographics are missing, force the Demographics page first
  Future<void> _rerouteIfDemographicsIncomplete() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final UserProfile? p = await _profiles.watchProfile(user.uid).first;
      final missingDemo = (p == null) ||
          (p.dob == null) ||
          (p.gender == null) ||
          ((p.heightCm == null) && (p.weightKg == null));
      if (missingDemo && mounted) {
        // Use replacement so Back doesn't return here first
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context)
                .pushReplacementNamed(RoutePaths.demographics);
          }
        });
      }
    } catch (_) {
      // If any error, stay on this page; user can still proceed.
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _debouncer?.cancel();
    super.dispose();
  }

  String _normalizeHandle(String input) {
    final s = input.trim().toLowerCase();
    // keep letters, numbers, underscore, dot; 3–20 chars
    final filtered = s.replaceAll(RegExp(r'[^a-z0-9._]'), '');
    return filtered;
  }

  Future<void> _checkAvailability(String input) async {
    final h = _normalizeHandle(input);
    if (h.length < 3) {
      setState(() {
        _available = null;
        _statusMsg = 'Use 3–20 characters.';
      });
      return;
    }
    setState(() {
      _checking = true;
      _statusMsg = null;
    });
    try {
      final ok = await _profiles.isUsernameAvailable(h);
      setState(() {
        _available = ok;
        _statusMsg = ok ? 'Available' : 'Taken';
      });
    } catch (e) {
      setState(() {
        _available = null;
        _statusMsg = 'Error checking: $e';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _onUsernameChanged(String v) {
    _debouncer?.cancel();
    _debouncer = Timer(const Duration(milliseconds: 400), () {
      _checkAvailability(v);
    });
  }

  Future<void> _continue() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _statusMsg = 'Not signed in.');
      return;
    }
    final handle = _normalizeHandle(_usernameCtrl.text);
    if (handle.length < 3) {
      setState(() => _statusMsg = 'Use 3–20 characters.');
      return;
    }
    setState(() => _checking = true);
    try {
      // double-check availability then reserve + write on profile
      final ok = await _profiles.isUsernameAvailable(handle);
      if (!ok) {
        setState(() {
          _available = false;
          _statusMsg = 'That handle is taken.';
        });
        return;
      }
      await _profiles.reserveUsername(handle, user.uid);
      await _profiles.createOrUpdatePartial(uid: user.uid, data: {
        'username': handle,
        'username_lower': handle,
        'sharing': {
          'show_on_leaderboards': _showOnBoards,
        },
      });
      if (!mounted) return;
      // New order: go to Connect next
      Navigator.of(context).pushNamed(RoutePaths.home);
    } catch (e) {
      setState(() => _statusMsg = e.toString());
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final okToContinue = (_available ?? false) && !_checking;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your username')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'This will be your public handle',
              style: text.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Use 3–20 characters: letters, numbers, underscore or dot.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameCtrl,
              onChanged: _onUsernameChanged,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 4),
                  child: Text('@', style: TextStyle(fontSize: 18)),
                ),
                prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
                border: const OutlineInputBorder(),
                hintText: 'yourhandle',
                suffixIcon: _checking
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
                    : (_available == true
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : (_available == false
                    ? const Icon(Icons.error, color: Colors.red)
                    : null)),
              ),
            ),
            if (_statusMsg != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusMsg!,
                style: text.bodySmall?.copyWith(
                  color: _available == false
                      ? Colors.red
                      : (_available == true
                      ? Colors.green
                      : Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _showOnBoards,
              onChanged: (v) => setState(() => _showOnBoards = v ?? false),
              title: const Text('Show handle on public leaderboards'),
              subtitle: const Text("If off, you'll appear as ‘Anonymous’."),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: okToContinue ? _continue : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Continue'),
          ),
        ),
      ),
    );
  }
}
