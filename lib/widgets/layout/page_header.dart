import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const PageHeader({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}
