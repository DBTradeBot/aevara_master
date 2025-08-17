import 'package:flutter/material.dart';
import 'provider_card.dart';
class ProviderRow extends StatelessWidget{
  const ProviderRow({super.key});
  @override Widget build(BuildContext c)=>SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children:[
      SizedBox(width: 8),
      const SizedBox(width: 220, child: ProviderCard(name:'Apple Health', status:'Connected', icon: Icons.watch)),
      const SizedBox(width: 12),
      const SizedBox(width: 220, child: ProviderCard(name:'Fitbit', status:'Connected', icon: Icons.directions_walk)),
      const SizedBox(width: 12),
      const SizedBox(width: 220, child: ProviderCard(name:'Garmin', status:'Not connected', icon: Icons.sports_score)),
      const SizedBox(width: 12),
      const SizedBox(width: 220, child: ProviderCard(name:'WHOOP', status:'Not connected', icon: Icons.bolt_outlined)),
      const SizedBox(width: 12),
      const SizedBox(width: 220, child: ProviderCard(name:'Oura', status:'Connected', icon: Icons.nightlight_round)),
      const SizedBox(width: 8),
    ]),
  );
}
