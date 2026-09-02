/// Single source of route path constants used across the app.
class RoutePaths {
  // Auth
  static const String signin  = '/auth/signin';
  static const String signup  = '/auth/signup';
  static const String verify  = '/auth/verify';
  static const String forgot  = '/auth/forgot';

  // Onboarding
  static const String identity     = '/onboarding/identity';
  static const String demographics = '/onboarding/demographics';
  static const String consent      = '/onboarding/consent';
  static const String connect      = '/onboarding/connect';

  // About / Help
  static const String aboutPrivacy = '/about/privacy';
  static const String about        = '/about';
  static const String aboutTerms   = '/about/terms';
  static const String methodsDoc   = '/info/methods_doc';

  // App
  static const String home = '/app/home';

  // App → Settings/Account
  static const String profileEdit      = '/profile/edit';
  static const String updateProfile    = '/settings/update-profile';
  static const String settingsUsername = '/settings/username';
  static const String settingsEmail    = '/settings/change-email';
  static const String settingsPassword = '/settings/change-password';

  // App → Devices/Notifications
  static const String settingsDevices  = '/settings/devices';
  static const String settingsNotifs   = '/settings/notifications';

  // App → Data & Privacy
  static const String profilePrivacy   = '/profile/privacy';
  static const String profileExport    = '/profile/export';
  static const String profileDelete    = '/profile/delete';
}
