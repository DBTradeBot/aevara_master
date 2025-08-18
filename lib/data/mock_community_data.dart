import 'package:flutter/material.dart';

enum BadgeTier { bronze, silver, gold, platinum, diamond }

extension BadgeTierX on BadgeTier {
  String get label => switch (this) {
        BadgeTier.bronze => 'Bronze',
        BadgeTier.silver => 'Silver',
        BadgeTier.gold => 'Gold',
        BadgeTier.platinum => 'Platinum',
        BadgeTier.diamond => 'Diamond',
      };
  Color get color => switch (this) {
        BadgeTier.bronze => const Color(0xFFB08D57),
        BadgeTier.silver => const Color(0xFFC0C0C0),
        BadgeTier.gold => const Color(0xFFE1B200),
        BadgeTier.platinum => const Color(0xFFE5E4E2),
        BadgeTier.diamond => const Color(0xFF7FDBFF),
      };
}

class BadgeModel {
  final String id;
  final String category;
  final String name;
  final String emoji;
  final BadgeTier tier;
  final String description;
  final double progress;
  final bool earned;

  const BadgeModel({
    required this.id,
    required this.category,
    required this.name,
    required this.emoji,
    required this.tier,
    required this.description,
    required this.progress,
    this.earned = false,
  });
}

class ChallengeModel {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final int days;
  final String category;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.days,
    required this.category,
  });
}

class LeaderboardRowModel {
  final String uid;
  final String name;
  final String avatarEmoji;
  final int rank;
  final int score;
  final int delta;
  final String recentBadgeEmoji;

  const LeaderboardRowModel({
    required this.uid,
    required this.name,
    required this.avatarEmoji,
    required this.rank,
    required this.score,
    required this.delta,
    required this.recentBadgeEmoji,
  });
}

class ClubModel {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int members;

  const ClubModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.members,
  });
}

final demoBadges = <BadgeModel>[
  const BadgeModel(
    id: 'sleep_7',
    category: 'Sleep',
    name: 'Sleep Streak 7',
    emoji: 'ðŸ˜´',
    tier: BadgeTier.bronze,
    description: 'Sleep 7 nights in a row',
    progress: .6,
  ),
  const BadgeModel(
    id: 'steps_10k_day',
    category: 'Steps',
    name: '10k in a Day',
    emoji: 'ðŸ‘Ÿ',
    tier: BadgeTier.bronze,
    description: 'Hit 10k steps in one day',
    progress: 1,
    earned: true,
  ),
  const BadgeModel(
    id: 'hrv_plus_10',
    category: 'Heart',
    name: 'HRV +10ms',
    emoji: 'ðŸ’“',
    tier: BadgeTier.silver,
    description: 'Increase HRV by 10ms over 30 days',
    progress: .2,
  ),
  const BadgeModel(
    id: 'mood_30',
    category: 'Mood',
    name: 'Mood High 30',
    emoji: 'ðŸ˜Š',
    tier: BadgeTier.gold,
    description: 'Mood >4 for 30 days',
    progress: .8,
  ),
  const BadgeModel(
    id: 'med_100',
    category: 'Mindfulness',
    name: 'Meditation 100',
    emoji: 'ðŸ§˜',
    tier: BadgeTier.gold,
    description: 'Meditate 100 days',
    progress: .35,
  ),
  const BadgeModel(
    id: 'sleep_90',
    category: 'Sleep',
    name: 'Sleep Streak 90',
    emoji: 'ðŸŒ™',
    tier: BadgeTier.platinum,
    description: 'Sleep 90 nights in a row',
    progress: .12,
  ),
  const BadgeModel(
    id: 'steps_365',
    category: 'Steps',
    name: '365 Step Streak',
    emoji: 'ðŸ”¥',
    tier: BadgeTier.diamond,
    description: '10k steps for 365 days',
    progress: .01,
  ),
];

final demoChallenges = <ChallengeModel>[
  const ChallengeModel(
    id: 'sleep_onramp_7',
    title: 'Sleep 7',
    subtitle: '7 nights in a row',
    emoji: 'ðŸ›Œ',
    days: 7,
    category: 'Sleep',
  ),
  const ChallengeModel(
    id: 'steps_10k_week',
    title: '70k Week',
    subtitle: '10k steps Ã— 7 days',
    emoji: 'ðŸ‘£',
    days: 7,
    category: 'Steps',
  ),
  const ChallengeModel(
    id: 'hrv_lift_7',
    title: 'HRV Lift',
    subtitle: '+5ms over 7 days',
    emoji: 'ðŸ“ˆ',
    days: 7,
    category: 'Heart',
  ),
  const ChallengeModel(
    id: 'med_7',
    title: 'Meditate 7',
    subtitle: '7 sessions in 7 days',
    emoji: 'ðŸ§˜',
    days: 7,
    category: 'Mindfulness',
  ),
];

final demoClubs = <ClubModel>[
  const ClubModel(
    id: 'sleep_streakers',
    name: 'Sleep Streakers',
    emoji: 'ðŸŒ™',
    description: 'Members chasing 30/60/90-night streaks.',
    members: 428,
  ),
  const ClubModel(
    id: 'ten_k_daily',
    name: '10k Daily',
    emoji: 'ðŸ‘Ÿ',
    description: 'We hit 10k every day. Tips & routes inside.',
    members: 1321,
  ),
  const ClubModel(
    id: 'meditation_100',
    name: 'Meditation 100',
    emoji: 'ðŸ§˜',
    description: 'Mindfulness fans aiming for 100 sessions.',
    members: 289,
  ),
];

final demoLeaderboard = List.generate(10, (i) {
  return LeaderboardRowModel(
    uid: 'user$i',
    name: 'User${i + 1}',
    avatarEmoji: ['ðŸ™‚', 'ðŸ˜Ž', 'ðŸ¤©', 'ðŸ¤“', 'ðŸ¥³'][i % 5],
    rank: i + 1,
    score: 100 - (i * 2),
    delta: (i % 2 == 0 ? 1 : -1) * (i % 3),
    recentBadgeEmoji: ['ðŸ˜´', 'ðŸ‘Ÿ', 'ðŸ§˜', 'ðŸ“ˆ', 'ðŸ˜Š'][i % 5],
  );
});

class RecentEvent {
  final String text;
  final String emoji;
  final DateTime when;
  const RecentEvent(this.text, this.emoji, this.when);
}

final demoEvents = <RecentEvent>[
  RecentEvent('@sam clapped your HRV streak', 'ðŸ‘',
      DateTime.now().subtract(const Duration(minutes: 2))),
  RecentEvent('@jordan fired up your steps', 'ðŸ”¥',
      DateTime.now().subtract(const Duration(hours: 1))),
  RecentEvent('@morgan flexed your PR sleep score', 'ðŸ’ª',
      DateTime.now().subtract(const Duration(hours: 3))),
];

BadgeModel? computeNextMilestone(List<BadgeModel> mine) {
  final candidates = mine.where((b) => !b.earned).toList()
    ..sort((a, b) => b.progress.compareTo(a.progress));
  return candidates.isNotEmpty ? candidates.first : null;
}
