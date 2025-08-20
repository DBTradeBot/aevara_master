// lib/routing/routes.dart
import 'package:flutter/material.dart';

import 'route_paths.dart';

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

// About
import '../features/about/privacy_page.dart';

// App
import '../features/home/dashboard_page.dart';

Map<String, WidgetBuilder> appRoutes = <String, WidgetBuilder>{
  // Auth
  RoutePaths.signin: (_) => const SignInPage(),
  RoutePaths.signup: (_) => const SignUpPage(),
  RoutePaths.verify: (_) => const VerifyEmailPage(),
  RoutePaths.forgot: (_) => const ForgotPasswordPage(),

  // Onboarding
  RoutePaths.demographics: (_) => const DemographicsPage(),
  RoutePaths.identity: (_) => const IdentityPage(),
  RoutePaths.consent: (_) => const ConsentPage(),
  RoutePaths.connect: (_) => const ConnectPage(),

  // About
  RoutePaths.aboutPrivacy: (_) => const PrivacyPage(),

  // App
  RoutePaths.home: (_) => const DashboardPage(),
};

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];
  if (builder != null) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }
  // Fallback to home if unknown
  return MaterialPageRoute(
    builder: (_) => const DashboardPage(),
    settings: const RouteSettings(name: RoutePaths.home),
  );
}
