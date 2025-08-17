import 'package:flutter/material.dart';

class ReactionBar extends StatelessWidget {
  final void Function(String)? onReact;
  const ReactionBar({super.key, this.onReact});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,           // <-- critical for ListTile.trailing
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Text('ðŸ‘', style: TextStyle(fontSize: 18)),
          onPressed: () => onReact?.call('clap'),
          tooltip: 'Clap',
        ),
        IconButton(
          icon: const Text('ðŸ”¥', style: TextStyle(fontSize: 18)),
          onPressed: () => onReact?.call('fire'),
          tooltip: 'Fire',
        ),
        IconButton(
          icon: const Text('ðŸ’¯', style: TextStyle(fontSize: 18)),
          onPressed: () => onReact?.call('hundred'),
          tooltip: '100',
        ),
      ],
    );
  }
}
