// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext c) => Row(children: [
        Expanded(
            child: Text(title,
                style: Theme.of(c)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.w600))),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!))
      ]);
}

