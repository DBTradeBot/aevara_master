import 'package:flutter/material.dart';
import '../../data/mock_community_data.dart';
import '../../widgets/badge_card.dart';
import '../../widgets/badge_filters.dart';
import '../../widgets/section.dart';
import './widgets/badge_reactions_row.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String selectedCat = 'All';
  String selectedTier = 'All';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges & Achievements'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Mine'),
            Tab(text: 'Friends'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildMine(),
          _buildFriends(), // ðŸ‘ˆ reactions live here only
          _buildAll(),
        ],
      ),
    );
  }

  Widget _buildMine() {
    final filtered = demoBadges.where((b) {
      final catOk = selectedCat == 'All' || b.category == selectedCat;
      final tierOk = selectedTier == 'All' || b.tier.label == selectedTier;
      return catOk && tierOk;
    }).toList();

    return ListView(
      children: [
        const SizedBox(height: 8),
        CategoryChips(selected: selectedCat, onChanged: (c) => setState(() => selectedCat = c)),
        const SizedBox(height: 8),
        TierFilterBar(selectedTier: selectedTier, onChanged: (t) => setState(() => selectedTier = t)),
        const SizedBox(height: 8),
        Section(
          title: 'Your badges',
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (c, i) {
              final b = filtered[i];
              return BadgeCard(
                badge: b,
                onTap: () => _showBadgeDetail(b),
              );
            },
          ),
        ),
      ],
    );
  }

  /// FRIENDS TAB â€” includes reactions row under each earned badge card.
  Widget _buildFriends() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: demoBadges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = demoBadges[i];
        // unique id for reactions store; adapt if you have a real event id
        final badgeId = 'friend_${i}_${b.name}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Text(b.emoji, style: const TextStyle(fontSize: 24)),
                title: Text('@friend${i + 1} earned ${b.name}'),
                subtitle: Text('${b.tier.label} â€¢ ${b.category}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showBadgeDetail(b),
              ),
            ),

            const SizedBox(height: 8),

            // NEW: emoji reactions (Friends tab only)
            BadgeReactionsRow(
              badgeId: badgeId,
              // Optionally seed with some starting counts from your mocks:
              // seedCounts: {'ðŸ‘': 2, 'ðŸ”¥': 1},
            ),

            const SizedBox(height: 8),
            const Divider(height: 0),
          ],
        );
      },
    );
  }

  Widget _buildAll() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: demoBadges.length,
      itemBuilder: (_, i) => BadgeCard(badge: demoBadges[i], onTap: () => _showBadgeDetail(demoBadges[i])),
    );
  }

  void _showBadgeDetail(BadgeModel b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BadgeDetailSheet(badge: b),
    );
  }
}

class _BadgeDetailSheet extends StatelessWidget {
  final BadgeModel badge;
  const _BadgeDetailSheet({required this.badge});

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned || badge.progress >= 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(badge.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Text(badge.name, style: Theme.of(context).textTheme.titleLarge)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badge.tier.color.withOpacity(.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badge.tier.label),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(badge.description),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: earned ? 1 : badge.progress),
            const SizedBox(height: 16),
            Text('How to earn', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('â€¢ Complete the associated challenge(s) or keep up your streak.'),
            const Text('â€¢ Streaks respect your time zone; one-day grace tokens for long tiers.'),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(onPressed: () => Navigator.pop(context), child: Text(earned ? 'Share' : 'Join a challenge')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
