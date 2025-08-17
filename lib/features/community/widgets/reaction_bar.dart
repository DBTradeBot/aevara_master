import 'package:flutter/material.dart';
class ReactionBar extends StatelessWidget{
  final VoidCallback? onCheer; final VoidCallback? onComment; final VoidCallback? onShare;
  const ReactionBar({super.key, this.onCheer, this.onComment, this.onShare});
  @override Widget build(BuildContext c){
    return Row(mainAxisAlignment: MainAxisAlignment.end, children:[
      IconButton(onPressed:onCheer, icon: const Icon(Icons.emoji_emotions_outlined), tooltip:'Cheer'),
      IconButton(onPressed:onComment, icon: const Icon(Icons.chat_bubble_outline), tooltip:'Comment'),
      IconButton(onPressed:onShare, icon: const Icon(Icons.ios_share), tooltip:'Share'),
    ]);
  }
}
