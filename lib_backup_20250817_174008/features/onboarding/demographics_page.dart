import 'package:flutter/material.dart';
import '../../widgets/atoms/aev_text_field.dart';

class DemographicsPage extends StatefulWidget {
  const DemographicsPage({super.key});

  @override
  State<DemographicsPage> createState() => _DemographicsPageState();
}

class _DemographicsPageState extends State<DemographicsPage> {
  String gender = 'Prefer not to say';
  final _height = TextEditingController();
  final _weight = TextEditingController();

  String heightUnit = 'cm';
  String weightUnit = 'kg';

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demographics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Gender', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in const [
                  'Female',
                  'Male',
                  'Non-binary',
                  'Prefer not to say',
                  'Other'
                ])
                  ChoiceChip(
                    label: Text(g),
                    selected: gender == g,
                    onSelected: (_) => setState(() => gender = g),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Height
            Row(
              children: [
                Expanded(
                  child: AevTextField(
                    controller: _height,
                    label: 'Height ($heightUnit)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'cm', label: Text('cm')),
                    ButtonSegment(value: 'in', label: Text('in')),
                  ],
                  selected: {heightUnit},
                  onSelectionChanged: (s) =>
                      setState(() => heightUnit = s.first),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Weight
            Row(
              children: [
                Expanded(
                  child: AevTextField(
                    controller: _weight,
                    label: 'Weight ($weightUnit)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'kg', label: Text('kg')),
                    ButtonSegment(value: 'lb', label: Text('lb')),
                  ],
                  selected: {weightUnit},
                  onSelectionChanged: (s) =>
                      setState(() => weightUnit = s.first),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nav actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/onboarding/username'),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
