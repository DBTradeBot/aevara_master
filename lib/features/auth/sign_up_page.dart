import 'package:flutter/material.dart';
import '../../widgets/layout/auth_scaffold.dart';
import '../../widgets/atoms/aev_text_field.dart';
import '../../widgets/atoms/aev_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Account',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                AevTextField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.mail_outlined),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your email' : null),
                const SizedBox(height: 12),
                AevTextField(
                    controller: _password,
                    label: 'Password',
                    obscure: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 chars' : null),
                const SizedBox(height: 12),
                AevTextField(
                    controller: _confirm,
                    label: 'Confirm Password',
                    obscure: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (v) => (v != _password.text)
                        ? 'Passwords do not match'
                        : null),
                const SizedBox(height: 16),
                AevButton.primary(_loading ? 'Creating...' : 'Create account',
                    onPressed: _loading
                        ? null
                        : () async {
<<<<<<< Updated upstream
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _loading = true);
                            await Future.delayed(
                                const Duration(milliseconds: 500));
                            if (mounted)
                              Navigator.pushReplacementNamed(
                                  context, '/auth/verify');
=======
if (!_formKey.currentState!.validate() ) return
                            setState(() => _loading = true);
                            await Future.delayed(
                                const Duration(milliseconds: 500));
if (mounted) Navigator.pushReplacementNamed(
                                  context, '/auth/verify')
>>>>>>> Stashed changes
                          }),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/auth/signin'),
                    child: const Text('Back to sign in')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


