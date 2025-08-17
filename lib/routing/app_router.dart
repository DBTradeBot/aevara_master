import 'package:flutter/material.dart';

// Pages
import '../features/auth/sign_in_page.dart';
import '../features/auth/sign_up_page.dart';
import '../features/auth/forgot_page.dart';
import '../features/auth/verify_page.dart';

import '../features/onboarding/intro_page.dart';
import '../features/onboarding/identity_page.dart';
import '../features/onboarding/demographics_page.dart';
import '../features/onboarding/username_page.dart';
import '../features/onboarding/consent_page.dart';
import '../features/onboarding/connect_page.dart';
import '../features/onboarding/ready_page.dart';

import '../features/app/home_placeholder_page.dart';
import '../features/data_hub/data_hub_page.dart';
import '../features/experiments/experiments_page.dart';
import '../features/community/community_page.dart';
import '../features/profile/profile_me_page.dart';
import '../features/settings/settings_panel.dart';
import '../features/dev/dev_menu.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    '/auth/signin': (_) => const SignInPage(),
    '/auth/signup': (_) => const SignUpPage(),
    '/auth/forgot': (_) => const ForgotPage(),
    '/auth/verify': (_) => const VerifyPage(),
    '/onboarding/intro': (_) => const IntroPage(),
    '/onboarding/identity': (_) => const IdentityPage(),
    '/onboarding/demographics': (_) => const DemographicsPage(),
    '/onboarding/username': (_) => const UsernamePage(),
    '/onboarding/consent': (_) => const ConsentPage(),
    '/onboarding/connect': (_) => const ConnectPage(),
    '/onboarding/ready': (_) => const ReadyPage(),
    '/app/home': (_) => const HomePlaceholderPage(),
    '/app/data-hub': (_) => const DataHubPage(),
    '/experiments': (_) => const ExperimentsPage(),
    '/community': (_) => const CommunityPage(),
    '/profile/me': (_) => const ProfileMePage(),
    '/settings': (_) => const SettingsPanel(),
    '/dev': (_) => const DevMenuPage(),
  };
}
