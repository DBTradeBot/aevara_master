import 'package:flutter/material.dart';
import '../../widgets/layout/auth_scaffold.dart';
import '../../widgets/atoms/aev_text_field.dart';
import '../../widgets/atoms/aev_button.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
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
                Row(
                  children: [
                    const Icon(Icons.favorite_outline, size: 24),
                    const SizedBox(width: 8),
                    Text('brand.ai',
                        style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('LetÃ¢â‚¬â„¢s get started by filling out the form below.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                AevTextField(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outlined),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your email' : null,
                ),
                const SizedBox(height: 12),
                AevTextField(
                  controller: _password,
                  label: 'Password',
                  obscure: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                const SizedBox(height: 16),
                AevButton.primary(_loading ? 'Signing in...' : 'Sign in',
                    onPressed: _loading
                        ? null
                        : () async {
if (!_formKey.currentState!.validate() { ) return; }
                            setState(() => _loading = true);
                            await Future.delayed(
                                const Duration(milliseconds: 500));
                            if (mounted) {
                              Navigator.of(context)
                                  .pushReplacementNamed('/onboarding/intro');
                            }
                          }),
                const SizedBox(height: 12),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('OR')),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 12),
                AevButton.secondary('Continue with Google',
                    leading: const Icon(Icons.g_mobiledata), onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OAuth stubbed.')));
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/auth/forgot'),
                      child: const Text('Forgot password?'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, '/auth/signup'),
                      child: const Text('Sign Up here'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

