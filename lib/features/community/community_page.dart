import 'package:flutter/material.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tc,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Feed'), Tab(text: 'Challenges'), Tab(text: 'Leaderboards'), Tab(text: 'Friends'), Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: const [
          _FeedTab(), _ChallengesTab(), _LeaderboardsTab(), _FriendsTab(), _GroupsTab(),
        ],
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('@dan', 'earned a Sleep Streak badge'),
      ('@alexa', 'completed +10% Steps challenge'),
      ('@rob', 'joined Group: Trail Runners'),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __)=> const SizedBox(height: 8),
      itemBuilder: (_, i){
        final it = items[i];
        return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(it.$1), subtitle: Text(it.$2), trailing: IconButton(icon: const Icon(Icons.heart_broken_outlined), onPressed: (){})));
      },
    );
  }
}

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context) {
    final challenges = [
      ('Public: September Steps', 'Global leaderboard', 'Join'),
      ('Friends: Sleep 7h Streak', 'Private leaderboard', 'Invite'),
      ('Group: Recovery Gains', 'Team board', 'Open'),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      separatorBuilder: (_, __)=> const SizedBox(height: 8),
      itemBuilder: (_, i){
        final c = challenges[i];
        return Card(child: ListTile(title: Text(c.$1), subtitle: Text(c.$2), trailing: FilledButton(onPressed: (){}, child: Text(c.$3))));
      },
    );
  }
}

class _LeaderboardsTab extends StatelessWidget {
  const _LeaderboardsTab();

  @override
  Widget build(BuildContext context) {
    final rows = List.generate(10, (i)=> ('#${i+1}', '@user${i+1}', '${(10000 - i*432)} steps'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Wrap(spacing: 8, children: [Chip(label: Text('Global')), Chip(label: Text('Friends')), Chip(label: Text('Group'))]),
        const SizedBox(height: 12),
        Card(child: Column(children: [for (final r in rows) ListTile(leading: Text(r.$1), title: Text(r.$2), trailing: Text(r.$3))])),
      ],
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context) {
    final friends = ['@dan','@alexa','@rob'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search users')), const SizedBox(height: 12),
        Card(child: Column(children: [for (final f in friends) ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(f), trailing: Wrap(spacing: 8, children: [OutlinedButton(onPressed: (){}, child: const Text('Cheer')), OutlinedButton(onPressed: (){}, child: const Text('Invite'))]))])),
      ],
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    final groups = ['Trail Runners', 'HRV Ninjas', 'Sleep Squad'];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length + 1,
      separatorBuilder: (_, __)=> const SizedBox(height: 8),
      itemBuilder: (_, i){
        if (i==0) {
          return OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.add), label: const Text('Create group'));
        }
        final g = groups[i-1];
        return Card(child: ListTile(title: Text(g), subtitle: const Text('Weekly leaderboard â€¢ 128 members'), trailing: FilledButton(onPressed: (){}, child: const Text('Open'))));
      },
    );
  }
}
