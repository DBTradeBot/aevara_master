import 'package:flutter/material.dart';

class AevButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final Widget? leading;
  const AevButton.primary(this.label, {super.key, this.onPressed, this.leading})
      : primary = true;
  const AevButton.secondary(this.label,
      {super.key, this.onPressed, this.leading})
      : primary = false;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Text(label),
      ],
    )
    return primary
        ? ElevatedButton(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
  }
}


