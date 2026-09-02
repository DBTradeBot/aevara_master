// lib/routing/routes.dart
import 'package:flutter/material.dart';

import '../routing/route_paths.dart';

// Auth
import '../features/auth/signin_page.dart';
import '../features/auth/signup_page.dart';
import '../features/auth/verify_email_page.dart';
import '../features/auth/forgot_password_page.dart';

// Onboarding
import '../features/onboarding/identity_page.dart';
import '../features/onboarding/demographics_page.dart';
import '../features/onboarding/consent_page.dart';
import '../features/onboarding/connect_page.dart';

// About & Legal
import '../features/about/privacy_page.dart'; // ✅ corrected
import '../features/about/about_page.dart';
import '../features/about/terms_page.dart';

// Devices & Notifications
import '../features/settings/devices_page.dart';
import '../features/settings/notifications_page.dart';

// Account/Settings pages
import '../features/profile/edit/edit_profile_page.dart'; // legacy route target (kept)
import '../features/settings/account/change_username_page.dart';
import '../features/settings/account/change_email_page.dart';
import '../features/settings/account/change_password_page.dart';
import '../features/settings/account/update_profile_page.dart'; // ✅ new page

// Data & Privacy
import '../features/profile/privacy_dashboard_page.dart';
import '../features/profile/export_page.dart';
import '../features/profile/delete_account_page.dart';

// Methods & transparency (existing docs page)
import '../features/insights/methods_doc_page.dart';

// App shell + guards
import '../shell/app_shell.dart';
import '../core/guards/auth_guard.dart';
import '../core/guards/onboarding_guard.dart';

final Map<String, WidgetBuilder> appRoutes = <String, WidgetBuilder>{
  // Auth
  RoutePaths.signin: (_) => const SignInPage(),
  RoutePaths.signup: (_) => const SignUpPage(),
  RoutePaths.verify: (_) => const VerifyEmailPage(),
  RoutePaths.forgot: (_) => const ForgotPasswordPage(),

  // Onboarding
  RoutePaths.identity: (_) => const IdentityPage(),
  RoutePaths.demographics: (_) => const DemographicsPage(),
  RoutePaths.consent: (_) => const ConsentPage(),
  RoutePaths.connect: (_) => const ConnectPage(),

  // About & Legal
  RoutePaths.aboutPrivacy: (_) => const PrivacyPage(), // ✅ fixed mapping
  RoutePaths.about: (_) => const AboutPage(),
  RoutePaths.aboutTerms: (_) => const TermsPage(),

  // Devices & Notifications
  RoutePaths.settingsDevices: (_) => const DevicesPage(),
  RoutePaths.settingsNotifs: (_) => const NotificationsPage(),

  // Data & Privacy
  RoutePaths.profilePrivacy: (_) => const PrivacyDashboardPage(),
  RoutePaths.profileExport:  (_) => const ExportPage(),
  RoutePaths.profileDelete:  (_) => const DeleteAccountPage(),

  // Account / Profile editors
  RoutePaths.profileEdit:       (_) => const EditProfilePage(), // legacy
  RoutePaths.updateProfile:     (_) => const UpdateProfilePage(), // ✅ new route
  RoutePaths.settingsUsername:  (_) => const ChangeUsernamePage(),
  RoutePaths.settingsEmail:     (_) => const ChangeEmailPage(),
  RoutePaths.settingsPassword:  (_) => const ChangePasswordPage(),

  // Methods & transparency
  RoutePaths.methodsDoc: (_) => const MethodsDocPage(),

  // APP HOME → wrap the shell with both guards:
  //   - AuthGuard ensures user is signed in.
  //   - OnboardingGuard ensures onboarding is finished before letting user in.
  RoutePaths.home: (_) =>
      AuthGuard(child: OnboardingGuard(child: const AppShell())),
};

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];
  if (builder != null) {
    return MaterialPageRoute<void>(builder: builder, settings: settings);
  }
  // Fallback to home if unknown
  return MaterialPageRoute<void>(
    builder: (_) => AuthGuard(child: OnboardingGuard(child: const AppShell())),
    settings: const RouteSettings(name: RoutePaths.home),
  );
}
