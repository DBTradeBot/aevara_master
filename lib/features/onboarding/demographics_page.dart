// lib/features/onboarding/demographics_page.dart
// Demographics (Onboarding) — mirrors Cupertino style used in UpdateProfilePage,
// adds Waist measurement sheet, and writes canonical fields.
// Flutter 3.22+, Dart 3.

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

import '../../routing/route_paths.dart';
// Enums for Gender/Units
import '../../data/models/user_profile.dart';

// ---- Visual tokens (match profile page vibe) ----
const _kPad = 16.0;
const _kRadius = 16.0;

// Prime/double-prime display (match Apple typography)
const String _ftMark = '′'; // U+2032
const String _inMark = '″'; // U+2033

class DemographicsPage extends StatefulWidget {
  const DemographicsPage({super.key});
  @override
  State<DemographicsPage> createState() => _DemographicsPageState();
}

class _DemographicsPageState extends State<DemographicsPage> {
  // Services
  final _auth = FirebaseAuth.instance;

  // Name
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();

  // Basics
  DateTime? _dob;
  Gender? _gender;

  // Units prefs (shared with Profile)
  LengthUnit _lenUnit = LengthUnit.cm;
  WeightUnit _wtUnit = WeightUnit.kg;

  // Canonical values (cm/kg) for height/weight/waist
  double? _heightCm;
  double? _weightKg;
  double? _waistCm;

  // Avatar (optional)
  XFile? _avatarPicked;
  String? _avatarUrl;
  bool _uploadingAvatar = false;

  // State
  bool _saving = false;
  String? _error;

  // Ranges/guards
  static const double _minKg = 20.0;
  static const double _maxKg = 350.0;
  static const double _minLb = 45.0;
  static const double _maxLb = 770.0;

  static const double _minHeightCm = 0.0;
  static const double _maxHeightCm = 260.0;

  static const double _minWaistCm = 30.0;
  static const double _maxWaistCm = 200.0;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  Future<User> _ensureAuthed() async {
    final cur = _auth.currentUser;
    if (cur != null) return cur;
    final user = await _auth.authStateChanges().firstWhere((u) => u != null);
    return user!;
  }

  // ---------- Avatar ----------
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
    final user = await _ensureAuthed();
    final uid = user.uid;

