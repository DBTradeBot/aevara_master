import 'package:flutter/material.dart';
class AeListSectionHeader extends StatelessWidget{
  final String title; final String? actionLabel; final VoidCallback? onAction;
  const AeListSectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  @override Widget build(BuildContext c)=>Row(children:[
    Expanded(child: Text(title, style: Theme.of(c).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700))),
    if(actionLabel!=null) TextButton(onPressed: onAction, child: Text(actionLabel!))
  ]);
}
