import 'package:flutter/material.dart';
class AeProgressRing extends StatelessWidget{
  final double value; final String label;
  const AeProgressRing({super.key, required this.value, required this.label});
  @override Widget build(BuildContext c)=>Column(mainAxisSize: MainAxisSize.min, children:[
    SizedBox(height:86, width:86, child: Stack(alignment: Alignment.center, children:[
      CircularProgressIndicator(value:value, strokeWidth:10),
      Text('${(value*100).round()}%')
    ])),
    const SizedBox(height:6),
    Text(label)
  ]);
}
