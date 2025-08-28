import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // FieldValue
import '../../../state/user_providers.dart';

class ChangeUsernamePage extends ConsumerStatefulWidget {
  const ChangeUsernamePage({super.key});

  @override
  ConsumerState<ChangeUsernamePage> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends ConsumerState<ChangeUsernamePage> {
  final _ctrl = TextEditingController();

  bool _checking = false;
  String? _statusMsg;
  Timer? _debouncer;

  // Result of last availability check
  bool? _available;              // null = unknown, true = ok, false = taken by someone else
  bool _ownerIsSelf = false;     // true when the doc exists and it's owned by me

  // Prefill guard: run exactly once and never after user types.
  bool _didPrefill = false;
  bool _userTyped = false;

  @override
  void dispose() {
    _debouncer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  String _normalize(String input) {
    final s = input.trim().toLowerCase();
    return s.replaceAll(RegExp(r'[^a-z0-9._]'), '');
  }

  void _onChanged(String v) {
    _userTyped = true; // prevent future prefill on rebuild
    _debouncer?.cancel();
    _debouncer = Timer(const Duration(milliseconds: 350), () => _check(v));
  }

  Future<void> _check(String raw) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final h = _normalize(raw);
    if (h.length < 3) {
      setState(() {
        _available = null;
        _ownerIsSelf = false;
        _statusMsg = 'Use 3–20 characters.';
      });
      return;
    }

    setState(() {
      _checking = true;
      _statusMsg = null;
    });

    try {
      // Explicit ownership check: available if no owner OR owner == me
      final svc = ref.read(userProfileServiceProvider);
      final owner = await svc.usernameOwner(h);

      final isMine = (owner != null && owner == uid);
      final ok = (owner == null || isMine);

      setState(() {
        _ownerIsSelf = isMine;
        _available = ok;
        _statusMsg = ok
            ? (isMine ? 'You own this handle' : 'Available')
            : 'Taken';
      });
    } catch (e) {
      setState(() {
        _available = null;
        _ownerIsSelf = false;
        _statusMsg = 'Error: $e';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _save() async {
    final uid = ref.read(currentUserIdProvider);
    final profile = ref.read(currentUserProfileProvider).value;
    if (uid == null) {
      setState(() => _statusMsg = 'Not signed in.');
      return;
    }

    final svc = ref.read(userProfileServiceProvider);
    final next = _normalize(_ctrl.text);
    if (next.length < 3) {
      setState(() => _statusMsg = 'Use 3–20 characters.');
      return;
    }

    // If unchanged, just pop.
    final prevLower = (profile?.usernameLower ?? profile?.username)?.toLowerCase();
    if (prevLower != null && prevLower == next) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _checking = true;
      _statusMsg = null;
    });

    try {
      final owner = await svc.usernameOwner(next);
      if (owner == null) {
        // Fresh claim
        await svc.reserveUsername(next, uid);
      } else if (owner != uid) {
        // Someone else owns it
        setState(() {
          _available = false;
          _ownerIsSelf = false;
          _statusMsg = 'That handle is taken.';
        });
        return;
      }
      // Keep history so you can go back later.
      if (prevLower != null && prevLower.isNotEmpty) {
        await svc.addUsernameHistory(uid: uid, handleLower: prevLower);
      }

      await svc.createOrUpdatePartial(uid: uid, data: {
        'username': next,
        'username_lower': next,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      setState(() => _statusMsg = e.toString());
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // One-time prefill with current username (only if user hasn't started typing)
    final p = ref.watch(currentUserProfileProvider).asData?.value;
    final current = p?.username;
    if (!_didPrefill && !_userTyped && (current != null && current.isNotEmpty)) {
      _ctrl.text = current; // keep original casing in the field
      _ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _ctrl.text.length),
      );
      _didPrefill = true;
    }

    final normalized = _normalize(_ctrl.text);
    final prevLower = (p?.usernameLower ?? p?.username)?.toLowerCase();
    final unchanged = (prevLower != null && prevLower == normalized);

    final canSave = (_available == true) && !_checking && !unchanged;

    return Scaffold(
      appBar: AppBar(title: const Text('Change username')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('This will be your public handle', style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Use 3–20 characters: letters, numbers, underscore or dot.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 4),
                  child: Text('@', style: TextStyle(fontSize: 18)),
                ),
                prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: (current != null && current.isNotEmpty)
                    ? '@$current'
                    : 'yourhandle',
                suffixIcon: _checking
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
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
                      : (_ownerIsSelf ? Colors.green : null),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: canSave ? _save : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Save'),
          ),
        ),
      ),
    );
  }
}