    setState(() => _uploadingAvatar = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('user_avatars/$uid.jpg');

      if (kIsWeb) {
        final Uint8List bytes = await file.readAsBytes();
        final task = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avatar upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ---------- Validation ----------
  int? _ageYears(DateTime? d) {
    if (d == null) return null;
    final now = DateTime.now();
    int years = now.year - d.year;
    final hadBirthday =
        (now.month > d.month) || (now.month == d.month && now.day >= d.day);
    if (!hadBirthday) years -= 1;
    return years;
  }

  bool get _firstValid {
    final t = _firstCtrl.text.trim();
    return t.length >= 2;
  }

  bool get _dobValid => _dob != null && (_ageYears(_dob) ?? 0) >= 13;
  bool get _minComplete => _firstValid && _dobValid;

  // ---------- Display helpers (match Profile page) ----------
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

  // ---------- Sheets ----------
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
      _lenUnit = result.unit;
      _heightCm = result.cm;
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

  // ---------- Save ----------
  Future<void> _save() async {
    if (!_minComplete) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final user = await _ensureAuthed();
      final uid = user.uid;
      final ref = FirebaseFirestore.instance.doc('users/$uid');

      // Guard canonical ranges before write
      double? heightCm = _heightCm;
      double? weightKg = _weightKg;
      double? waistCm = _waistCm;

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
        'first_name': _firstCtrl.text.trim(),
        if (_lastCtrl.text.trim().isNotEmpty) 'last_name': _lastCtrl.text.trim(),
        'dob': Timestamp.fromDate(DateTime(_dob!.year, _dob!.month, _dob!.day)),
        if (_gender != null) 'gender': _gender!.name,
        'preferred_units': {
          'length': _lenUnit.name, // 'cm' or 'inch'
          'weight': _wtUnit.name,  // 'kg' or 'lb'
        },
        if (heightCm != null) 'height_cm': double.parse(heightCm.toStringAsFixed(2)),
        if (weightKg != null) 'weight_kg': double.parse(weightKg.toStringAsFixed(2)),
        if (waistCm  != null) 'waist_cm' : double.parse(waistCm.toStringAsFixed(1)),
        if (_avatarUrl != null && _avatarUrl!.isNotEmpty) 'photo_url': _avatarUrl,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Merge so we don’t clear other fields
      await ref.set(payload, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RoutePaths.identity);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile setup')),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(_kPad, 16, _kPad, 120),
          children: [
            // Intro
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dial in your basics', style: text.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'We use these to personalize your ranges and convert units across devices. '
                          'You can edit everything later in Profile.',
                      style: text.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(.75),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(RoutePaths.aboutPrivacy),
                      child: const Text('How we use your data'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Avatar
            _AvatarPicker(
              uploading: _uploadingAvatar,
              avatarUrl: _avatarUrl,
              localFilePath: _avatarPicked?.path,
              onPick: _pickAvatar,
            ),

            const SizedBox(height: 16),

            // Name
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name', style: text.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('First name', style: text.labelLarge),
                        const Text('Required',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _firstCtrl,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ' -]")),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        hintText: 'First name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Last name (optional)', style: text.labelLarge),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _lastCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ' -]")),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        hintText: 'Last name',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Basics: DOB & Gender (Cupertino date + dropdown gender)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basics', style: text.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date of birth', style: text.labelLarge),
                        const Text('Required',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _DobCupertinoField(value: _dob, onTap: _openDobCupertinoPicker),
                    const SizedBox(height: 4),
                    if (_dob != null && !_dobValid)
                      Text('You must be at least 13.',
                          style: text.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    const SizedBox(height: 16),
                    Text('Gender (optional)', style: text.labelLarge),
                    const SizedBox(height: 6),
                    _GenderPicker(
                      value: _gender,
                      onChanged: (g) => setState(() => _gender = g),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optional, but improves accuracy. Data is private and never shared.',
                      style: text.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Body metrics (Cupertino-style row tiles that summon sheets)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Body metrics', style: text.titleMedium),
                    const SizedBox(height: 8),

                    _MetricRowTile(
                      label: 'Height (optional)',
                      valueText: _fmtHeight(_heightCm),
                      onTap: _openHeightSheet,
                    ),

                    const SizedBox(height: 12),

                    _MetricRowTile(
                      label: 'Weight (optional)',
                      valueText: _fmtWeight(_weightKg),
                      onTap: _openWeightSheet,
                    ),

                    const SizedBox(height: 12),

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
              MaterialBanner(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                content: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_minComplete)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  !_firstValid && !_dobValid
                      ? 'Enter your first name and date of birth.'
                      : (!_firstValid
                      ? 'First name must be at least 2 characters.'
                      : (!_dobValid
                      ? 'Enter a valid date of birth (13+).'
                      : '')),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (!_saving && _minComplete) ? _save : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _saving
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Continue'),
              ),
            ),
          ],
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

// ---------- Reused pickers (mirroring UpdateProfilePage) ----------
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
    // Lists
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
  int _lbs = 175;       // integer wheel
  int _kgTimes10 = 700; // 70.0 kg default

  @override
  void initState() {
    super.initState();
    _unit = widget.initialWeightUnit;
    final kg = widget.initialKg;
    if (kg != null && kg > 0) {
      _lbs = (kg / 0.45359237).round().clamp(widget.minLb.round(), widget.maxLb.round());
      _kgTimes10 = (kg * 10).round().clamp((widget.minKg * 10).round(), (widget.maxKg * 10).round());
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

// Avatar display/pick widget (private name avoids cross-file collisions)
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
            'Add a photo (optional). You can change this later in Profile.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
