class Routes {
  // Auth
  static const signIn = '/auth/signin';
  static const signUp = '/auth/signup';
  static const forgot = '/auth/forgot';

  // Onboarding
  static const obBasics = '/onboard/basics';
  static const obGoals = '/onboard/goals';
  static const obAvatar = '/onboard/avatar';
  static const obReady = '/onboard/ready';

  // Tabs
  static const home = '/home';
  static const dataHub = '/data';
  static const experiments = '/experiments';
  static const community = '/community';

  // Experiments (missing in your build)
  static const expDetail = '/experiments/detail';
  static const expStart = '/experiments/start';
  static const expActive = '/experiments/active';
  static const expProgress = '/experiments/progress';

  // DataHub sub
  static const metricDetails = '/data/metric_details';
  static const wellbeingPrompt = '/data/wellbeing_prompt';
  static const syncTimeline = '/data/sync_timeline';

  // Community sub
  static const feed = '/community/feed';
  static const friends = '/community/friends';
  static const groups = '/community/groups';
  static const badges = '/community/badges';
  static const leaderboards = '/community/leaderboards';

  // Challenges
  static const challenges = '/challenges';

  // Settings & Legal
  static const account = '/settings/account';
  static const devices = '/settings/devices';
  static const notifications = '/settings/notifications';
  static const privacy = '/settings/privacy';
  static const security = '/settings/security';
  static const about = '/settings/about';
  static const help = '/settings/help';
  static const terms = '/legal/terms';
  static const policy = '/legal/policy';

  // Misc
  static const search = '/search';
  static const inbox = '/inbox';
}
