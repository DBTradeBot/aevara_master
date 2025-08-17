import 'package:flutter/material.dart';
class NumberStepperField extends StatefulWidget{
  final String label; final double value; final double min; final double max; final double step; final String unit;
  final void Function(double) onChanged;
  const NumberStepperField({super.key, required this.label, required this.value, required this.min, required this.max, required this.step, required this.unit, required this.onChanged});
  @override State<NumberStepperField> createState()=>_NumberStepperFieldState();
}
class _NumberStepperFieldState extends State<NumberStepperField>{
  late TextEditingController _c;
  @override void initState(){ super.initState(); _c = TextEditingController(text: widget.value.toStringAsFixed(0)); }
  @override void didUpdateWidget(covariant NumberStepperField old){ super.didUpdateWidget(old); if(old.value!=widget.value) _c.text = widget.value.toStringAsFixed(0); }
  void _delta(double d){ final v = (double.tryParse(_c.text) ?? widget.min) + d; final clamped = v.clamp(widget.min, widget.max); _c.text = clamped.toStringAsFixed(0); widget.onChanged(clamped); }
  @override Widget build(BuildContext c)=>Row(children:[
    Expanded(child: TextField(controller:_c, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: widget.label, suffixText: widget.unit), onChanged:(s){ final v=double.tryParse(s); if(v!=null) widget.onChanged(v.clamp(widget.min, widget.max)); })),
    const SizedBox(width:8),
    IconButton.filledTonal(onPressed: ()=>_delta(-widget.step), icon: const Icon(Icons.remove)),
    const SizedBox(width:4),
    IconButton.filled(onPressed: ()=>_delta(widget.step), icon: const Icon(Icons.add)),
  ]);
}
