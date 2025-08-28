// lib/features/settings/account/update_profile_page.dart
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routing/route_paths.dart';
import '../../../data/adapters/firestore/user_profile_service_fs.dart';
import '../../../data/models/user_profile.dart';
import '../../about/privacy_page.dart'; // ✅ correct import

// ---- Visual tokens (match onboarding) ----
const _kPad = 16.0;
const _kRadius = 16.0;
const _kPrimary = Color(0xFF3F87A6);
const _kTextSecondary = Color(0xFF575C6C);

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

  // Body metrics
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  LengthUnit _lenUnit = LengthUnit.cm;
  WeightUnit _wtUnit = WeightUnit.kg;

  // Avatar
  XFile? _avatarPicked;
  String? _avatarUrl; // downloadURL after upload
  bool _uploadingAvatar = false;

  // State
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Keep the original doc so we can compute a minimal patch and preserve types.
  Map<String, dynamic> _initial = {};

  @override
  void initState() {
    super.initState();
    _loadPrefill();
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
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
          .collection('user_profiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        _initial = Map<String, dynamic>.from(data);

        // Names
        _firstCtrl.text = (data['first_name'] as String?) ?? '';
        _lastCtrl.text  = (data['last_name']  as String?) ?? '';

        // DOB: accept String (legacy) or Timestamp (new-ish)
        final dobRaw = data['dob'];
        if (dobRaw is String) {
          _dob = DateTime.tryParse(dobRaw);
        } else if (dobRaw is Timestamp) {
          _dob = dobRaw.toDate();
        } else {
          _dob = null;
        }

        // Gender (enum name)
        final gStr = data['gender'];
        if (gStr is String && gStr.isNotEmpty) {
          _gender = Gender.values.firstWhere(
                (g) => g.name == gStr,
            orElse: () => Gender.preferNotSay,
          );
        }

        // Units
        final pref  = (data['preferred_units'] as Map<String, dynamic>?) ?? {};
        final lenStr = (pref['length'] as String?) ?? 'cm';
        final wtStr  = (pref['weight'] as String?) ?? 'kg';
        _lenUnit = (lenStr == LengthUnit.inch.name) ? LengthUnit.inch : LengthUnit.cm;
        _wtUnit  = (wtStr == WeightUnit.lb.name)   ? WeightUnit.lb   : WeightUnit.kg;

        // Height/Weight (stored canonical in cm/kg)
        final heightCm = (data['height_cm'] as num?)?.toDouble();
        final weightKg = (data['weight_kg'] as num?)?.toDouble();
        if (heightCm != null) {
          final displayHeight = _lenUnit == LengthUnit.cm ? heightCm : heightCm / 2.54;
          _heightCtrl.text = _trimNum(displayHeight);
        }
        if (weightKg != null) {
          final displayWeight = _wtUnit == WeightUnit.kg ? weightKg : weightKg / 0.45359237;
          _weightCtrl.text = _trimNum(displayWeight);
        }

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

  String _trimNum(double v) {
    final s = v.toStringAsFixed(2);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  bool _nearlyEqual(num a, num b, {double eps = 1e-6}) => (a - b).abs() <= eps;

  bool _isHttpUrl(String? s) =>
      s != null && s.isNotEmpty && (s.startsWith('http://') || s.startsWith('https://'));

  DateTime? _normalizeDob(dynamic dobRaw) {
    if (dobRaw == null) return null;
    if (dobRaw is Timestamp) return dobRaw.toDate();
    if (dobRaw is String) return DateTime.tryParse(dobRaw);
    return null;
  }

  String _fmtYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

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

  bool get _ageIsValid => (_ageYears(_dob) ?? 1000) >= 13;
  bool get _canSave => _saving ? false : _ageIsValid;

  // ---------- Patch builder (minimal, sanitized; preserves DOB type) ----------
  Map<String, dynamic> _buildProfilePatch() {
    final Map<String, dynamic> patch = {};

    // First/Last name (only include if non-empty AND different)
    final initialFirst = (_initial['first_name'] as String?) ?? '';
    final initialLast  = (_initial['last_name']  as String?) ?? '';
    final newFirst = _firstCtrl.text.trim();
    final newLast  = _lastCtrl.text.trim();
    if (newFirst.isNotEmpty && newFirst != initialFirst) {
      patch['first_name'] = newFirst;
    }
    if (newLast.isNotEmpty && newLast != initialLast) {
      patch['last_name'] = newLast;
    }

    // DOB — preserve stored type; default to string to satisfy rules
    final initialDobRaw = _initial['dob'];
    if (_dob != null) {
      final initialDob = _normalizeDob(initialDobRaw);
      final sameDay = initialDob != null &&
          initialDob.year == _dob!.year &&
          initialDob.month == _dob!.month &&
          initialDob.day == _dob!.day;

      if (!sameDay) {
        if (initialDobRaw is Timestamp) {
          patch['dob'] = Timestamp.fromDate(_dob!);
        } else {
          // Either it was a String or absent → keep/write string
          patch['dob'] = _fmtYmd(_dob!);
        }
      }
    }

    // Gender (must be one of: male|female|nonbinary|preferNotSay|other)
    final initialGender = (_initial['gender'] as String?) ?? '';
    final newGender = _gender?.name;
    if (newGender != null && newGender.isNotEmpty && newGender != initialGender) {
      patch['gender'] = newGender;
    }

    // Units (length: cm|inch, weight: kg|lb)
    final initialPref = (_initial['preferred_units'] as Map?) ?? const {};
    final initialLen  = (initialPref['length'] as String?) ?? 'cm';
    final initialWt   = (initialPref['weight'] as String?) ?? 'kg';
    final newLen = _lenUnit.name; // cm or inch
    final newWt  = _wtUnit.name;  // kg or lb
    if (newLen != initialLen || newWt != initialWt) {
      patch['preferred_units'] = {'length': newLen, 'weight': newWt};
    }

    // Height/Weight (canonical cm/kg)
    final initialHeightCm = (_initial['height_cm'] as num?)?.toDouble();
    final initialWeightKg = (_initial['weight_kg'] as num?)?.toDouble();

    final hCm = _heightToCm();
    if (hCm != null) {
      if (initialHeightCm == null || !_nearlyEqual(hCm, initialHeightCm)) {
        patch['height_cm'] = double.parse(hCm.toStringAsFixed(2));
      }
    }

    final wKg = _weightToKg();
    if (wKg != null) {
      if (initialWeightKg == null || !_nearlyEqual(wKg, initialWeightKg)) {
        patch['weight_kg'] = double.parse(wKg.toStringAsFixed(2));
      }
    }

    // Avatar (only include if valid http(s) and changed)
    final initialPhoto = (_initial['photo_url'] as String?) ?? '';
    if (_isHttpUrl(_avatarUrl) && _avatarUrl != initialPhoto) {
      patch['photo_url'] = _avatarUrl;
    }

    // Always include updated_at if there are any changes
    if (patch.isNotEmpty) {
      patch['updated_at'] = FieldValue.serverTimestamp();
    }

    // DEBUG: See exactly what we send
    debugPrint('Profile update patch → $patch');

    return patch;
  }

  // ---------- Save ----------
  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct highlighted fields.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final patch = _buildProfilePatch();

      if (patch.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to save')),
        );
        setState(() => _saving = false);
        return;
      }

      // Minimal, merge-safe update. Keeps all other fields from onboarding.
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .update(patch);

      // Keep local initial copy in sync so subsequent edits compute correctly
      _initial = {..._initial, ...patch};
      if (patch.containsKey('dob')) {
        _initial['dob'] = patch['dob'];
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).maybePop(); // close page on save
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
      appBar: AppBar(title: const Text('Update Profile Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(_kPad, _kPad, _kPad, 120),
          children: [
            _IntroCard(),
            const SizedBox(height: 12),

            // AVATAR
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
                      onChanged: (d) => setState(() => _dob = d),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Used to personalize ranges.',
                      style: text.bodySmall?.copyWith(color: _kTextSecondary),
                    ),
                    if (_dob != null && !_ageIsValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'You must be at least 13.',
                          style: text.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text('Gender', style: text.labelLarge),
                    const SizedBox(height: 6),
                    _GenderPicker(
                      value: _gender,
                      onChanged: (g) => setState(() => _gender = g),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Helps us set appropriate reference ranges.',
                      style: text.bodySmall?.copyWith(color: _kTextSecondary),
                    ),
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
                          onChanged: (u) => setState(() {
                            final cm = _heightToCm();
                            _lenUnit = u;
                            if (cm != null) {
                              final disp = (_lenUnit == LengthUnit.cm) ? cm : cm / 2.54;
                              _heightCtrl.text = _trimNum(disp);
                            }
                          }),
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
                          onChanged: (u) => setState(() {
                            final kg = _weightToKg();
                            _wtUnit = u;
                            if (kg != null) {
                              final disp = (_wtUnit == WeightUnit.kg) ? kg : kg / 0.45359237;
                              _weightCtrl.text = _trimNum(disp);
                            }
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: text.bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
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
            if (!_ageIsValid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'You must be at least 13.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: _kTextSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            // Full-width primary button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52), // taller + full-width
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
          ],
        ),
      ),
    );
  }
}

// ---------- Sub-widgets (copied to match onboarding layout) ----------
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
            // Removed any "edit later in Profile" phrasing.
            Text(
              'We use these to personalize your ranges and convert units across devices.',
              style: text.bodyMedium?.copyWith(color: _kTextSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              // Direct push to avoid route table or nested Navigator issues
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPage(),
                  settings: const RouteSettings(name: RoutePaths.aboutPrivacy),
                ),
              ),
              child: const Text('How we use your data'),
            ),
          ],
        ),
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
            // Removed "You can change this later in Profile."
            'Add a photo (optional).',
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
              : '${value!.year.toString().padLeft(4, '0')}-'
              '${value!.month.toString().padLeft(2, '0')}-'
              '${value!.day.toString().padLeft(2, '0')}',
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
        value: Gender.preferNotSay,
        child: Text('Prefer not to say'),
      ),
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
            color: selected ? _kPrimary : Theme.of(context).colorScheme.onSurface,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
