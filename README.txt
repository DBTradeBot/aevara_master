
Aevara Community Hub — drop-in module (UI + mock data)
------------------------------------------------------

Add the files into your project under /lib. Then add routes in your main.dart:

  import 'features/community/community_home_page.dart';
  import 'features/community/badges_page.dart';
  import 'features/community/leaderboards_page.dart';
  import 'features/community/challenges_page.dart';
  import 'features/community/friends_page.dart';
  import 'features/community/clubs_page.dart';

  '/community': (c) => const CommunityHomePage(),
  '/community/badges': (c) => const BadgesPage(),
  '/community/leaderboards': (c) => const LeaderboardsPage(),
  '/community/challenges': (c) => const ChallengesPage(),
  '/community/friends': (c) => const FriendsPage(),
  '/community/clubs': (c) => const ClubsPage(),

Replace mock data in lib/data/mock_community_data.dart with Firestore implementation later.
