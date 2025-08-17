import 'package:flutter/material.dart';
class ProfileBanner extends StatelessWidget{
  const ProfileBanner({super.key});
  @override Widget build(BuildContext c)=>Row(children:[
    const CircleAvatar(radius: 28, child: Icon(Icons.person)),
    const SizedBox(width:12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text('Aevara User', style: Theme.of(c).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
      Text('@username • Streak 5 • Badges 8', style: Theme.of(c).textTheme.bodySmall)
    ]))
  ]);
}
