// lib/features/onboarding/body_metrics_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_profile.dart';
import '../../routing/route_paths.dart';
import '../../state/user_providers.dart';
import '../../core/widgets/dev_fab_navigator.dart';

class BodyMetricsPage extends ConsumerStatefulWidget {
  const BodyMetricsPage({super.key});
  @override
  ConsumerState<BodyMetricsPage> createState() => _BodyMetricsPageState();
}

class _BodyMetricsPageState extends ConsumerState<BodyMetricsPage> {
  final _height = TextEditingController();
  final _weight = TextEditingController();

  LengthUnit _lengthUnit = LengthUnit.cm;
  WeightUnit _weightUnit = WeightUnit.kg;

  bool _loading = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _submit(UserProfile p) async {
    setState(() => _loading = true);
    try {
      double? heightCm;
      if (_height.text.isNotEmpty) {
        final v = double.tryParse(_height.text);
        if (v != null) {
          heightCm = _lengthUnit == LengthUnit.cm ? v : (v * 2.54);
        }
      }

      double? weightKg;
      if (_weight.text.isNotEmpty) {
        final v = double.tryParse(_weight.text);
        if (v != null) {
          weightKg = _weightUnit == WeightUnit.kg ? v : (v * 0.45359237);
        }
      }

      final updated = p.copyWith(
        preferredUnits: UnitsPrefs(length: _lengthUnit, weight: _weightUnit),
        heightCm: heightCm,
        weightKg: weightKg,
        updatedAt: DateTime.now(),
      );
      await ref.read(userProfileWriteProvider).createOrUpdate(updated);
      if (mounted) {
        Navigator.pushNamed(context, RoutePaths.consent);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profAsync = ref.watch(currentUserProfileProvider);
    final profile = profAsync.value;

    return Scaffold(
      floatingActionButton: const DevFabNavigator(),
      appBar: AppBar(title: const Text('Body metrics')),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      hintText: 'e.g. 180',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<LengthUnit>(
                  value: _lengthUnit,
                  onChanged: (u) =>
                      setState(() => _lengthUnit = u ?? _lengthUnit),
                  items: const [
                    DropdownMenuItem(value: LengthUnit.cm, child: Text('cm')),
                    DropdownMenuItem(value: LengthUnit.inch, child: Text('in')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      hintText: 'e.g. 78',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<WeightUnit>(
                  value: _weightUnit,
                  onChanged: (u) =>
                      setState(() => _weightUnit = u ?? _weightUnit),
                  items: const [
                    DropdownMenuItem(value: WeightUnit.kg, child: Text('kg')),
                    DropdownMenuItem(value: WeightUnit.lb, child: Text('lb')),
                  ],
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (profile == null || _loading)
                    ? null
                    : () => _submit(profile),
                child: _loading
                    ? const CircularProgressIndicator.adaptive()
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
