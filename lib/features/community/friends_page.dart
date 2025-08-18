import 'package:flutter/material.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 4, vsync: this); // Friends / Invites / Discover / Clubs
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Invites'),
            Tab(text: 'Discover'),
            Tab(text: 'Clubs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _friends(),
          _invites(), // fixed: trailing is now constrained
          _discover(),
          _clubsShortcut(),
        ],
      ),
    );
  }

  Widget _friends() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Search friends',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(['ðŸ™‚', 'ðŸ˜Ž', 'ðŸ¤©'][i])),
                title: Text(['@alex', '@sam', '@jordan'][i]),
                subtitle: const Text('x7 â€¢ Top badges: ðŸ˜´ ðŸ‘Ÿ ðŸ§˜'),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'cheer', child: Text('Cheer ðŸ‘')),
                    PopupMenuItem(value: 'nudge', child: Text('Nudge ðŸ””')),
                    PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _invites() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('Invite to @casey'),
            subtitle: const Text('1m ago'),
            trailing: SizedBox(
              width:
                  180, // constrain trailing area so ListTile doesn't overflow
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Decline',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {},
                      child:
                          const Text('Accept', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _discover() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Find friends via contacts or share your QR.',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add),
                label: const Text('Invite friends')),
          ],
        ),
      ),
    );
  }

  Widget _clubsShortcut() {
    return Center(
      child: FilledButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/community/clubs'),
        icon: const Icon(Icons.groups),
        label: const Text('Browse clubs'),
      ),
    );
  }
}

