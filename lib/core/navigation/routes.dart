// lib/core/navigation/routes.dart
class AevaraRoutes {
  // App tabs
  static const home = '/app/home';
  static const dataHub = '/app/data';
  static const experiments = '/app/experiments';
  static const community = '/app/community';

  // Auth
  static const signIn = '/auth/signin';
  static const signUp = '/auth/signup';
  static const verify = '/auth/verify';
  static const forgot = '/auth/forgot';

  // Onboarding
  static const obIdentity = '/onboarding/identity';
  static const obDemo = '/onboarding/demographics';
  static const obConsent = '/onboarding/consent';
  static const obConnect = '/onboarding/connect';
  static const obReady = '/onboarding/ready';

  // Insights / Data
  static const insights = '/insights';
  static const whyChange = '/insights/why-change';
  static const methods = '/insights/methods';
  static const metricDetail = '/data/metric';
  static const daily = '/data/daily';

  // Community
  static const feed = '/community/feed';
  static const friends = '/community/friends';
  static const groups = '/community/groups';
  static const badges = '/community/badges';
  static const challenges = '/community/challenges';
  static const leaderboards = '/community/leaderboards';
  static const friendProfile = '/community/friend-profile';
  static const challengeDetail = '/community/challenge-detail';

  // Search & inbox
  static const search = '/search';
  static const inbox = '/inbox';

  // Settings (& panel entries)
  static const settingsPanel = '/settings';
  static const accountSettings = '/settings/profile';
  static const securitySettings = '/settings/security';
  static const notifications = '/settings/notifications';
  static const privacyDash = '/settings/data-control';
  static const export = '/settings/export';
  static const deleteAccount = '/settings/delete-account';
  static const aboutSettings = '/settings/about';
  static const help = '/settings/help';
  static const terms = '/about/terms';
  static const policy = '/about/policy';

  // Generic/profile/about (aliases some of the above)
  static const profile = '/settings/profile';
  static const about = '/settings/about';

  // Additional settings expected by some screens
  static const devices = '/settings/devices';
  static const privacy = '/settings/privacy';

  // Dev
  static const devRoutes = '/dev/routes';
}
