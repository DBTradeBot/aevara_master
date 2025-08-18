import 'package:flutter/material.dart';

class UserRank {
  final String username;
  final int score;
  final int rank;
  final int delta;
  final bool verified;
  final String avatarEmoji;
  final int streak;

  const UserRank({
    required this.username,
    required this.score,
    required this.rank,
    this.delta = 0,
    this.verified = false,
    this.avatarEmoji = 'ðŸ™‚',
    this.streak = 0,
  });
}

class Challenge {
  final String id;
  final String title;
  final String subtitle;
  final int durationDays;
  final String focus;
  final bool groupable;
  final Color color;

  const Challenge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationDays,
    required this.focus,
    this.groupable = true,
    this.color = const Color(0xFF5B6CFF),
  });
}

class Friend {
  final String handle;
  final int streak;
  final String avatarEmoji;

  const Friend(
      {required this.handle, this.streak = 0, this.avatarEmoji = 'ðŸ™‚'});
}

class Club {
  final String name;
  final String description;
  final int members;
  final String emoji;

  const Club(
      {required this.name,
      required this.description,
      required this.members,
      this.emoji = 'ðŸ'});
}
