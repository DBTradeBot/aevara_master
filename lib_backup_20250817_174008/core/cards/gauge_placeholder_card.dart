// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class GaugePlaceholderCard extends StatelessWidget {
  final String title;
  const GaugePlaceholderCard({super.key, required this.title});
  @override
  Widget build(BuildContext c) => Card(
      child:
          SizedBox(height: 120, child: Center(child: Text('Gauge: $title'))));
}
