// lib/copy/microcopy.dart
//
// Deterministic microcopy for the Coach bubble.
// Exposes BOTH:
//   - CoachCopy.composeLine(...)  → used by daily_providers.dart
//   - buildCoachBubbleLine(...)   → used by hero_header.dart

import 'package:intl/intl.dart';
import 'package:aevara_app/data/models/daily_metrics.dart';

enum CoachDaypart { morning, afternoon, evening }

class CoachCopy {
  CoachCopy._();

  // --- Greeting --------------------------------------------------------------

  static CoachDaypart _daypart(DateTime now) {
    final h = now.hour;
    if (h < 12) return CoachDaypart.morning;
    if (h < 17) return CoachDaypart.afternoon;
    return CoachDaypart.evening;
  }

  static String _greet(DateTime now, String name) {
    switch (_daypart(now)) {
      case CoachDaypart.morning:
        return 'Good morning, $name';
      case CoachDaypart.afternoon:
        return 'Good afternoon, $name';
      case CoachDaypart.evening:
        return 'Good evening, $name';
    }
  }

  // --- Variant pools ---------------------------------------------------------

  static const _younger = <String>[
    "running younger by {d}y",
    "ahead of your age by {d}y",
    "in a younger zone (−{d}y)",
  ];

  static const _near = <String>[
    "about on par with your age",
    "right around your age band",
    "tracking close to your age",
  ];

  static const _slightlyOlder = <String>[
    "a bit older today (+{d}y)",
    "running a touch hot (+{d}y)",
    "slightly above your age (+{d}y)",
  ];

  static const _muchOlder = <String>[
    "under the weather (+{d}y)",
    "well above your age (+{d}y)",
    "body needs a reset (+{d}y)",
  ];

  static const _tailsLowConfidence = <String>[
    "Confidence is low — some data is stale.",
    "Low confidence — refresh data when you can.",
    "Numbers may be off — update your inputs.",
  ];

  static const _tailsCalibrating = <String>[
    "Calibrating your baseline — expect some wobble.",
    "Personalizing your ranges — calibration in progress.",
  ];

  static const _tailsWaitingInputs = <String>[
    "We’ll compute once today’s inputs land.",
    "Add a quick input to compute today.",
  ];

  // --- Helpers ---------------------------------------------------------------

