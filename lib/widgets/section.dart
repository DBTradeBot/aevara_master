
import 'package:flutter/material.dart';

class Section extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onSeeAll;
  final String? actionLabel;

  const Section({
    super.key,
    required this.title,
    required this.child,
    this.onSeeAll,
    this.actionLabel,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(actionLabel ?? 'See all'),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
