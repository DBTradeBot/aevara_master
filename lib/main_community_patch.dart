
import 'package:flutter/material.dart';

import 'features/community/community_home_page.dart';
import 'features/community/badges_page.dart';
import 'features/community/leaderboards_page.dart';
import 'features/community/challenges_page.dart';
import 'features/community/friends_page.dart';
import 'features/community/clubs_page.dart';

void main() {
  runApp(const AevaraApp());
}

class AevaraApp extends StatelessWidget {
  const AevaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aevara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF5B6CFF)),
      initialRoute: '/community',
      routes: {
        '/community': (c) => const CommunityHomePage(),
        '/community/badges': (c) => const BadgesPage(),
        '/community/leaderboards': (c) => const LeaderboardsPage(),
        '/community/challenges': (c) => const ChallengesPage(),
        '/community/friends': (c) => const FriendsPage(),
        '/community/clubs': (c) => const ClubsPage(),
      },
    );
  }
}
