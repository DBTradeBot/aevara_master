// lib/features/onboarding/profile_setup_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aevara_app/data/adapters/firestore/user_profile_service_fs.dart';
import 'package:aevara_app/data/services/user_profile_service.dart';
import 'package:aevara_app/data/models/user_profile.dart';


// Visual tokens (fallbacks if your theme isn't hooked yet)
const _kPad = 16.0;
const _kRadius = 16.0;
const _kPrimary = Color(0xFF3F87A6); // Calm Azure
const _kTextSecondary = Color(0xFF575C6C);

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  // Services
  late final UserProfileService _profiles =
  UserProfileServiceFs(FirebaseFirestore.instance);

  // Auth
  User? get _user => FirebaseAuth.instance.currentUser;

  // Controllers & state
  DateTime? _dob;
  Gender? _gender;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  LengthUnit _lenUnit = LengthUnit.cm;
  WeightUnit _wtUnit = WeightUnit.kg;

  bool _showOptional = false;
  bool _showOnBoards = false;
  bool _receiveEmails = false;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ---------- Unit conversion helpers ----------
  double? _toDouble(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  double? _convertHeightToCm() {
    final v = _toDouble(_heightCtrl);
    if (v == null) return null;
    if (_lenUnit == LengthUnit.cm) return v;
    // inches -> cm
    return v * 2.54;
  }

  double? _convertWeightToKg() {
    final v = _toDouble(_weightCtrl);
    if (v == null) return null;
    if (_wtUnit == WeightUnit.kg) return v;
    // lb -> kg
    return v * 0.45359237;
  }

  void _toggleLenUnit(LengthUnit u) {
    if (_lenUnit == u) return;
    final current = _toDouble(_heightCtrl);
    setState(() {
      if (_lenUnit == LengthUnit.cm && u == LengthUnit.inch && current != null) {
        // cm -> in
        _heightCtrl.text = (current / 2.54).toStringAsFixed(1);
      } else if (_lenUnit == LengthUnit.inch && u == LengthUnit.cm && current != null) {
        // in -> cm
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
        // kg -> lb
        _weightCtrl.text = (current / 0.45359237).toStringAsFixed(1);
      } else if (_wtUnit == WeightUnit.lb && u == WeightUnit.kg && current != null) {
        // lb -> kg
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
    final hadBirthday = (now.month > d.month) ||
        (now.month == d.month && now.day >= d.day);
    if (!hadBirthday) years -= 1;
    return years;
  }

  bool get _meetsAge {
    final age = _ageYears(_dob);
    if (age == null) return false;
    return age >= 13;
  }

  bool get _hasBodyMetric => _heightCtrl.text.trim().isNotEmpty || _weightCtrl.text.trim().isNotEmpty;

  bool get _minComplete => _dob != null && _gender != null && _hasBodyMetric && _meetsAge;

  // ---------- Save ----------
  Future<void> _save() async {
    if (!_minComplete) return;
    if (_user == null) {
      setState(() => _error = 'Not signed in.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final heightCm = _convertHeightToCm();
      final weightKg = _convertWeightToKg();

      await _profiles.createOrUpdatePartial(
        uid: _user!.uid,
        data: {
          if (_dob != null) 'dob': _dob!.toIso8601String(),
          if (_gender != null) 'gender': _gender!.name,
          'preferred_units': {
            'length': _lenUnit.name,
            'weight': _wtUnit.name,
          },
          if (heightCm != null) 'height_cm': double.parse(heightCm.toStringAsFixed(2)),
          if (weightKg != null) 'weight_kg': double.parse(weightKg.toStringAsFixed(2)),
          'sharing': {
            'show_on_leaderboards': _showOnBoards,
            'receive_product_emails': _receiveEmails,
          },
        },
      );

      if (!mounted) return;
      // Navigate to device connect step (adjust route name if different in your router)
      Navigator.of(context).pushReplacementNamed('/onboarding/connect');
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
      appBar: AppBar(
        title: const Text('Profile setup'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(_kPad),
          children: [
            _IntroCard(),
            const SizedBox(height: 12),

            // Basics Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
              elevation: 0,
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(_kPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basics', style: text.titleMedium),
                    const SizedBox(height: 12),

                    // DOB
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
                    if (_dob != null && !_meetsAge)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'You must be at least 13.',
                          style: text.bodySmall?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Gender
                    Text('Gender', style: text.labelLarge),
                    const SizedBox(height: 6),
                    _GenderPicker(
                      value: _gender,
                      onChanged: (g) => setState(() => _gender = g),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lets us set appropriate reference ranges.',
                      style: text.bodySmall?.copyWith(color: _kTextSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Height
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
                          options: const {
                            LengthUnit.cm: 'cm',
                            LengthUnit.inch: 'in',
                          },
                          value: _lenUnit,
                          onChanged: (u) => _toggleLenUnit(u),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weight
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
                          options: const {
                            WeightUnit.kg: 'kg',
                            WeightUnit.lb: 'lb',
                          },
                          value: _wtUnit,
                          onChanged: (u) => _toggleWtUnit(u),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Optional prefs
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(_kPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showOptional = !_showOptional),
                      child: Row(
                        children: [
                          Expanded(child: Text('Optional preferences', style: text.titleMedium)),
                          Icon(_showOptional ? Icons.expand_less : Icons.expand_more),
                        ],
                      ),
                    ),
                    if (_showOptional) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _showOnBoards,
                        onChanged: (v) => setState(() => _showOnBoards = v ?? false),
                        title: const Text('Show handle on public leaderboards'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: _receiveEmails,
                        onChanged: (v) => setState(() => _receiveEmails = v ?? false),
                        title: const Text('Receive important product emails'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can change these anytime in Profile → Privacy.',
                        style: text.bodySmall?.copyWith(color: _kTextSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!_saving && _minComplete) ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Text('Continue'),
              ),
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
              onPressed: () => Navigator.of(context).pushNamed('/about/privacy'),
              child: const Text('Learn about privacy'),
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
