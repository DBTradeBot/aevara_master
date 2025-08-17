import 'package:flutter/material.dart';
class FreshnessChip extends StatelessWidget{
  final String freshness; // 'green','yellow','red'
  const FreshnessChip({super.key, required this.freshness});
  @override Widget build(BuildContext c){
    String label = 'Fresh'; Color col = Colors.green;
    if(freshness=='yellow'){ label='Stale'; col=Colors.orange; }
    if(freshness=='red'){ label='Old'; col=Colors.red; }
    return Chip(label: Text(label), avatar: Icon(Icons.circle, size:12, color: col), visualDensity: VisualDensity.compact);
  }
}
