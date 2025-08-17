import 'package:flutter/material.dart';
import '../widgets/avatar.dart';
import '../../app_routes.dart';
class GlobalSettingsPanel extends StatelessWidget{
  const GlobalSettingsPanel({super.key});
  @override Widget build(BuildContext c){
    final cs = Theme.of(c).colorScheme;
    return Drawer(child: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children:[
      Row(children:[const Avatar(size:56), const SizedBox(width:12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text('Aevara User', style: Theme.of(c).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
          Text('@username', style: Theme.of(c).textTheme.bodySmall)
        ])),
      ]),
      const SizedBox(height:12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(16)),
        child: Row(children:[Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Text('Streak: 5 days'), const SizedBox(height:4), const Text('Badges: 8 • XP: 1240')
        ])), FilledButton(onPressed: ()=>Navigator.pushNamed(c, Routes.badges), child: const Text('View badges'))])),
      const SizedBox(height:16), const Divider(),
      ListTile(leading: const Icon(Icons.person), title: const Text('Account'), onTap: ()=>Navigator.pushNamed(c, Routes.account)),
      ListTile(leading: const Icon(Icons.devices_other), title: const Text('Devices & Integrations'), onTap: ()=>Navigator.pushNamed(c, Routes.devices)),
      ListTile(leading: const Icon(Icons.notifications_active_outlined), title: const Text('Notifications'), onTap: ()=>Navigator.pushNamed(c, Routes.notifications)),
      ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Privacy'), onTap: ()=>Navigator.pushNamed(c, Routes.privacy)),
      ListTile(leading: const Icon(Icons.security), title: const Text('Security'), onTap: ()=>Navigator.pushNamed(c, Routes.security)),
      ListTile(leading: const Icon(Icons.info_outline), title: const Text('About'), onTap: ()=>Navigator.pushNamed(c, Routes.about)),
      ListTile(leading: const Icon(Icons.help_outline), title: const Text('Help'), onTap: ()=>Navigator.pushNamed(c, Routes.help)),
      ListTile(leading: const Icon(Icons.description_outlined), title: const Text('Terms of Service'), onTap: ()=>Navigator.pushNamed(c, Routes.terms)),
      ListTile(leading: const Icon(Icons.privacy_tip), title: const Text('Privacy Policy'), onTap: ()=>Navigator.pushNamed(c, Routes.policy)),
      const Divider(),
      ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), onTap: ()=>Navigator.pushNamedAndRemoveUntil(c, Routes.signIn, (_)=>false)),
    ])));
  }
}
