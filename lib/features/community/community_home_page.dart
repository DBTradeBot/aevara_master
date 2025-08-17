import 'package:flutter/material.dart';
import '../../data/mock_community_data.dart';
import '../../widgets/next_milestone_card.dart';
import '../../widgets/section.dart';
import '../../widgets/club_card.dart';
import '../../widgets/recent_event_tile.dart';
import '../../widgets/challenge_card.dart';

// NEW: single compact summary
import '../../widgets/dashboard/badges/badge_summary_card.dart';

class CommunityHomePage extends StatelessWidget {
  const CommunityHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final next = computeNextMilestone(demoBadges);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open settings from shell')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          NextMilestoneCard(
            badge: next,
            onTap: () => Navigator.pushNamed(context, '/community/badges'),
          ),

          // quick links
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickLink(icon: Icons.military_tech, label: 'Badges', route: '/community/badges'),
                _QuickLink(icon: Icons.emoji_events, label: 'Leaderboards', route: '/community/leaderboards'),
                _QuickLink(icon: Icons.flag, label: 'Challenges', route: '/community/challenges'),
                _QuickLink(icon: Icons.groups, label: 'Friends', route: '/community/friends'),
              ],
            ),
          ),

          // LESS SPACE above the fold
          const SizedBox(height: 8),

          // ONE compact summary card (replaces pill + next card)
          const BadgeSummaryCard(),

          const SizedBox(height: 8),

          Section(
            title: 'Trending clubs',
            actionLabel: 'Explore',
            onSeeAll: () => Navigator.pushNamed(context, '/community/clubs'),
            child: SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 4),
                itemCount: demoClubs.length,
                itemBuilder: (_, i) => ClubCard(
                  club: demoClubs[i],
                  width: 220,
                  onTap: () => Navigator.pushNamed(context, '/community/clubs'),
                ),
              ),
            ),
          ),
          Section(
            title: 'Recent reactions',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: demoEvents.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) => RecentEventTile(event: demoEvents[i]),
            ),
          ),
          const SizedBox(height: 12),
          Section(
            title: 'Suggested challenges',
            actionLabel: 'See all',
            onSeeAll: () => Navigator.pushNamed(context, '/community/challenges'),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: demoChallenges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => ChallengeCard(
                challenge: demoChallenges[i],
                onJoin: () {},
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  const _QuickLink({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: 150,
        height: 56, // was 64 â†’ tighter without feeling cramped
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
