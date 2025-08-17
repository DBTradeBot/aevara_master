import 'package:flutter/material.dart';
class ProviderCard extends StatelessWidget {
  final String name; final String status; final IconData icon;
  const ProviderCard({super.key, required this.name, required this.status, required this.icon});
  @override Widget build(BuildContext c)=>Card(child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children:[
      Row(children:[Icon(icon), const SizedBox(width:8), Text(name, style: Theme.of(c).textTheme.titleMedium)]),
      const SizedBox(height:6),
      Chip(label: Text(status), avatar: const Icon(Icons.check_circle_outline, size: 16))
    ]),
  ));
}
