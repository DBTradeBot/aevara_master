// lib/features/onboarding/demographics_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../routing/route_paths.dart';
import '../../data/adapters/firestore/user_profile_service_fs.dart';
import '../../data/services/user_profile_service.dart';
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
  late final UserProfileService _profiles =
  UserProfileServiceFs(FirebaseFirestore.instance);

  // Auth
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

  void _toggleLenUnit(LengthUnit u) {
    if (_lenUnit == u) return;
    final current = _toDouble(_heightCtrl);
    setState(() {
      if (_lenUnit == LengthUnit.cm && u == LengthUnit.inch && current != null) {
        _heightCtrl.text = (current / 2.54).toStringAsFixed(1);
      } else if (_lenUnit == LengthUnit.inch && u == LengthUnit.cm && current != null) {
        _heightCtrl.text = (current * 2.54).toStringAsFixed(1);
      }
      _lenUnit = u;
    });
  }

  void _toggleWtUnit(WeightUnit u) {
    if (_wtUnit == u) return;
    final current = _toDouble(_weightCtrl);
    setState(() {
      if (_wtUnit == WeightUnit.kg && u == WeightUnit.lb && current != null) {
        _weightCtrl.text = (current / 0.45359237).toStringAsFixed(1);
      } else if (_wtUnit == WeightUnit.lb && u == WeightUnit.kg && current != null) {
        _weightCtrl.text = (current * 0.45359237).toStringAsFixed(1);
      }
      _wtUnit = u;
    });
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
  bool get _hasMetric =>
      _heightCtrl.text.trim().isNotEmpty || _weightCtrl.text.trim().isNotEmpty;

  bool get _minComplete => _dob != null && _gender != null && _hasMetric && _meetsAge;

  // ---------- Save ----------
  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _error = 'Not signed in.');
      return;
    }
    if (!_minComplete) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final heightCm = _heightToCm();
      final weightKg = _weightToKg();

      await _profiles.createOrUpdatePartial(uid: user.uid, data: {
        // Stamp identity
        'uid': user.uid,
        'email': user.email ?? '',
        // Core fields
        'first_name': _firstCtrl.text.trim().isEmpty ? null : _firstCtrl.text.trim(),
        'last_name': _lastCtrl.text.trim().isEmpty ? null : _lastCtrl.text.trim(),
        if (_dob != null) 'dob': _dob!.toIso8601String(),
        if (_gender != null) 'gender': _gender!.name,
        'preferred_units': {
          'length': _lenUnit.name,
          'weight': _wtUnit.name,
        },
        if (heightCm != null) 'height_cm': double.parse(heightCm.toStringAsFixed(2)),
        if (weightKg != null) 'weight_kg': double.parse(weightKg.toStringAsFixed(2)),
        // Audit
        'updated_at': FieldValue.serverTimestamp(),
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
                    _DobField(value: _dob, onChanged: (d) => setState(() => _dob = d)),
                    const SizedBox(height: 4),
                    Text('Used to personalize ranges.',
                        style: text.bodySmall?.copyWith(color: _kTextSecondary)),
                    if (_dob != null && !_meetsAge)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('You must be at least 13.',
                            style: text.bodySmall?.copyWith(color: theme.colorScheme.error)),
                      ),
                    const SizedBox(height: 16),

                    Text('Gender', style: text.labelLarge),
                    const SizedBox(height: 6),
                    _GenderPicker(value: _gender, onChanged: (g) => setState(() => _gender = g)),
                    const SizedBox(height: 4),
                    Text('Helps us set appropriate reference ranges.',
                        style: text.bodySmall?.copyWith(color: _kTextSecondary)),
                    const SizedBox(height: 16),

                    Text('Height', style: text.labelLarge),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _heightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: 'Enter height',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _UnitChips<LengthUnit>(
                          options: {LengthUnit.cm: 'cm', LengthUnit.inch: 'in'},
                          value: _lenUnit,
                          onChanged: _toggleLenUnit,
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
                            decoration: const InputDecoration(
                              hintText: 'Enter weight',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _UnitChips<WeightUnit>(
                          options: {WeightUnit.kg: 'kg', WeightUnit.lb: 'lb'},
                          value: _wtUnit,
                          onChanged: _toggleWtUnit,
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
                  style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
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
                      : (!_hasMetric
                      ? 'Enter height or weight to continue.'
                      : (!_meetsAge ? 'You must be at least 13.' : '')),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: _kTextSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: (!_saving && _minComplete) ? _save : null,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
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
              // Opens the in-app explainer page
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
    final items = [
      DropdownMenuItem(value: Gender.male, child: const Text('Male')),
      DropdownMenuItem(value: Gender.female, child: const Text('Female')),
      DropdownMenuItem(value: Gender.nonbinary, child: const Text('Non-binary')),
      DropdownMenuItem(value: Gender.preferNotSay, child: const Text('Prefer not to say')),
      DropdownMenuItem(value: Gender.other, child: const Text('Other')),
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
