import 'package:flutter/material.dart';

class MyPositionPill extends StatelessWidget {
  final int myIndex;
  final VoidCallback onTap;
  const MyPositionPill({super.key, required this.myIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FloatingActionButton.extended(
          heroTag: 'me_pill',
          onPressed: onTap,
          icon: const Icon(Icons.my_location),
          label: Text('Me â€¢ #${myIndex + 1}'),
        ),
      ),
    );
  }
}
