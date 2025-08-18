// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class EmojiScale extends StatefulWidget {
  final int initial;
  final ValueChanged<int>? onChanged;
  const EmojiScale({super.key, this.initial = 3, this.onChanged});
  @override
  State<EmojiScale> createState() => _EmojiScaleState();
}

class _EmojiScaleState extends State<EmojiScale> {
  int v = 3;
  @override
  void initState() {
    v = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext c) {
    final items = ['Ã°Å¸ËœÅ¾', 'Ã°Å¸ËœÂ', 'Ã°Å¸â„¢â€š', 'Ã°Å¸ËœÆ’', 'Ã°Å¸Â¤Â©'];
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
            5,
            (i) => GestureDetector(
                onTap: () {
                  setState(() => v = i + 1);
                  widget.onChanged?.call(v);
                },
                child: Text(items[i], style: const TextStyle(fontSize: 24)))));
  }
}

