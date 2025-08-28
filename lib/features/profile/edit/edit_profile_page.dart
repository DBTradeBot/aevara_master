import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/adapters/firestore/user_profile_service_fs.dart';

const _kPad = 16.0;
const _kRadius = 16.0;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _svc = UserProfileServiceFs(FirebaseFirestore.instance);
  final _auth = FirebaseAuth.instance;

  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  DateTime? _dob;
  String? _gender; // male|female|nonbinary|preferNotSay|other
  String _lenUnit = 'cm';
  String _wtUnit  = 'kg';

  String? _avatarUrl;
  bool _uploadingAvatar = false;
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

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1024, imageQuality: 88);
      if (picked == null) return;
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
        final task = await ref.putFile(File(file.path),
            SettableMetadata(contentType: 'image/jpeg'));
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

  double? _toDouble(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  double? _heightToCm() {
    final v = _toDouble(_heightCtrl);
    if (v == null) return null;
    return _lenUnit == 'cm' ? v : v * 2.54;
  }

  double? _weightToKg() {
    final v = _toDouble(_weightCtrl);
    if (v == null) return null;
    return _wtUnit == 'kg' ? v : v * 0.45359237;
  }

  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() { _saving = true; _error = null; });
    try {
      final heightCm = _heightToCm();
      final weightKg = _weightToKg();

      await _svc.createOrUpdatePartial(uid: user.uid, data: {
        'uid': user.uid,
        'email': user.email ?? '',
        'first_name': _firstCtrl.text.trim().isEmpty ? null : _firstCtrl.text.trim(),
        'last_name':  _lastCtrl.text.trim().isEmpty  ? null : _lastCtrl.text.trim(),
        if (_dob != null) 'dob': _dob!.toIso8601String(),
        if (_gender != null) 'gender': _gender,
        'preferred_units': { 'length': _lenUnit, 'weight': _wtUnit },
        if (heightCm != null) 'height_cm': double.parse(heightCm.toStringAsFixed(2)),
        if (weightKg != null) 'weight_kg': double.parse(weightKg.toStringAsFixed(2)),
        if (_avatarUrl != null && _avatarUrl!.isNotEmpty) 'photo_url': _avatarUrl,
        // IMPORTANT: do NOT send created_at on update
        'updated_at': FieldValue.serverTimestamp(),
      });

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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(_kPad, _kPad, _kPad, 120),
          children: [
            // Avatar
            Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      backgroundImage:
                      (_avatarUrl != null && _avatarUrl!.isNotEmpty) ? NetworkImage(_avatarUrl!) : null,
                      child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                          ? Icon(Icons.person, size: 40,
                          color: Theme.of(context).colorScheme.onSecondaryContainer)
                          : null,
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: InkWell(
                        onTap: _uploadingAvatar ? null : _pickAvatar,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: _uploadingAvatar
                              ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
            ),

            const SizedBox(height: 16),
            // Names
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
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
                      decoration: const InputDecoration(hintText: 'First name'),
                    ),
                    const SizedBox(height: 12),
                    Text('Last name', style: text.labelLarge),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _lastCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Last name'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            // Basics
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
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
                    const SizedBox(height: 16),
                    Text('Gender', style: text.labelLarge),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'nonbinary', child: Text('Non-binary')),
                        DropdownMenuItem(value: 'preferNotSay', child: Text('Prefer not to say')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (g) => setState(() => _gender = g),
                      isDense: true,
                      decoration: const InputDecoration(hintText: 'Select'),
                    ),
                    const SizedBox(height: 16),
                    Text('Height', style: text.labelLarge),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _heightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: 'Enter height'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('cm'),
                              selected: _lenUnit == 'cm',
                              onSelected: (_) => setState(() => _lenUnit = 'cm'),
                            ),
                            ChoiceChip(
                              label: const Text('in'),
                              selected: _lenUnit == 'inch',
                              onSelected: (_) => setState(() => _lenUnit = 'inch'),
                            ),
                          ],
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: 'Enter weight'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('kg'),
                              selected: _wtUnit == 'kg',
                              onSelected: (_) => setState(() => _wtUnit = 'kg'),
                            ),
                            ChoiceChip(
                              label: const Text('lb'),
                              selected: _wtUnit == 'lb',
                              onSelected: (_) => setState(() => _wtUnit = 'lb'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Cancel'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DobField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const _DobField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final initial = value ?? DateTime(now.year - 25, now.month, now.day);
    return InkWell(
      onTap: () async {
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
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value == null
              ? 'Select date'
              : '${value!.year.toString().padLeft(4, '0')}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
