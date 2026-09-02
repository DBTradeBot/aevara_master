// lib/features/settings/account/update_profile_page.dart
// Update Profile (Settings) — Cupertino inputs for Height, Weight, Waist (+ info)
// Canonical Firestore writes: height_cm, weight_kg, waist_cm, preferred_units.{length,weight}
// Node: none (Flutter only).  Flutter 3.22+, Dart 3.

import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routing/route_paths.dart';
import '../../../data/adapters/firestore/user_profile_service_fs.dart';
import '../../../data/models/user_profile.dart';

// ---- Visual tokens ----
const _kPad = 16.0;
const _kRadius = 16.0;
const _kPrimary = Color(0xFF3F87A6);
const _kTextSecondary = Color(0xFF575C6C);

// Prime/double-prime display (match Apple typography)
const String _ftMark = '′'; // U+2032
const String _inMark = '″'; // U+2033

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});
  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  // Services
  final _svc = UserProfileServiceFs(FirebaseFirestore.instance);
  final _auth = FirebaseAuth.instance;

  // Name
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();

  // Basics
  DateTime? _dob;
  Gender? _gender;

  // Avatar
  XFile? _avatarPicked;
  String? _avatarUrl; // downloadURL after upload
  bool _uploadingAvatar = false;

  // Username (inline section)
  final _usernameCtrl = TextEditingController();
  Timer? _usernameDebouncer;
  bool _usernameChecking = false;
  String? _usernameStatus;
  bool? _usernameAvailable;      // null = unknown, true ok, false taken
  bool _usernameOwnerIsSelf = false;
  bool _usernameDidPrefill = false;

  // Units prefs (shared w/ Demographics)
  LengthUnit _lenUnit = LengthUnit.cm;  // affects Height + Waist displays
  WeightUnit _wtUnit = WeightUnit.kg;

  // Canonical values kept in memory (cm/kg)
  double? _heightCm;
  double? _weightKg;
  double? _waistCm; // NEW

  // State
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Keep original doc for minor comparisons/UI
  Map<String, dynamic> _initial = {};

  // Ranges/guards
  static const int _minFeet = 2;
  static const int _maxFeet = 8;
  static const int _minInches = 0;
  static const int _maxInches = 11;

  static const double _minKg = 20.0;
  static const double _maxKg = 350.0;
  static const double _minLb = 45.0;
  static const double _maxLb = 770.0;

  static const double _minHeightCm = 0.0;
  static const double _maxHeightCm = 260.0;

  // Waist sanity range (broad but sane)
  static const double _minWaistCm = 30.0;
  static const double _maxWaistCm = 200.0;

  @override
  void initState() {
    super.initState();
    _loadPrefill();
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _usernameDebouncer?.cancel();
    _usernameCtrl.dispose();
    super.dispose();
  }

  // ---------- Read Firestore and prefill ----------
  Future<void> _loadPrefill() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Not signed in.';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        _initial = Map<String, dynamic>.from(data);

        // Names
        _firstCtrl.text = (data['first_name'] as String?) ?? '';
        _lastCtrl.text  = (data['last_name']  as String?) ?? '';

        // Username prefill
        final currentUsername = (data['username'] as String?) ?? '';
        if (!_usernameDidPrefill && currentUsername.isNotEmpty) {
          _usernameCtrl.text = currentUsername;
          _usernameCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _usernameCtrl.text.length),
          );
          _usernameDidPrefill = true;
        }

        // DOB (Timestamp or String)
        final dobRaw = data['dob'];
        if (dobRaw is String) {
          _dob = DateTime.tryParse(dobRaw);
        } else if (dobRaw is Timestamp) {
          _dob = dobRaw.toDate();
        } else {
          _dob = null;
        }

        // Gender
        final gStr = data['gender'];
        if (gStr is String && gStr.isNotEmpty) {
          _gender = Gender.values.firstWhere(
                (g) => g.name == gStr,
            orElse: () => Gender.preferNotSay,
          );
        }

        // Units (prefs)
        final pref = (data['preferred_units'] as Map<String, dynamic>?) ?? {};
        final lenStr = (pref['length'] as String?) ?? 'cm';
        final wtStr  = (pref['weight'] as String?) ?? 'kg';
        _lenUnit = (lenStr == LengthUnit.inch.name) ? LengthUnit.inch : LengthUnit.cm;
        _wtUnit  = (wtStr == WeightUnit.lb.name)   ? WeightUnit.lb   : WeightUnit.kg;

        // Canonical metrics
        _heightCm = (data['height_cm'] as num?)?.toDouble();
        _weightKg = (data['weight_kg'] as num?)?.toDouble();
        _waistCm  = (data['waist_cm']  as num?)?.toDouble(); // NEW

        // Avatar
        _avatarUrl = data['photo_url'] as String?;
      }

      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load profile: $e';
      });
    }
  }

  // ---------- Avatar: pick + upload ----------
  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 88,
      );
      if (picked == null) return;
      setState(() => _avatarPicked = picked);
      await _uploadAvatar(picked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _uploadAvatar(XFile file) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('user_avatars/$uid.jpg');

      if (kIsWeb) {
        final Uint8List bytes = await file.readAsBytes();
        final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        _avatarUrl = await task.ref.getDownloadURL();
      } else {
        final task = await ref.putFile(
          File(file.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        _avatarUrl = await task.ref.getDownloadURL();
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ---------- Username (inline) ----------
  String _normalizeHandle(String input) {
    final s = input.trim().toLowerCase();
    return s.replaceAll(RegExp(r'[^a-z0-9._]'), '');
  }

  void _onUsernameChanged(String v) {
    _usernameDebouncer?.cancel();
    _usernameDebouncer = Timer(const Duration(milliseconds: 350), () {
      _checkUsername(v);
    });
  }

  Future<void> _checkUsername(String raw) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final h = _normalizeHandle(raw);
    if (h.length < 3) {
      setState(() {
        _usernameAvailable = null;
        _usernameOwnerIsSelf = false;
        _usernameStatus = 'Use 3–20 characters.';
      });
      return;
    }

    setState(() {
      _usernameChecking = true;
      _usernameStatus = null;
    });

    try {
      final owner = await _svc.usernameOwner(h); // returns uid or null
      final isMine = (owner != null && owner == uid);
      final ok = (owner == null || isMine);

      setState(() {
        _usernameOwnerIsSelf = isMine;
        _usernameAvailable = ok;
        _usernameStatus = ok
            ? (isMine ? 'You own this handle' : 'Available')
            : 'Taken';
      });
    } catch (e) {
      setState(() {
        _usernameAvailable = null;
        _usernameOwnerIsSelf = false;
        _usernameStatus = 'Error: $e';
      });
    } finally {
      if (mounted) setState(() => _usernameChecking = false);
    }
  }

  Future<void> _saveUsername() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _usernameStatus = 'Not signed in.');
      return;
    }

    final next = _normalizeHandle(_usernameCtrl.text);
    if (next.length < 3 || next.length > 20) {
      setState(() => _usernameStatus = 'Use 3–20 characters.');
      return;
    }

    final prev = (_initial['username_lower'] as String?) ??
        (_initial['username'] as String?)?.toLowerCase();
    if (prev != null && prev == next) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }

    setState(() {
      _usernameChecking = true;
      _usernameStatus = null;
    });

    try {
      final owner = await _svc.usernameOwner(next);
      if (owner == null) {
        await _svc.reserveUsername(next, uid);
      } else if (owner != uid) {
        setState(() {
          _usernameAvailable = false;
          _usernameOwnerIsSelf = false;
          _usernameStatus = 'That handle is taken.';
        });
        return;
      }

      if (prev != null && prev.isNotEmpty) {
        await _svc.addUsernameHistory(uid: uid, handleLower: prev);
      }

      await _svc.createOrUpdatePartial(uid: uid, data: {
        'username': next,
        'username_lower': next,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _initial['username'] = next;
      _initial['username_lower'] = next;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
      setState(() {
        _usernameAvailable = true;
        _usernameOwnerIsSelf = true;
        _usernameStatus = 'Saved';
      });
    } catch (e) {
      setState(() => _usernameStatus = e.toString());
    } finally {
      if (mounted) setState(() => _usernameChecking = false);
    }
  }

  // ---------- Display helpers ----------
  String _fmtHeight(double? cm) {
    if (cm == null || cm <= 0) return '—';
    if (_lenUnit == LengthUnit.inch) {
      final totalIn = cm / 2.54;
      final feet = totalIn ~/ 12;
      final inches = (totalIn - feet * 12).round().clamp(0, 11);
      return '$feet$_ftMark $inches$_inMark';
    } else {
      final m = (cm ~/ 100);
      final rem = (cm - m * 100).round();
      return '${m} m ${rem} cm';
    }
  }

  String _fmtWaist(double? cm) {
    if (cm == null || cm <= 0) return '—';
    if (_lenUnit == LengthUnit.inch) {
      final inches = (cm / 2.54);
      return '${inches.toStringAsFixed(0)} in';
    } else {
      return '${cm.toStringAsFixed(0)} cm';
    }
  }

  String _fmtWeight(double? kg) {
    if (kg == null || kg <= 0) return '—';
    if (_wtUnit == WeightUnit.lb) {
      final lbs = kg / 0.45359237;
      return '${lbs.toStringAsFixed(0)} lb';
    } else {
      return '${kg.toStringAsFixed(1)} kg';
    }
  }

  // ---------- Save ----------
  bool get _canSave => !_saving; // profile page has minimal gating

  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uid = user.uid;
      final ref = FirebaseFirestore.instance.doc('users/$uid');

      // Validate guards on canonical values before write
      double? heightCm = _heightCm;
      double? weightKg = _weightKg;
      double? waistCm  = _waistCm;

      if (heightCm != null) {
        if (heightCm <= _minHeightCm || heightCm > _maxHeightCm) heightCm = null;
      }
      if (weightKg != null) {
        if (weightKg < _minKg || weightKg > _maxKg) weightKg = null;
      }
      if (waistCm != null) {
        if (waistCm < _minWaistCm || waistCm > _maxWaistCm) waistCm = null;
      }

      final payload = <String, dynamic>{
        'uid': uid,
        if ((user.email ?? '').isNotEmpty) 'email': user.email,
        if (_firstCtrl.text.trim().isNotEmpty) 'first_name': _firstCtrl.text.trim(),
        if (_lastCtrl.text.trim().isNotEmpty) 'last_name': _lastCtrl.text.trim(),
        if (_dob != null)
          'dob': Timestamp.fromDate(DateTime(_dob!.year, _dob!.month, _dob!.day)),
        if (_gender != null) 'gender': _gender!.name,
        'preferred_units': {
          'length': _lenUnit.name, // 'cm' or 'inch'
          'weight': _wtUnit.name,  // 'kg' or 'lb'
        },
        if (heightCm != null) 'height_cm': double.parse(heightCm.toStringAsFixed(2)),
        if (weightKg != null) 'weight_kg': double.parse(weightKg.toStringAsFixed(2)),
        if (waistCm  != null) 'waist_cm' : double.parse(waistCm.toStringAsFixed(1)),
        if (_avatarUrl != null && _avatarUrl!.startsWith('http')) 'photo_url': _avatarUrl,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await ref.set(payload, SetOptions(merge: true));

      // Update local cache for UX
      _initial = {..._initial, ...payload};

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- Cupertino Sheets ----------
  Future<void> _openHeightSheet() async {
    final result = await showCupertinoModalPopup<_LenPickResult>(
      context: context,
      builder: (ctx) => _HeightSheet(
        initialLenUnit: _lenUnit,
        initialCm: _heightCm,
      ),
    );
    if (result == null) return;
    setState(() {
      _lenUnit = result.unit;        // update pref immediately for display
      _heightCm = result.cm;         // canonical
    });
  }

  Future<void> _openWeightSheet() async {
    final result = await showCupertinoModalPopup<_WeightPickResult>(
      context: context,
      builder: (ctx) => _WeightSheet(
        initialWeightUnit: _wtUnit,
        initialKg: _weightKg,
        minKg: _minKg,
        maxKg: _maxKg,
        minLb: _minLb,
        maxLb: _maxLb,
      ),
    );
    if (result == null) return;
    setState(() {
      _wtUnit = result.unit;
      _weightKg = result.kg;
    });
  }

  Future<void> _openWaistSheet() async {
    final result = await showCupertinoModalPopup<_LenPickResult>(
      context: context,
      builder: (ctx) => _WaistSheet(
        initialLenUnit: _lenUnit,
        initialCm: _waistCm,
        minCm: _minWaistCm,
        maxCm: _maxWaistCm,
      ),
    );
    if (result == null) return;
    setState(() {
      _lenUnit = result.unit;
      _waistCm = result.cm;
    });
  }

  // ---------- DOB picker ----------
  Future<void> _openDobCupertinoPicker() async {
    final now = DateTime.now();
    final maxAllowed = DateTime(now.year - 13, now.month, now.day);
    final fallback = DateTime(now.year - 25, now.month, now.day);
    final candidate = _dob ?? fallback;
    final initial = candidate.isAfter(maxAllowed) ? maxAllowed : candidate;

    DateTime temp = initial;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return _CupertinoBottomSheet(
          title: 'Date of birth',
          onCancel: () => Navigator.of(ctx).pop(),
          onDone: () {
            setState(() => _dob = temp);
            Navigator.of(ctx).pop();
          },
          child: SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initial,
              maximumDate: maxAllowed,
              minimumDate: DateTime(1900, 1, 1),
              onDateTimeChanged: (d) => temp = d,
              use24hFormat: true,
            ),
          ),
        );
      },
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    final prevUsernameLower =
        (_initial['username_lower'] as String?) ??
            (_initial['username'] as String?)?.toLowerCase();
    final normalizedCurrent = _normalizeHandle(_usernameCtrl.text);
    final usernameUnchanged =
        prevUsernameLower != null && prevUsernameLower == normalizedCurrent;
    final canSaveUsername =
        (_usernameAvailable == true || _usernameOwnerIsSelf) &&
            !_usernameChecking &&
            !usernameUnchanged;

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(_kPad, 8, _kPad, 96),
          children: [
            // AVATAR
            _AvatarPicker(
              uploading: _uploadingAvatar,
              avatarUrl: _avatarUrl,
              localFilePath: _avatarPicked?.path,
              onPick: _pickAvatar,
            ),
            const SizedBox(height: 12),

            // USERNAME
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Username', style: text.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _usernameCtrl,
                            onChanged: _onUsernameChanged,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 12, right: 4),
                                child: Text('@', style: TextStyle(fontSize: 18)),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0, minHeight: 0,
                              ),
                              hintText:
                              (_initial['username'] as String?)?.isNotEmpty ==
                                  true
                                  ? '@${_initial['username']}'
                                  : 'yourhandle',
                              suffixIcon: _usernameChecking
                                  ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                                  : (_usernameAvailable == true ||
                                  _usernameOwnerIsSelf)
                                  ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                                  : (_usernameAvailable == false
                                  ? const Icon(Icons.error,
                                  color: Colors.red)
                                  : null),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: canSaveUsername ? _saveUsername : null,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    if (_usernameStatus != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _usernameStatus!,
                        style: text.bodySmall?.copyWith(
                          color: _usernameAvailable == false
                              ? theme.colorScheme.error
                              : (_usernameOwnerIsSelf
                              ? Colors.green
                              : _kTextSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Names
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name', style: text.titleMedium),
                    const SizedBox(height: 8),
                    Text('First name', style: text.labelLarge),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _firstCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ' -]"),
                        ),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        hintText: 'First name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Last name', style: text.labelLarge),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _lastCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ' -]"),
                        ),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        hintText: 'Last name',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Basics (DOB/Gender)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basics', style: text.titleMedium),
                    const SizedBox(height: 8),
                    Text('Date of birth', style: text.labelLarge),
                    const SizedBox(height: 6),
                    _DobCupertinoField(
                      value: _dob,
                      onTap: _openDobCupertinoPicker,
                    ),
                    const SizedBox(height: 12),
                    Text('Gender (optional)', style: text.labelLarge),
                    const SizedBox(height: 6),
                    _GenderPicker(
                      value: _gender,
                      onChanged: (g) => setState(() => _gender = g),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Body metrics
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Body metrics', style: text.titleMedium),
                    const SizedBox(height: 8),

                    // Height
                    _MetricRowTile(
                      label: 'Height (optional)',
                      valueText: _fmtHeight(_heightCm),
                      onTap: _openHeightSheet,
                    ),

                    const SizedBox(height: 12),

                    // Weight
                    _MetricRowTile(
                      label: 'Weight (optional)',
                      valueText: _fmtWeight(_weightKg),
                      onTap: _openWeightSheet,
                    ),

                    const SizedBox(height: 12),

                    // Waist + info
                    _MetricRowTile(
                      label: 'Waist (optional)',
                      valueText: _fmtWaist(_waistCm),
                      onTap: _openWaistSheet,
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        tooltip: 'Why waist matters',
                        onPressed: () => _showWaistInfo(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canSave ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _saving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Save changes'),
          ),
        ),
      ),
    );
  }

  // ---------- Waist info ----------
  void _showWaistInfo(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => _CupertinoBottomSheet(
        title: 'About Waist',
        onCancel: () => Navigator.of(ctx).pop(),
        onDone: () => Navigator.of(ctx).pop(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 8),
                Text('What it is'),
                SizedBox(height: 6),
                Text(
                  'Waist circumference is the measurement around your belly at the level of your navel (or midpoint between the lower rib and top of the hip).',
                ),
                SizedBox(height: 12),
                Text('Why it matters'),
                SizedBox(height: 6),
                Text(
                  'It’s a strong signal for cardio-metabolic risk. Many guidelines flag higher risk at ~35″ (88 cm) for women and ~40″ (102 cm) for men.',
                ),
                SizedBox(height: 12),
                Text('How to measure quickly'),
                SizedBox(height: 6),
                Text(
                  'Stand, exhale normally, wrap a soft tape horizontally around your middle at the navel, snug but not compressing. Read at the end of a normal breath. No tape? Use your pants waist size as a starting value and refine later.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// ===================  Sub-widgets / Sheets  ==================
// =============================================================

class _MetricRowTile extends StatelessWidget {
  final String label;
  final String valueText;
  final VoidCallback onTap;
  final Widget? trailing;
  const _MetricRowTile({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.labelLarge),
                  const SizedBox(height: 4),
                  Text(valueText, style: text.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null) trailing!,
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _CupertinoBottomSheet extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final Widget child;

  const _CupertinoBottomSheet({
    required this.title,
    required this.onCancel,
    required this.onDone,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: onDone,
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              child,
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Height Sheet ----------
class _HeightSheet extends StatefulWidget {
  final LengthUnit initialLenUnit;
  final double? initialCm;
  const _HeightSheet({
    required this.initialLenUnit,
    required this.initialCm,
  });

  @override
  State<_HeightSheet> createState() => _HeightSheetState();
}

class _HeightSheetState extends State<_HeightSheet> {
  late LengthUnit _unit;
  int _feet = 5;
  int _inches = 10;
  int _meters = 1;
  int _centis = 75;

  static const int minFeet = 2, maxFeet = 8;
  static const int minIn = 0, maxIn = 11;

  static const int minM = 0, maxM = 2;
  static const int minCm = 0, maxCm = 99;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialLenUnit;
    final cm = widget.initialCm;
    if (cm != null && cm > 0) {
      if (_unit == LengthUnit.inch) {
        final total = cm / 2.54;
        _feet = total ~/ 12;
        _inches = (total - _feet * 12).round().clamp(0, 11);
        _feet = _feet.clamp(minFeet, maxFeet);
      } else {
        final total = cm.round().clamp(0, 260);
        _meters = total ~/ 100;
        _centis = total % 100;
        _meters = _meters.clamp(minM, maxM);
        _centis = _centis.clamp(minCm, maxCm);
      }
    }
  }

  double _toCm() {
    if (_unit == LengthUnit.inch) {
      final totalIn = (_feet * 12) + _inches;
      return totalIn * 2.54;
    } else {
      return (_meters * 100.0) + _centis;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CupertinoBottomSheet(
      title: 'Height',
      onCancel: () => Navigator.of(context).pop(),
      onDone: () {
        final cm = _toCm().clamp(0, 260).toDouble();
        Navigator.of(context).pop<_LenPickResult>(_LenPickResult(unit: _unit, cm: cm));
      },
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoSegmentedControl<LengthUnit>(
              children: const {
                LengthUnit.inch: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('ft / in')),
                LengthUnit.cm: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('m / cm')),
              },
              groupValue: _unit,
              onValueChanged: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _unit == LengthUnit.inch
                  ? Row(
                children: [
                  Expanded(child: _wheel(minFeet, maxFeet, _feet, (i) => setState(() => _feet = i), label: 'ft')),
                  Expanded(child: _wheel(minIn, maxIn, _inches, (i) => setState(() => _inches = i), label: 'in')),
                ],
              )
                  : Row(
                children: [
                  Expanded(child: _wheel(minM, maxM, _meters, (i) => setState(() => _meters = i), label: 'm')),
                  Expanded(child: _wheel(minCm, maxCm, _centis, (i) => setState(() => _centis = i), label: 'cm')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel(int min, int max, int value, ValueChanged<int> onChanged, {required String label}) {
    final items = List<int>.generate(max - min + 1, (i) => min + i);
    final initialIndex = (value - min).clamp(0, items.length - 1);
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: initialIndex),
      itemExtent: 36,
      onSelectedItemChanged: (i) => onChanged(items[i]),
      children: [for (final v in items) Center(child: Text('$v $label'))],
    );
  }
}

// ---------- Waist Sheet ----------
class _WaistSheet extends StatefulWidget {
  final LengthUnit initialLenUnit;
  final double? initialCm;
  final double minCm;
  final double maxCm;
  const _WaistSheet({
    required this.initialLenUnit,
    required this.initialCm,
    required this.minCm,
    required this.maxCm,
  });

  @override
  State<_WaistSheet> createState() => _WaistSheetState();
}

class _WaistSheetState extends State<_WaistSheet> {
  late LengthUnit _unit;
  int _inches = 32; // rounded inches
  int _centis = 80; // rounded cm

  @override
  void initState() {
    super.initState();
    _unit = widget.initialLenUnit;
    final cm = widget.initialCm;
    if (cm != null && cm > 0) {
      _centis = cm.round().clamp(30, 200);
      _inches = (cm / 2.54).round().clamp(12, 80);
    }
  }

  double _toCm() {
    if (_unit == LengthUnit.inch) {
      return (_inches.toDouble() * 2.54);
    } else {
      return _centis.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build simple integer wheels (real-world granularity is fine at 1 unit)
    final cmValues = List<int>.generate(171, (i) => 30 + i); // 30..200
    final inValues = List<int>.generate(69, (i) => 12 + i);  // 12..80

    final cmIndex = cmValues.indexOf(_centis).clamp(0, cmValues.length - 1);
    final inIndex = inValues.indexOf(_inches).clamp(0, inValues.length - 1);

    return _CupertinoBottomSheet(
      title: 'Waist',
      onCancel: () => Navigator.of(context).pop(),
      onDone: () {
        final cm = _toCm().clamp(widget.minCm, widget.maxCm);
        Navigator.of(context).pop<_LenPickResult>(_LenPickResult(unit: _unit, cm: cm));
      },
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoSegmentedControl<LengthUnit>(
              children: const {
                LengthUnit.inch: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('in')),
                LengthUnit.cm: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('cm')),
              },
              groupValue: _unit,
              onValueChanged: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _unit == LengthUnit.inch
                  ? CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: inIndex),
                itemExtent: 36,
                onSelectedItemChanged: (i) => setState(() => _inches = inValues[i]),
                children: [for (final v in inValues) Center(child: Text('$v in'))],
              )
                  : CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: cmIndex),
                itemExtent: 36,
                onSelectedItemChanged: (i) => setState(() => _centis = cmValues[i]),
                children: [for (final v in cmValues) Center(child: Text('$v cm'))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Weight Sheet ----------
class _WeightSheet extends StatefulWidget {
  final WeightUnit initialWeightUnit;
  final double? initialKg;
  final double minKg;
  final double maxKg;
  final double minLb;
  final double maxLb;
  const _WeightSheet({
    required this.initialWeightUnit,
    required this.initialKg,
    required this.minKg,
    required this.maxKg,
    required this.minLb,
    required this.maxLb,
  });

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  late WeightUnit _unit;
  int _lbs = 175;    // integer wheel
  int _kgTimes10 = 750; // tenths kg => e.g., 75.0 kg == 750

  @override
  void initState() {
    super.initState();
    _unit = widget.initialWeightUnit;
    final kg = widget.initialKg;
    if (kg != null && kg > 0) {
      _lbs = (kg / 0.45359237).round().clamp(widget.minLb.round(), widget.maxLb.round());
      _kgTimes10 = (kg * 10).round().clamp((widget.minKg * 10).round(), (widget.maxKg * 10).round());
    } else {
      // default safe mids
      _lbs = 170;
      _kgTimes10 = 700; // 70.0
    }
  }

  double _toKg() {
    if (_unit == WeightUnit.lb) {
      return _lbs * 0.45359237;
    } else {
      return _kgTimes10 / 10.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build lists
    final lbValues = List<int>.generate((widget.maxLb - widget.minLb).round() + 1,
            (i) => widget.minLb.round() + i);
    final kg10Values = List<int>.generate((widget.maxKg * 10 - widget.minKg * 10).round() + 1,
            (i) => (widget.minKg * 10).round() + i);

    final lbIndex = lbValues.indexOf(_lbs).clamp(0, lbValues.length - 1);
    final kgIndex = kg10Values.indexOf(_kgTimes10).clamp(0, kg10Values.length - 1);

    return _CupertinoBottomSheet(
      title: 'Weight',
      onCancel: () => Navigator.of(context).pop(),
      onDone: () {
        final kg = _toKg().clamp(widget.minKg, widget.maxKg);
        Navigator.of(context).pop<_WeightPickResult>(_WeightPickResult(unit: _unit, kg: kg));
      },
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoSegmentedControl<WeightUnit>(
              children: const {
                WeightUnit.lb: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('lb')),
                WeightUnit.kg: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('kg')),
              },
              groupValue: _unit,
              onValueChanged: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _unit == WeightUnit.lb
                  ? CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: lbIndex),
                itemExtent: 36,
                onSelectedItemChanged: (i) => setState(() => _lbs = lbValues[i]),
                children: [for (final v in lbValues) Center(child: Text('$v lb'))],
              )
                  : CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: kgIndex),
                itemExtent: 36,
                onSelectedItemChanged: (i) => setState(() => _kgTimes10 = kg10Values[i]),
                children: [
                  for (final v in kg10Values)
                    Center(child: Text('${(v / 10).toStringAsFixed(1)} kg')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Small DTOs ----------
class _LenPickResult {
  final LengthUnit unit;
  final double cm;
  _LenPickResult({required this.unit, required this.cm});
}

class _WeightPickResult {
  final WeightUnit unit;
  final double kg;
  _WeightPickResult({required this.unit, required this.kg});
}

// ---------- Reused Sub-widgets ----------
class _DobCupertinoField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;
  const _DobCupertinoField({required this.value, required this.onTap});

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '$y-$m-$da';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value == null ? 'Select date' : _fmt(value!),
          style: text.bodyMedium,
        ),
      ),
    );
  }
}

class _GenderPicker extends StatelessWidget {
  final Gender? value;
  final ValueChanged<Gender?> onChanged;
  const _GenderPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = const [
      DropdownMenuItem(value: Gender.male, child: Text('Male')),
      DropdownMenuItem(value: Gender.female, child: Text('Female')),
      DropdownMenuItem(value: Gender.nonbinary, child: Text('Non-binary')),
      DropdownMenuItem(value: Gender.preferNotSay, child: Text('Prefer not to say')),
      DropdownMenuItem(value: Gender.other, child: Text('Other')),
    ];

    return DropdownButtonFormField<Gender>(
      value: value,
      items: items,
      onChanged: onChanged,
      isDense: true,
      decoration: const InputDecoration(
        hintText: 'Select',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final bool uploading;
  final String? avatarUrl;
  final String? localFilePath;
  final VoidCallback onPick;

  const _AvatarPicker({
    required this.uploading,
    required this.avatarUrl,
    required this.localFilePath,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final size = 86.0;

    ImageProvider? provider;
    if (localFilePath != null && !kIsWeb) {
      provider = FileImage(File(localFilePath!));
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      provider = NetworkImage(avatarUrl!);
    }

    return Row(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: size / 2,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              backgroundImage: provider,
              child: provider == null
                  ? Icon(
                Icons.person,
                size: size * 0.5,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              )
                  : null,
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: InkWell(
                onTap: uploading ? null : onPick,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: uploading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.photo_camera, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Add a photo (optional).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
