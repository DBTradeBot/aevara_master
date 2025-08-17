import 'package:flutter/material.dart';
class MiniSparkline extends StatelessWidget{
  final List<double> values; const MiniSparkline({super.key, required this.values});
  @override Widget build(BuildContext c)=>SizedBox(height:24, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: values.map((v)=>Expanded(
    child: Padding(padding: const EdgeInsets.symmetric(horizontal:1.2), child: Container(height: (v.clamp(0,1))*24))
  )).toList()));
}
