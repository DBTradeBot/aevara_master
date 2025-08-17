import 'package:flutter/material.dart';
import '../../navigation/routes.dart';
class QuickLinksList extends StatelessWidget{
  const QuickLinksList({super.key});
  ListTile t(BuildContext c, IconData i, String label, String route)=>ListTile(
    leading: Icon(i), title: Text(label), onTap: ()=>Navigator.pushNamed(c, route));
  @override Widget build(BuildContext c)=>Column(children:[
    t(c, Icons.person_outline, 'Account', Routes.account),
    t(c, Icons.devices_other, 'Devices & Integrations', Routes.devices),
    t(c, Icons.notifications_active_outlined, 'Notifications', Routes.notifications),
    t(c, Icons.privacy_tip_outlined, 'Privacy', Routes.privacy),
    t(c, Icons.security, 'Security', Routes.security),
    t(c, Icons.info_outline, 'About', Routes.about),
    t(c, Icons.help_outline, 'Help', Routes.help),
    t(c, Icons.description_outlined, 'Terms', Routes.terms),
    t(c, Icons.privacy_tip, 'Privacy Policy', Routes.policy),
  ]);
}
