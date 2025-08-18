// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../navigation/routes.dart';

class OnboardingReadyPage extends StatelessWidget {
  const OnboardingReadyPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      body: Center(
          child: FilledButton(
              onPressed: () => Navigator.pushReplacementNamed(c, Routes.home),
              child: const Text('Go to Dashboard'))));
}
