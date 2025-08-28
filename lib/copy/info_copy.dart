// lib/copy/info_copy.dart
//
// Transparency & info sheet copy blocks.
// Each metric or score gets a “What it is / Why it matters / How we calculate / Where it comes from”
// aligned with Aevara’s transparency pillar.

class InfoCopy {
  InfoCopy._();

  static const vitalityAge = {
    "what": "Your body’s functional age, based on heart, sleep, activity, and wellbeing.",
    "why": "It reflects how your lifestyle and recovery compare to your chronological age.",
    "how": "We combine daily subscores (Recovery, Sleep, Activity, Wellbeing, optional Fitness) into a Risk Index, then map it linearly to years. Constants and caps are transparent in your data.",
    "where": "Derived from your daily inputs and connected devices.",
  };

  static const healthyDays = {
    "what": "The number of physically and mentally healthy days you’ve had in the past month.",
    "why": "It’s a simple way to see if your habits are improving your wellbeing.",
    "how": "We subtract penalties for metrics out of range and add bonuses for optimal days, rolling over 30 days.",
    "where": "Built from your daily signals — recovery, sleep, activity, and affect inputs.",
  };

  static const sleep = {
    "what": "Your total nightly sleep hours (and regularity if available).",
    "why": "Both short and long sleep increase health risks; ~7–8h is optimal.",
    "how": "We use a U-curve that peaks at 7.5h, with bonus for consistent bed/wake times.",
    "where": "Wearables like Oura, Fitbit, Apple Health, or manual input.",
  };

  static const recovery = {
    "what": "Your recovery balance, from HRV (higher is better) and Resting HR (lower is better).",
    "why": "A strong autonomic system supports stress resilience and longevity.",
    "how": "Weighted 60:40 HRV:RHR, scaled into a subscore (0–100).",
    "where": "Usually measured passively by wearables overnight.",
  };

  static const activity = {
    "what": "Your daily steps or activity minutes.",
    "why": "Moderate daily activity reduces risk for many diseases.",
    "how": "We use a logistic curve: big gains 3–10k, flattening by ~12k.",
    "where": "Wearables, phones, or manual logs.",
  };

  static const wellbeing = {
    "what": "Your self-rated wellbeing (1–5).",
    "why": "How you feel mentally and emotionally is as important as physical signals.",
    "how": "Mapped from 1=excellent to 5=poor; older mood/stress inputs fall back here.",
    "where": "Quick check-ins in Aevara or connected apps.",
  };
}
