import 'package:flutter/material.dart'; import '../../core/navigation/app_shell.dart'; import '../../core/tiles/leaderboard_row.dart';
class LeaderboardsPage extends StatefulWidget{ const LeaderboardsPage({super.key}); @override State<LeaderboardsPage> createState()=>_LeaderboardsPageState();}
class _LeaderboardsPageState extends State<LeaderboardsPage>{ List<int> cheers=[0,0,0];
  @override Widget build(BuildContext c)=>AppShell(currentIndex:3, child: DefaultTabController(length:3, child: Column(children:[
    const TabBar(tabs:[Tab(text:'Overall'), Tab(text:'Weekly Steps'), Tab(text:'Sleep Streaks')]),
    Expanded(child: TabBarView(children:[
      ListView(children:[LeaderboardRow(rank:1, name:'Alex', score:'980', onCheer:(){setState(()=>cheers[0]++);}),
        LeaderboardRow(rank:2, name:'Sam', score:'930', onCheer:(){setState(()=>cheers[1]++);}),
        LeaderboardRow(rank:3, name:'Jules', score:'900', onCheer:(){setState(()=>cheers[2]++);}),
      ]),
      ListView(children:[const ListTile(title: Text('Weekly steps board (placeholder)'))]),
      ListView(children:[const ListTile(title: Text('Sleep streaks board (placeholder)'))]),
    ])),
  ])));
}
