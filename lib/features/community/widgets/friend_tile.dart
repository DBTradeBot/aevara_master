import 'package:flutter/material.dart';
import '../models.dart';

class FriendTile extends StatelessWidget {
  final Friend f;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  const FriendTile({super.key, required this.f, this.onTap, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text(f.avatarEmoji)),
        title: Text('@${f.handle}'),
        subtitle: f.streak > 0 ? Row(children: [
          const Text('ðŸ”¥ '),
          Text('x${f.streak}', style: const TextStyle(color: Colors.black54)),
        ]) : const Text(''),
        trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: onMore),
      ),
    );
  }
}
