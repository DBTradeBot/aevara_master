import 'package:flutter/material.dart';

class ConsentsPage extends StatefulWidget {
  const ConsentsPage({super.key});

  @override
  State<ConsentsPage> createState() => _ConsentsPageState();
}

class _ConsentsPageState extends State<ConsentsPage> {
  bool terms = true, privacy = true, dataUse = true, research = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Consents')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CheckboxListTile(
          value: terms,
          onChanged: (v) => setState(() => terms = v ?? false),
          title: const Text('Terms of Service'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: privacy,
          onChanged: (v) => setState(() => privacy = v ?? false),
          title: const Text('Privacy Policy'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: dataUse,
          onChanged: (v) => setState(() => dataUse = v ?? false),
          title: const Text('Use of data for features'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: research,
          onChanged: (v) => setState(() => research = v ?? false),
          title: const Text('Optional: anonymized research data'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Consents updated (stub)')),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
