// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Terms placeholder text in sections.')));
}

