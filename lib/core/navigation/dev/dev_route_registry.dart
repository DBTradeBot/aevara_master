import 'package:aevara_app/core/navigation/routes.dart';

final Map<String, List<String>> kDevRouteGroups = {
  'Auth': [
    AevaraRoutes.signIn,
    AevaraRoutes.signUp,
    AevaraRoutes.verify,
    AevaraRoutes.forgot
  ],
  'Onboarding': [
    AevaraRoutes.obIdentity,
    AevaraRoutes.obDemo,
    AevaraRoutes.obConsent,
    AevaraRoutes.obConnect,
    AevaraRoutes.obReady
  ],
  'Tabs': [
    AevaraRoutes.home,
    AevaraRoutes.dataHub,
    AevaraRoutes.experiments,
    AevaraRoutes.community,
    AevaraRoutes.profile
  ],
  'Insights': [
    AevaraRoutes.insights,
    AevaraRoutes.whyChange,
    AevaraRoutes.methods
  ],
  'Community': [
    AevaraRoutes.feed,
    AevaraRoutes.friends,
    AevaraRoutes.friendProfile,
    AevaraRoutes.groups,
    AevaraRoutes.badges
  ],
  'Challenges & Leaderboards': [
    AevaraRoutes.challenges,
    AevaraRoutes.challengeDetail,
    AevaraRoutes.leaderboards
  ],
  'Privacy & Export': [
    AevaraRoutes.privacyDash,
    AevaraRoutes.export,
    AevaraRoutes.deleteAccount
  ],
  'Settings': [
    AevaraRoutes.settingsPanel,
    AevaraRoutes.accountSettings,
    AevaraRoutes.securitySettings,
    AevaraRoutes.devices,
    AevaraRoutes.notifications,
    AevaraRoutes.aboutSettings,
    AevaraRoutes.help
  ],
  'About & Legal': [
    AevaraRoutes.about,
    AevaraRoutes.terms,
    AevaraRoutes.privacy
  ],
  'Search & Inbox': [AevaraRoutes.search, AevaraRoutes.inbox],
  'Dev': [AevaraRoutes.devRoutes],
};
