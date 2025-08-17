import 'package:flutter/material.dart';

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool terms=false, privacy=false, dataUse=false;

  @override
  Widget build(BuildContext context) {
    final all = terms && privacy && dataUse;
    return Scaffold(
      appBar: AppBar(title: const Text('Consent')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(value: terms, onChanged: (v)=> setState(()=> terms=v??false), title: const Text('I agree to the Terms of Service')),
            CheckboxListTile(value: privacy, onChanged: (v)=> setState(()=> privacy=v??false), title: const Text('I agree to the Privacy Policy')),
            CheckboxListTile(value: dataUse, onChanged: (v)=> setState(()=> dataUse=v??false), title: const Text('I consent to data usage for features')),
            const Spacer(),
            Row(children: [
              TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Back')),
              const Spacer(),
              FilledButton(onPressed: all? ()=> Navigator.pushNamed(context, '/onboarding/connect') : null, child: const Text('Next')),
            ])
          ],
        ),
      ),
    );
  }
}
