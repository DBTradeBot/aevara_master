import '../../../app_routes.dart';
final Map<String, List<String>> kDevRouteGroups = {
  'Auth': [Routes.signIn, Routes.signUp, Routes.verify, Routes.forgot],
  'Onboarding': [Routes.obIdentity, Routes.obDemo, Routes.obConsent, Routes.obConnect, Routes.obReady],
  'Tabs': [Routes.home, Routes.dataHub, Routes.experiments, Routes.community, Routes.profile],
  'Insights': [Routes.insights, Routes.whyChange, Routes.methods],
  'Community': [Routes.feed, Routes.friends, Routes.friendProfile, Routes.groups, Routes.badges],
  'Challenges & Leaderboards': [Routes.challenges, Routes.challengeDetail, Routes.leaderboards],
  'Privacy & Export': [Routes.privacyDash, Routes.export, Routes.deleteAccount],
  'Settings': [Routes.settingsPanel, Routes.accountSettings, Routes.securitySettings, Routes.devices, Routes.notifications, Routes.aboutSettings, Routes.help],
  'About & Legal': [Routes.about, Routes.terms, Routes.privacy],
  'Search & Inbox': [Routes.search, Routes.inbox],
  'Dev': [Routes.devRoutes],
};
