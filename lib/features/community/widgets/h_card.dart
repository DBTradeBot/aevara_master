import 'package:flutter/material.dart';

class HCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const HCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      ),
    );
  }
}
