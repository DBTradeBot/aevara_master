import 'package:flutter/material.dart';
import 'design/theme.dart';
import 'controllers/theme_controller.dart';
import 'navigation/routes.dart';
// Auth
import 'features/auth/signin/signin_page.dart';
import 'features/auth/signup/signup_page.dart';
import 'features/auth/forgot/forgot_password_page.dart';
// Onboarding
import 'features/onboarding/step_basics_page.dart';
import 'features/onboarding/step_goals_page.dart';
import 'features/onboarding/step_avatar_page.dart';
import 'features/onboarding/step_ready_page.dart';
// Tabs
import 'features/home/home_placeholder_page.dart';
import 'features/data_hub/data_hub_page.dart';
import 'features/experiments/experiments_page.dart';
import 'features/community/community_page.dart';
// Experiments sub
import 'features/experiments/experiment_detail_page.dart';
import 'features/experiments/experiment_start_page.dart';
import 'features/experiments/experiment_active_page.dart';
import 'features/experiments/experiment_progress_page.dart';
// Community sub
import 'features/community/feed_page.dart';
import 'features/community/friends_page.dart';
import 'features/community/groups_page.dart';
import 'features/community/badges_page.dart';
import 'features/community/leaderboards_page.dart';
// DataHub demo subroutes
import 'features/data_hub/metric_details_demo_page.dart';
import 'features/data_hub/wellbeing_prompt_demo_page.dart';
import 'features/data_hub/sync_timeline_page.dart';
// Challenges
import 'features/challenges/challenges_page.dart';
// Settings & Legal
import 'features/settings/account_page.dart';
import 'features/settings/devices_page.dart';
import 'features/settings/notifications_page.dart';
import 'features/settings/privacy_page.dart';
import 'features/settings/security_page.dart';
import 'features/settings/about_page.dart';
import 'features/settings/help_page.dart';
import 'features/legal/terms_page.dart';
import 'features/legal/policy_page.dart';
// Misc
import 'features/search/search_page.dart';
import 'features/inbox/inbox_page.dart';

Route<dynamic> _r(Widget w) => MaterialPageRoute(builder: (_) => w);

class AevaraApp extends StatelessWidget {
  const AevaraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Aevara',
          debugShowCheckedModeBanner: false,
          theme: AeTheme.light(),
          darkTheme: AeTheme.dark(),
          themeMode: mode,
          initialRoute: Routes.signIn,
          onGenerateRoute: (s) {
            switch (s.name) {
              case Routes.signIn:
                return _r(const SignInPage());
              case Routes.signUp:
                return _r(const SignUpPage());
              case Routes.forgot:
                return _r(const ForgotPasswordPage());
              case Routes.obBasics:
                return _r(const OnboardingBasicsPage());
              case Routes.obGoals:
                return _r(const OnboardingGoalsPage());
              case Routes.obAvatar:
                return _r(const OnboardingAvatarPage());
              case Routes.obReady:
                return _r(const OnboardingReadyPage());
              case Routes.home:
                return _r(const HomePlaceholderPage());
              case Routes.dataHub:
                return _r(const DataHubPage());
              case Routes.experiments:
                return _r(const ExperimentsPage());
              case Routes.community:
                return _r(const CommunityPage());
              case Routes.expDetail:
                return _r(const ExperimentDetailPage());
              case Routes.expStart:
                return _r(const ExperimentStartPage());
              case Routes.expActive:
                return _r(const ExperimentActivePage());
              case Routes.expProgress:
                return _r(const ExperimentProgressPage());
              case Routes.feed:
                return _r(const FeedPage());
              case Routes.friends:
                return _r(const FriendsPage());
              case Routes.groups:
                return _r(const GroupsPage());
              case Routes.badges:
                return _r(const BadgesPage());
              case Routes.leaderboards:
                return _r(const LeaderboardsPage());
              case Routes.metricDetails:
                return _r(const MetricDetailsDemoPage());
              case Routes.wellbeingPrompt:
                return _r(const WellbeingPromptDemoPage());
              case Routes.syncTimeline:
                return _r(const SyncTimelinePage());
              case Routes.challenges:
                return _r(const ChallengesPage());
              case Routes.account:
                return _r(const AccountPage());
              case Routes.devices:
                return _r(const DevicesPage());
              case Routes.notifications:
                return _r(const NotificationsPage());
              case Routes.privacy:
                return _r(const PrivacyPage());
              case Routes.security:
                return _r(const SecurityPage());
              case Routes.about:
                return _r(const AboutPage());
              case Routes.help:
                return _r(const HelpPage());
              case Routes.terms:
                return _r(const TermsPage());
              case Routes.policy:
                return _r(const PolicyPage());
              case Routes.search:
                return _r(const SearchPage());
              case Routes.inbox:
                return _r(const InboxPage());
            }
            return _r(const SignInPage());
          },
        );
      },
    );
  }
}
