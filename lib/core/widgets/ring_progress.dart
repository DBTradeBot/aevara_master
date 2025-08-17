import 'package:flutter/material.dart';
class RingProgress extends StatelessWidget{
  final double value; final String label;
  const RingProgress({super.key, required this.value, required this.label});
  @override Widget build(BuildContext c)=>Column(mainAxisSize: MainAxisSize.min, children:[
    SizedBox(height:76, width:76, child: Stack(alignment: Alignment.center, children:[
      CircularProgressIndicator(value: value, strokeWidth: 8),
      Text('${(value*100).round()}%')
    ])), const SizedBox(height:6), Text(label, style: Theme.of(c).textTheme.labelMedium)
  ]);
}