  static int _hashToday(String uid, DateTime now) {
    final key = '${uid}_${now.year}${now.month}${now.day}';
    var h = 0;
    for (final c in key.codeUnits) {
      h = 0x1fffffff & (h + c);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= (h >> 6);
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= (h >> 11);
    h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
    return h & 0x7fffffff;
  }

  static String _fmtDelta(double d) {
    final abs = d.abs();
    return abs.toStringAsFixed(abs >= 1.0 ? 0 : 1);
  }

  static String _humanMetric(String key) {
    switch (key) {
      case 'hrv_rmssd_ms':
        return 'HRV';
      case 'rhr_bpm':
        return 'resting HR';
      case 'sleep_total_hours':
        return 'sleep';
      case 'steps_count':
        return 'activity';
      case 'wellbeing_level_1to5':
      case 'mood_level_1to5':
        return 'wellbeing';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  static String _bestStaleHint(Map<String, int>? stale) {
    if (stale == null || stale.isEmpty) return '';
    final entries = stale.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final names = entries.take(2).map((e) => _humanMetric(e.key)).toList();
    if (names.isEmpty) return '';
    if (names.length == 1) return '${names.first} is stale';
    return '${names.first} & ${names.last} are stale';
  }

  static String _nudgeForDomain(String domain, CoachDaypart daypart, int rot) {
    final map = <String, List<String>>{
      'recovery': switch (daypart) {
        CoachDaypart.evening => [
          'wind down early tonight.',
          'keep it easy; calm evening wins.',
        ],
        CoachDaypart.afternoon => [
          'take a 3‑minute breath break.',
          'keep caffeine light after lunch.',
        ],
        CoachDaypart.morning => [
          'start easy — no hard efforts.',
          'ease into the day.',
        ],
      },
      'sleep': switch (daypart) {
        CoachDaypart.evening => [
          'lights down 60–90m before bed.',
          'keep bedtime consistent tonight.',
        ],
        _ => [
          'plan a steady bedtime window.',
          'avoid late naps today.',
        ],
      },
      'activity': switch (daypart) {
        CoachDaypart.evening => [
          'a short walk after dinner helps.',
          'stretch 5 minutes before bed.',
        ],
        _ => [
          'slot a 10‑minute walk.',
          'break up sits with quick laps.',
        ],
      },
      'wellbeing': switch (daypart) {
        CoachDaypart.evening => [
          'jot a quick note on stress.',
          'do a 2‑minute unwind.',
        ],
        _ => [
          'check in with mood/stress.',
          'do one small stress reset.',
        ],
      },
      'crf': [
        'cardio consistency compounds.',
        'easy aerobic work adds up.',
      ],
    };

    final list = map[domain] ?? const ['small steps add up.'];
    return list[list.isEmpty ? 0 : rot % list.length];
  }

  // --- PUBLIC: main composer used by providers ------------------------------

  /// Full composer used in daily_providers.dart
  static String composeLine({
    required String name,
    required DateTime now,
    required bool hasVitality,
    required String? statusMessage,
    required double deltaYears,
    required String state, // "younger" | "near" | "slightlyOlder" | "muchOlder"
    required int confidence,
    required bool calibrating,
    required int? healthyDays30,
    required Map<String, int>? staleDays,
    String uid = 'anon',
  }) {
    final greet = _greet(now, name);

    if (!hasVitality) {
      final msg = (statusMessage ?? _tailsWaitingInputs.first);
      return '$greet 👋  $msg';
    }

    final pools = switch (state) {
      'younger' => _younger,
      'near' => _near,
      'slightlyOlder' => _slightlyOlder,
      'muchOlder' => _muchOlder,
      _ => _near,
    };

    final h = _hashToday(uid, now);
    final base = pools[h % pools.length].replaceAll('{d}', _fmtDelta(deltaYears));

    String? tail;
    if (calibrating) {
      tail = _tailsCalibrating[h % _tailsCalibrating.length];
    } else if (confidence < 60) {
      final staleHint = _bestStaleHint(staleDays);
      final baseTail = _tailsLowConfidence[h % _tailsLowConfidence.length];
      tail = staleHint.isEmpty ? baseTail : '$baseTail ($staleHint).';
    } else if (healthyDays30 != null && (h % 3 == 0)) {
      tail = 'Healthy days: $healthyDays30/30.';
    }

    return tail == null ? '$greet 👋  Today you’re $base.' : '$greet 👋  Today you’re $base. $tail';
  }
}

// --- PUBLIC: helper used by hero_header.dart --------------------------------

String buildCoachBubbleLine({
  required String name,
  required DateTime now,
  required DailyCoachContext ctx,
  bool includeNudge = true,
}) {
  final greet = CoachCopy._greet(now, name);

  if (!ctx.hasVitality) {
    // Match composeLine behavior when vitality is missing
    return '$greet 👋  We’ll compute once today’s inputs land.';
  }

  // Base state line —
  final stateStr = switch (ctx.state) {
    CoachAgeState.younger => CoachCopy._younger,
    CoachAgeState.near => CoachCopy._near,
    CoachAgeState.slightlyOlder => CoachCopy._slightlyOlder,
    CoachAgeState.muchOlder => CoachCopy._muchOlder,
  };
  final rot = int.parse(DateFormat('yyyyMMdd').format(now)) % stateStr.length;
  final abs = ctx.deltaHealthyYears.abs().toStringAsFixed(
    ctx.deltaHealthyYears.abs() >= 1.0 ? 0 : 1,
  );
  final base = stateStr[rot].replaceAll('{d}', abs);

  // Confidence hint
  final hint = ctx.confidenceBucket == 'low' ? ' (low data confidence)' : '';

  // Optional nudge based on weakest domain
  String nudge = '';
  if (includeNudge) {
    final wd = ctx.weakestDomain();
    if (wd != null) {
      final dp = CoachCopy._daypart(now);
      nudge = ' • ${CoachCopy._nudgeForDomain(wd.$1, dp, rot)}';
    }
  }

  return '$greet 👋  Today you’re $base.$hint$nudge';
}
