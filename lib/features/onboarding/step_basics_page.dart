// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../core/widgets/number_stepper_field.dart';
import '../../navigation/routes.dart';

class OnboardingBasicsPage extends StatefulWidget {
  const OnboardingBasicsPage({super.key});
  @override
  State<OnboardingBasicsPage> createState() => _OnboardingBasicsPageState();
}

class _OnboardingBasicsPageState extends State<OnboardingBasicsPage> {
  DateTime? dob;
  String gender = 'Prefer not to say';
  String units = 'Metric';
  double height = 170;
  double weight = 70;
  Future<void> pickDOB() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: now,
        initialDate: DateTime(now.year - 25));
    if (picked != null) setState(() => dob = picked);
  }

  void _switchUnits(String next) {
    setState(() {
      if (units != next) {
        if (next == 'Imperial') {
          height /= 2.54;
          weight *= 2.20462;
        } else {
          height *= 2.54;
          weight /= 2.20462;
        }
      }
      units = next;
      final hMin = units == 'Metric' ? 120.0 : 47.0,
          hMax = units == 'Metric' ? 220.0 : 86.0;
      final wMin = units == 'Metric' ? 40.0 : 88.0,
          wMax = units == 'Metric' ? 160.0 : 352.0;
      height = height.clamp(hMin, hMax);
      weight = weight.clamp(wMin, wMax);
    });
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Basics (2/4)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(
            title: const Text('Date of Birth'),
            subtitle: Text(dob != null
                ? dob!.toIso8601String().split('T').first
                : 'Select date'),
            trailing: const Icon(Icons.calendar_today),
            onTap: pickDOB),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
            value: gender,
            items: const ['Female', 'Male', 'Non-binary', 'Prefer not to say']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => gender = v ?? gender),
            decoration: const InputDecoration(
                labelText: 'Gender', prefixIcon: Icon(Icons.wc))),
        const SizedBox(height: 8),
        SegmentedButton<String>(segments: const [
          ButtonSegment(value: 'Metric', label: Text('Metric')),
          ButtonSegment(value: 'Imperial', label: Text('Imperial'))
        ], selected: {
          units
        }, onSelectionChanged: (s) => _switchUnits(s.first)),
        const SizedBox(height: 8),
        NumberStepperField(
            label: 'Height',
            value: height,
            min: units == 'Metric' ? 120 : 47,
            max: units == 'Metric' ? 220 : 86,
            step: 1,
            unit: units == 'Metric' ? 'cm' : 'in',
            onChanged: (v) => setState(() => height = v)),
        const SizedBox(height: 8),
        NumberStepperField(
            label: 'Weight',
            value: weight,
            min: units == 'Metric' ? 40 : 88,
            max: units == 'Metric' ? 160 : 352,
            step: 1,
            unit: units == 'Metric' ? 'kg' : 'lb',
            onChanged: (v) => setState(() => weight = v)),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: () => Navigator.pushNamed(c, Routes.obGoals),
            child: const Text('Next: Goals')),
      ]));
}

