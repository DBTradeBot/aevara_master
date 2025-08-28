/// FirestoreContractsV1
/// Central source of truth for Firestore collection & field names (v1 schema).
/// Avoids string literals spread across the codebase.

class FirestorePathsV1 {
  // ---- Top-level ----
  static const users = "users";
  static const userEvents = "user_events";
  static const systemRuns = "system_runs";
  static const leaderboards = "leaderboards";
  static const friends = "friends";
  static const groups = "groups";
  static const challenges = "challenges";
  static const communityEvents = "community_events";
  static const notifications = "notifications";
  static const invites = "invites";
  static const models = "models";
  static const percentiles = "percentiles";
  static const vitalityReference = "vitality_reference";
  static const tiers = "tiers";
  static const config = "config";

  // ---- User subcollections ----
  static String days(String uid) => "users/$uid/days";
  static String dayDoc(String uid, String date) => "users/$uid/days/$date";

  static String hydrationDays(String uid) => "users/$uid/hydration_days";
  static String hydrationDayDoc(String uid, String date) => "users/$uid/hydration_days/$date";

  static String measurements(String uid) => "users/$uid/measurements";
  static String workouts(String uid) => "users/$uid/workouts";
  static String glucose(String uid) => "users/$uid/biometrics_glucose";
  static String temp(String uid) => "users/$uid/biometrics_temp";
  static String bp(String uid) => "users/$uid/biometrics_bp";

  static String events(String uid) => "user_events/$uid/events";
  static String eventDoc(String uid, String id) => "user_events/$uid/events/$id";

  // ---- Leaderboards ----
  static String leaderboardEntries(String boardId) => "leaderboards/$boardId/entries";
}

class FirestoreFieldsV1 {
  // Identity
  static const dateLocal = "date_local";
  static const tz = "tz";

  // Inputs
  static const sleepTotalHours = "sleep_total_hours";
  static const stepsCount = "steps_count";
  static const hrvRmssdMs = "hrv_rmssd_ms";
  static const rhrBpm = "rhr_bpm";
  static const wellbeingLevel = "wellbeing_level_1to5";
  static const sleepRegularityPct = "sleep_regularity_pct";
  static const vo2max = "vo2max_ml_kg_min";
  static const fitnessAge = "fitness_age_years";

  // Computed
  static const ema7 = "ema7";
  static const staleDays = "stale_days";
  static const score = "score";
  static const riskIndex = "risk_index";
  static const vitalityAge = "vitality_age";
  static const scoreConfidence = "score_confidence";
  static const healthyDays30 = "healthy_days_30";
  static const wused = "wused";
  static const constants = "constants";

  // Metadata
  static const computedAtUtc = "computed_at_utc";
  static const lastSchedulerRunUtc = "last_scheduler_run_utc";
}
