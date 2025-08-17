import 'package:flutter/material.dart'; import '../../core/atoms/avatar.dart';
class FriendProfilePage extends StatelessWidget{ const FriendProfilePage({super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Friend Profile')), body: ListView(padding: const EdgeInsets.all(16), children:[
    const Center(child: Avatar(size:72)), const SizedBox(height:8), const Center(child: Text('@friend_handle')),
    const ListTile(title: Text('Public stats'), subtitle: Text('Steps, Sleep, HRV (placeholder)')),
    FilledButton(onPressed: (){}, child: const Text('Send Cheer')),
  ]));
}
