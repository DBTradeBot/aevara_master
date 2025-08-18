// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../app_routes.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool show = false;
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SizedBox(height: 8),
        TextField(
            controller: email,
            decoration: const InputDecoration(
                labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
        const SizedBox(height: 12),
        TextField(
            controller: pass,
            obscureText: !show,
            decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                    icon: Icon(show ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => show = !show)))),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () => Navigator.pushNamed(c, Routes.forgot),
                child: const Text('Forgot password?'))),
        const SizedBox(height: 8),
        FilledButton(
            onPressed: () => Navigator.pushReplacementNamed(c, Routes.home),
            child: const Text('Sign in')),
        const SizedBox(height: 8),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR')),
          Expanded(child: Divider())
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Continue with Google')),
        OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.apple),
            label: const Text('Continue with Apple')),
        OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.facebook),
            label: const Text('Continue with Facebook')),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('No account?'),
          TextButton(
              onPressed: () => Navigator.pushNamed(c, Routes.signUp),
              child: const Text('Sign up'))
        ]),
      ]));
}
