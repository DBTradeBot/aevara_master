import 'package:flutter/material.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Aevara')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your AI-powered longevity companion.',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
                'Track recovery, sleep, activity, and wellbeing with clarity and transparency.'),
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/onboarding/identity'),
                    child: const Text('Next')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
