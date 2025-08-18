// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class NumberStepper extends StatefulWidget {
  final String label;
  final num initial;
  final num step;
  final ValueChanged<num>? onChanged;
  const NumberStepper(
      {super.key,
      required this.label,
      this.initial = 0,
      this.step = 1,
      this.onChanged});
  @override
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  num v = 0;
  @override
  void initState() {
    v = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext c) => Row(children: [
        Text(widget.label),
        const Spacer(),
        IconButton(
            onPressed: () {
              setState(() => v -= widget.step);
              widget.onChanged?.call(v);
            },
            icon: const Icon(Icons.remove)),
        Text('$v'),
        IconButton(
            onPressed: () {
              setState(() => v += widget.step);
              widget.onChanged?.call(v);
            },
            icon: const Icon(Icons.add)),
      ]);
}
