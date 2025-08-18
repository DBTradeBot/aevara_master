// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../../navigation/routes.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Create account (1/4)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
            controller: name,
            decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(
            controller: email,
            decoration: const InputDecoration(
                labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
        const SizedBox(height: 12),
        TextField(
            controller: pass,
            decoration: const InputDecoration(
                labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
            obscureText: true),
        const SizedBox(height: 12),
        TextField(
            controller: confirm,
            decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_outline)),
            obscureText: true),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: () => Navigator.pushNamed(c, Routes.obBasics),
            child: const Text('Next: Basics')),
      ]));
}

