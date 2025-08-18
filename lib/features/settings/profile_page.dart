import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController(text: 'Your Name');
  final _username = TextEditingController(text: 'username');
  String gender = 'Prefer not to say';
  String heightUnit = 'cm';
  String weightUnit = 'kg';
  final _height = TextEditingController(text: '178');
  final _weight = TextEditingController(text: '74');

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixText: '@',
              ),
            ),
            const SizedBox(height: 12),

            // Gender
            Text('Gender', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
                  )
              ],
            ),
            const SizedBox(height: 16),

            // Height + unit
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Height ($heightUnit)',
                      border: const OutlineInputBorder(),
                    ),
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

            // Weight + unit
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Weight ($weightUnit)',
                      border: const OutlineInputBorder(),
                    ),
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
            const SizedBox(height: 16),

            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile saved (stub)')),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
}
