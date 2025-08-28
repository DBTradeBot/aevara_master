// lib/features/home/components/coach_greeting_bubble.dart
//
// Provider-aware bubble that composes the greeting + Vitality line.
// Tail defaults to TOP-LEFT (points toward the avatar row above).
// Uses the theme’s primary background (white in light mode).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aevara_app/core/widgets/avatar/coach_speech_bubble.dart';
import 'package:aevara_app/state/user_providers.dart';
import 'package:aevara_app/state/daily_providers.dart';

class CoachGreetingBubble extends ConsumerWidget {
  const CoachGreetingBubble({
    super.key,
    this.tail = BubbleTail.topLeft,
    this.tailSize = 14,
    this.tailOffset = 0.16,
    this.maxWidth = 360,
    this.safeHorizontalInset = 4,
    this.maxLines,
    this.textStyle,
    this.elevation = 6,
    this.borderRadius = 12,
  });

  final BubbleTail tail;
  final double tailSize;
  final double tailOffset;
  final double maxWidth;
  final double safeHorizontalInset;
  final int? maxLines;
  final TextStyle? textStyle;
  final double elevation;
  final double borderRadius;

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
      case 'crf':
        return "Fitness";
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

    final vmAsync = ref.watch(vitalityGaugeVMProvider);

    return vmAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (vm) {
        final vAge = vm.hasVitality ? vm.vitalityAge : null;
        final cAge = vm.chronoAge;
        final scores = vm.scores?.map((k, v) => MapEntry(k, v.toDouble()));
        final weights =
        vm.weightsUsed?.map((k, v) => MapEntry(k, v.toDouble()));

        final todayLine = _buildTodayLine(
          va: vAge,
          ca: cAge,
          scores: scores,
          weights: weights,
        );

        final text = "$greeting, $name 👋\n$todayLine";

        // Cap text scale for compactness inside the bubble
        final ts = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.15);

        final theme = Theme.of(context);

        // Force to primary white background (light) or primary dark (dark)
        final bubbleBg = theme.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1B1B1B);

        final bubbleTheme =
        theme.copyWith(scaffoldBackgroundColor: bubbleBg);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: ts),
          child: Theme(
            data: bubbleTheme,
            child: CoachSpeechBubble(
              text: text,
              tail: tail,
              tailSize: tailSize,
              tailOffset: tailOffset,
              maxWidth: maxWidth,
              safeHorizontalInset: safeHorizontalInset,
              maxLines: maxLines,
              textStyle: textStyle,
              elevation: elevation,
              borderRadius: borderRadius,
            ),
          ),
        );
      },
    );
  }
}
