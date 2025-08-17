import 'package:flutter/material.dart';
import 'package:aevara_app/theme/aevara_theme.dart';

// App shell (bottom nav + settings bar)
import 'features/home/dashboard_placeholder.dart';

// Onboarding
import 'features/onboarding/identity_page.dart';
import 'features/onboarding/demographics_page.dart';
import 'features/onboarding/username_page.dart';
import 'features/onboarding/consent_page.dart';
import 'features/onboarding/connect_page.dart';
import 'features/onboarding/ready_page.dart';

// Auth stub (replace with real auth later)
import 'features/auth/sign_in_stub.dart';

// Data
import 'features/data/daily_snapshot_page.dart';
import 'features/data/metric_details_page.dart';

// Experiments
import 'features/experiments/experiments_home_page.dart';
import 'features/experiments/experiment_detail_page.dart';

// Community
import 'features/community/community_home_page.dart';   // Community Hub
import 'features/community/leaderboards_page.dart';
import 'features/community/friends_page.dart';
import 'features/community/challenges_page.dart';
import 'features/community/badges_page.dart';            // NEW: Badges
import 'features/community/clubs_page.dart';             // Optional: Clubs (from zip)

// Settings pages
import 'features/settings/profile_page.dart';
import 'features/settings/password_page.dart';
import 'features/settings/devices_page.dart';
import 'features/settings/notifications_page.dart';
import 'features/settings/consents_page.dart';
import 'features/settings/data_control_page.dart';
import 'features/settings/about_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AevaraApp());
}

class AevaraApp extends StatelessWidget {
  const AevaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Build a ColorScheme so we can also seed the AevaraTheme extension from the same seed.
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF5B6CFF));

    return MaterialApp(
      title: 'Aevara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        extensions: <ThemeExtension<dynamic>>[
          AevaraTheme.fromScheme(scheme),
        ],
      ),

      // Start in the app shell
      initialRoute: '/app/home',

      routes: {
        // App shell + deep links to tabs
        '/app/home'        : (c) => const DashboardPlaceholder(),
        '/app/data'        : (c) => const DashboardPlaceholder(initialIndex: 0),
        '/app/experiments' : (c) => const DashboardPlaceholder(initialIndex: 1),
        '/app/community'   : (c) => const DashboardPlaceholder(initialIndex: 2),

        // Optional direct Community Hub entry (used by deep links / buttons)
        '/community'                 : (c) => const CommunityHomePage(),

        // Auth
        '/auth/signin'               : (c) => const SignInStub(),

        // Onboarding
        '/onboarding/identity'       : (c) => const IdentityPage(),
        '/onboarding/demographics'   : (c) => const DemographicsPage(),
        '/onboarding/username'       : (c) => const UsernamePage(),
        '/onboarding/consent'        : (c) => const ConsentPage(),
        '/onboarding/connect'        : (c) => const ConnectPage(),
        '/onboarding/ready'          : (c) => const ReadyPage(),

        // Data subpages
        '/data/daily'                : (c) => const DailySnapshotPage(),
        '/data/metric'               : (c) => const MetricDetailsPage(),

        // Experiments subpages
        '/experiments/home'          : (c) => const ExperimentsHomePage(),
        '/experiments/detail'        : (c) => const ExperimentDetailPage(),

        // Community subpages
        '/community/leaderboards'    : (c) => const LeaderboardsPage(),
        '/community/friends'         : (c) => const FriendsPage(),
        '/community/challenges'      : (c) => const ChallengesPage(),
        '/community/badges'          : (c) => const BadgesPage(),   // NEW
        '/community/clubs'           : (c) => const ClubsPage(),    // Optional

        // Settings pages
        '/settings/profile'          : (c) => const ProfilePage(),
        '/settings/password'         : (c) => const PasswordPage(),
        '/settings/devices'          : (c) => const DevicesPage(),
        '/settings/notifications'    : (c) => const NotificationsPage(),
        '/settings/consents'         : (c) => const ConsentsPage(),
        '/settings/data-control'     : (c) => const DataControlPage(),
        '/settings/about'            : (c) => const AboutPage(),
      },

      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const DashboardPlaceholder()),
    );
  }
}
