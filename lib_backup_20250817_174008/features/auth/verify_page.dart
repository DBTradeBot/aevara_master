import 'package:flutter/material.dart';
import '../../widgets/layout/auth_scaffold.dart';
import '../../widgets/atoms/aev_button.dart';

class VerifyPage extends StatelessWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify your email',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                  'We sent a verification link to your email. Open it and come back here.'),
              const SizedBox(height: 16),
              AevButton.primary('I have verified', onPressed: () {
                Navigator.pushReplacementNamed(context, '/onboarding/intro');
              }),
              const SizedBox(height: 8),
              TextButton(onPressed: () {}, child: const Text('Resend email')),
            ],
          ),
        ),
      ),
    );
  }
}
