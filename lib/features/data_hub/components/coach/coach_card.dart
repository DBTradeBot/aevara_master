import 'package:flutter/material.dart';
class CoachCard extends StatelessWidget{
  final VoidCallback onOpen;
  const CoachCard({super.key, required this.onOpen});
  @override Widget build(BuildContext c)=>Card(child: ListTile(
    leading: const Icon(Icons.psychology_outlined),
    title: const Text('How are you feeling?'),
    subtitle: const Text('Log mood, stress, and add a note'),
    trailing: FilledButton(onPressed: onOpen, child: const Text('Log')),
  ));
}
