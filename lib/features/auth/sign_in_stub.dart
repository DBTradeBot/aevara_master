import 'package:flutter/material.dart';

class SignInStub extends StatelessWidget {
  const SignInStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/app/home'),
                  child: const Text('Sign in'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/app/home'),
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continue with Google (stub)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
