// lib/features/onboarding/demographics_page.dart
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../routing/route_paths.dart';
import '../../data/adapters/firestore/user_profile_service_fs.dart';
import '../../data/models/user_profile.dart';

// Visual tokens
const _kPad = 16.0;
const _kRadius = 16.0;
const _kPrimary = Color(0xFF3F87A6);
const _kTextSecondary = Color(0xFF575C6C);

class DemographicsPage extends StatefulWidget {
  const DemographicsPage({super.key});
  @override
  State<DemographicsPage> createState() => _DemographicsPageState();
}

class _DemographicsPageState extends State<DemographicsPage> {
  // Services
  final _svc = UserProfileServiceFs(FirebaseFirestore.instance);
  final _auth = FirebaseAuth.instance;

  // Name
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();

  // Basics
  DateTime? _dob;
  Gender? _gender;

  // Body metrics
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  LengthUnit _lenUnit = LengthUnit.cm;
  WeightUnit _wtUnit = WeightUnit.kg;

  // Avatar (NEW)
  XFile? _avatarPicked;
  String? _avatarUrl; // downloadURL after upload
  bool _uploadingAvatar = false;

  // State
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ---------- Avatar: pick + upload (NEW) ----------
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ---------- Utils / conversions ----------
  double? _toDouble(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  double? _heightToCm() {
    final v = _toDouble(_heightCtrl);
    if (v == null) return null;
    return _lenUnit == LengthUnit.cm ? v : v * 2.54;
  }

  double? _weightToKg() {
    final v = _toDouble(_weightCtrl);
    if (v == null) return null;
    return _wtUnit == WeightUnit.kg ? v : v * 0.45359237;
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

  bool get _meetsAge => (_ageYears(_dob) ?? 0) >= 13;
  bool get _minComplete => _dob != null && _gender != null && _meetsAge;

  // ---------- Save ----------
  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null || !_minComplete) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final heightCm = _heightToCm();
      final weightKg = _weightToKg();

      await _svc.createOrUpdatePartial(uid: user.uid, data: {
        // Identity
        'uid': user.uid,
        'email': user.email ?? '',
        // Core fields
        'first_name':
        _firstCtrl.text.trim().isEmpty ? null : _firstCtrl.text.trim(),
        'last_name':
        _lastCtrl.text.trim().isEmpty ? null : _lastCtrl.text.trim(),
        if (_dob != null) 'dob': Timestamp.fromDate(_dob!), // ✅ Timestamp
        if (_gender != null) 'gender': _gender!.name,
        'preferred_units': {
          'length': _lenUnit.name,
          'weight': _wtUnit.name,
        },
        if (heightCm != null)
          'height_cm': double.parse(heightCm.toStringAsFixed(2)),
        if (weightKg != null)
          'weight_kg': double.parse(weightKg.toStringAsFixed(2)),
        if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
          'photo_url': _avatarUrl, // NEW
        // Audit: adapter sets updated_at.
      });

      if (!mounted) return;
      // Go to Username next
      Navigator.of(context).pushNamed(RoutePaths.identity);
    } catch (e) {
      setState(() => _error = e.toString());
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
          padding: const EdgeInsets.fromLTRB(_kPad, _kPad, _kPad, 120),
          children: [
            _IntroCard(),
            const SizedBox(height: 12),

            // AVATAR (NEW) — placed right under the intro card
            _AvatarPicker(
              uploading: _uploadingAvatar,
              avatarUrl: _avatarUrl,
              localFilePath: _avatarPicked?.path,
              onPick: _pickAvatar,
            ),

            const SizedBox(height: 16),

            // Names
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(_kPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name', style: text.titleMedium),
                    const SizedBox(height: 12),
                    Text('First name', style: text.labelLarge),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _firstCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'First name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Last name', style: text.labelLarge),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _lastCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Last name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Basics
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(_kPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basics', style: text.titleMedium),
                    const SizedBox(height: 12),
                    Text('Date of birth', style: text.labelLarge),
                    const SizedBox(height: 6),
                    _DobField(
                        value: _dob,
                        onChanged: (d) => setState(() => _dob = d)),
                    const SizedBox(height: 4),
                    Text('Used to personalize ranges.',
                        style:
                        text.bodySmall?.copyWith(color: _kTextSecondary)),
                    if (_dob != null && !_meetsAge)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('You must be at least 13.',
                            style: text.bodySmall
                                ?.copyWith(color: theme.colorScheme.error)),
                      ),
                    const SizedBox(height: 16),
                    Text('Gender', style: text.labelLarge),
                    const SizedBox(height: 6),
                    _GenderPicker(
                        value: _gender,
                        onChanged: (g) => setState(() => _gender = g)),
                    const SizedBox(height: 4),
                    Text('Helps us set appropriate reference ranges.',
                        style:
                        text.bodySmall?.copyWith(color: _kTextSecondary)),
                    const SizedBox(height: 16),
                    Text('Height', style: text.labelLarge),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _heightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              hintText: 'Enter height',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _UnitChips<LengthUnit>(
                          options: {LengthUnit.cm: 'cm', LengthUnit.inch: 'in'},
                          value: _lenUnit,
                          onChanged: (u) => setState(() => _lenUnit = u),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Weight', style: text.labelLarge),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              hintText: 'Enter weight',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _UnitChips<WeightUnit>(
                          options: {WeightUnit.kg: 'kg', WeightUnit.lb: 'lb'},
                          value: _wtUnit,
                          onChanged: (u) => setState(() => _wtUnit = u),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: text.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error)),
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
                  _dob == null || _gender == null
                      ? 'Add your date of birth and gender.'
                      : (!_meetsAge ? 'You must be at least 13.' : ''),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: _kTextSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: (!_saving && _minComplete) ? _save : null,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Sub-widgets ----------
class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(_kPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dial in your basics', style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              'We use these to personalize your ranges and convert units across devices. '
                  'You can edit everything later in Profile.',
              style: text.bodyMedium?.copyWith(color: _kTextSecondary),
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
    );
  }
}

// NEW: Avatar picker block
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
                  ? Icon(Icons.person,
                  size: size * 0.5,
                  color: Theme.of(context).colorScheme.onSecondaryContainer)
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
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.photo_camera,
                      size: 18, color: Colors.white),
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

class _DobField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const _DobField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initial = value ?? DateTime(now.year - 25, now.month, now.day);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: now,
          helpText: 'Select your date of birth',
        );
        onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value == null
              ? 'Select date'
              : '${value!.year.toString().padLeft(4, '0')}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
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
      DropdownMenuItem(
          value: Gender.preferNotSay, child: Text('Prefer not to say')),
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
      ),
    );
  }
}

class _UnitChips<T> extends StatelessWidget {
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  const _UnitChips({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.entries.map((e) {
        final selected = e.key == value;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          onSelected: (_) => onChanged(e.key),
          selectedColor: _kPrimary.withOpacity(0.15),
          labelStyle: TextStyle(
            color:
            selected ? _kPrimary : Theme.of(context).colorScheme.onSurface,
          ),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
