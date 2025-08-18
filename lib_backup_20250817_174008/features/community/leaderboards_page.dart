import 'package:flutter/material.dart';
import '../../widgets/leaderboard_switcher.dart';
import '../../data/mock_community_data.dart'; // for demoLeaderboard list
import 'widgets/rank_tile.dart' as community;

class LeaderboardsPage extends StatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> {
  String boardType = 'Weekly';
  String scope = 'Friends';

  final TextEditingController _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = demoLeaderboard
        .where((e) =>
            _q.isEmpty || e.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return SafeArea(
      child: Material(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              backgroundColor: Theme.of(context).colorScheme.surface,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Leaderboards'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _q = v),
                        decoration: const InputDecoration(
                          hintText: 'Search names',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    LeaderboardSwitcher(
                      boardType: boardType,
                      onBoardType: (v) => setState(() => boardType = v),
                      scope: scope,
                      onScope: (v) => setState(() => scope = v),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final e = entries[i];
                  return Column(
                    children: [
                      community.RankTile(
                        rank: e.rank,
                        name: e.name,
                        avatarEmoji: e.avatarEmoji,
                        scoreLabel: 'Score ${e.score}',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                    ],
                  );
                },
                childCount: entries.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
