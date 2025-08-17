import 'package:flutter/material.dart';
import '../../core/app_shell/app_shell.dart';
import '../../core/widgets/ae_progress_ring.dart';
import '../../core/widgets/ae_list_section_header.dart';
import '../../navigation/routes.dart';
class HomePlaceholderPage extends StatelessWidget{
  const HomePlaceholderPage({super.key});
  @override Widget build(BuildContext c)=>AppShell(currentIndex:0, title:'Home', body: ListView(padding: const EdgeInsets.all(16), children:[
    const Row(children:[ Expanded(child: Card(child: ListTile(title: Text('Welcome back'), subtitle: Text('Coach tip: small steps daily')))), SizedBox(width:12), AeProgressRing(value:.62, label:'Weekly Goal') ]),
    const SizedBox(height:16),
    const AeListSectionHeader(title:'Shortcuts'),
    Wrap(spacing:8, runSpacing:8, children:[
      FilledButton(onPressed: ()=>Navigator.pushNamed(c, Routes.dataHub), child: const Text('Data Hub')),
      OutlinedButton(onPressed: ()=>Navigator.pushNamed(c, Routes.experiments), child: const Text('Experiments')),
      OutlinedButton(onPressed: ()=>Navigator.pushNamed(c, Routes.challenges), child: const Text('Challenges')),
      OutlinedButton(onPressed: ()=>Navigator.pushNamed(c, Routes.leaderboards), child: const Text('Leaderboards')),
      OutlinedButton(onPressed: ()=>Navigator.pushNamed(c, Routes.badges), child: const Text('Badges')),
    ])
  ]));
}
