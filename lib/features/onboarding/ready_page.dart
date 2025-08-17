import 'package:flutter/material.dart';

class ReadyPage extends StatelessWidget {
  const ReadyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                "You're all set!",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                "Next up: your dashboard (placeholder) and data/experiments/community.",
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/app/home'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
