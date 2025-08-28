// lib/features/home/components/hero_header_coach.dart
//
// HeroHeaderCoach — text-only coach header (no avatar).
// Renders greeting + today's message bubble. Avatar is now placed
// by DashboardPage at the very top (no elevation).
//
// Dynamic copy pulled from the same providers as VitalityAgeGauge.
// Bubble anchors toward the right (leaving space for gauge).
//
// Note: If you previously saw the avatar here, that has been removed
// per the new layout spec.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aevara_app/core/widgets/avatar/coach_speech_bubble.dart';
import 'package:aevara_app/state/user_providers.dart';
import 'package:aevara_app/state/daily_providers.dart';

class HeroHeaderCoach extends ConsumerWidget {
  const HeroHeaderCoach({super.key});

  // Layout constants
  static const double _kPagePad = 20.0;        // page horizontal padding
  static const double _kGaugeReserve = 160.0;  // keep free for gauge + halo + gutter
  static const double _kBubbleOffsetY = 2.0;   // light downward nudge

  String _timeGreeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String? _firstFromProfile(dynamic profile) {
    if (profile == null) return null;
    try {
      final candidates = <String?>[
        profile.firstName as String?,
        profile.givenName as String?,
        profile.name as String?,
        profile.displayName as String?,
      ];
      for (final c in candidates) {
        final v = (c ?? '').trim();
        if (v.isNotEmpty) return _cap(v.split(RegExp(r'[ \._-]+')).first);
      }
    } catch (_) {}
    return null;
  }

  String _firstFromAuth({required String? displayName, required String? email}) {
    final dn = (displayName ?? '').trim();
    if (dn.isNotEmpty) return _cap(dn.split(RegExp(r'[ \._-]+')).first);
    final em = (email ?? '').trim();
    if (em.contains('@')) {
      final local = em.split('@').first;
      final token = local.split(RegExp(r'[ \._-]+')).first;
      if (token.isNotEmpty) return _cap(token);
    }
    return 'friend';
  }

  String _prettyKey(String key) {
    switch (key.toLowerCase()) {
      case 'recovery':
        return "Recovery";
      case 'sleep':
      case 'sleep_quality':
        return "Sleep";
      case 'activity':
      case 'steps':
        return "Activity";
      case 'affect':
      case 'mood':
      case 'wellbeing':
        return "Mood";
      default:
        return key.replaceAll('_', ' ').split(' ').map(_cap).join(' ');
    }
  }

  String _buildTodayLine({
    required double? va,
    required double? ca,
    Map<String, double>? scores,
    Map<String, double>? weights,
  }) {
    if (va == null || ca == null) {
      return "Today’s Vitality Age is being updated…";
    }

    final delta = va - ca;
    final absDelta = delta.abs();
    final signWord = delta < 0 ? "younger" : (delta > 0 ? "older" : "on par");
    final yearsStr = absDelta.toStringAsFixed(1);
    final vaStr = va.toStringAsFixed(1);

    String? bestKey;
    String? worstKey;
    if (scores != null && scores.isNotEmpty) {
      double bestVal = -1e9, worstVal = 1e9;
      for (final entry in scores.entries) {
        final w = (weights != null && weights.containsKey(entry.key))
            ? weights[entry.key]!
            : 1.0;
        final v = entry.value * w;
        if (v > bestVal) {
          bestVal = v;
          bestKey = entry.key;
        }
        if (v < worstVal) {
          worstVal = v;
          worstKey = entry.key;
        }
      }
    }

    String driverPart = "";
    if (bestKey != null && worstKey != null) {
      driverPart =
      " Strongest: ${_prettyKey(bestKey)}. Needs work: ${_prettyKey(worstKey)}.";
    } else if (bestKey != null) {
      driverPart = " Strongest today: ${_prettyKey(bestKey)}.";
    } else if (worstKey != null) {
      driverPart = " Needs work: ${_prettyKey(worstKey)}.";
    }

    if (delta == 0) {
      return "Today your Vitality Age is $vaStr — right on your chronological age.$driverPart";
    }

    return "Today your Vitality Age is $vaStr — that’s $yearsStr years $signWord.$driverPart";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider).value;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    final greeting = _timeGreeting(DateTime.now());
    final name = _firstFromProfile(profile) ??
        _firstFromAuth(displayName: auth?.displayName, email: auth?.email);

    // Pull same VM as VitalityAgeGauge
    final vmAsync = ref.watch(vitalityGaugeVMProvider);

    return vmAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const Text("—"),
      data: (vm) {
        final vAge = vm.hasVitality ? vm.vitalityAge : null;
        final cAge = vm.chronoAge;
        final scores = vm.scores?.map((k, v) => MapEntry(k, v.toDouble()));
        final weights = vm.weightsUsed?.map((k, v) => MapEntry(k, v.toDouble()));

        final todayLine = _buildTodayLine(
          va: vAge,
          ca: cAge,
          scores: scores,
          weights: weights,
        );

        final text = "$greeting, $name 👋\n$todayLine";
        final ts = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.15);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: ts),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.of(context).size.width;

              // Without the avatar, bubble can sit a bit higher and wider
              final contentW =
              (totalW - (_kPagePad * 2)).clamp(0.0, totalW);
              final leftInsetFromScreen = _kPagePad; // start bubble near page pad
              final rightStopFromScreen =
                  totalW - (_kPagePad + _kGaugeReserve);
              final availableRightSpan =
              (rightStopFromScreen - leftInsetFromScreen)
                  .clamp(160.0, 9999.0);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: _kPagePad),
                child: Transform.translate(
                  offset: const Offset(0, _kBubbleOffsetY),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width:
                        (leftInsetFromScreen - _kPagePad).clamp(0.0, contentW),
                      ),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: availableRightSpan,
                          ),
                          child: CoachSpeechBubble(
                            text: text,
                            tail: BubbleTail.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
