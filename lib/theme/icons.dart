import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AevaraBrandIcons {
  // Brand accent colors (placeholder values you can tune)
  static const Color fitbit  = Color(0xFF00B0B9);
  static const Color garmin  = Color(0xFF2B2D42);
  static const Color oura    = Color(0xFF1C1C1E);
  static const Color whoop   = Color(0xFF00A58D);
  static const Color apple   = Color(0xFF1F1F1F);
  static const Color google  = Color(0xFF4285F4);
  static const Color strava  = Color(0xFFFF4C00);
  static const Color polar   = Color(0xFF202124);

  // Asset paths (ensure files exist; pubspec already lists them)
  static const String fitbitPng      = 'assets/providers/fitbit.png';
  static const String garminPng      = 'assets/providers/garmin.png';
  static const String ouraPng        = 'assets/providers/oura.png';
  static const String whoopPng       = 'assets/providers/whoop.png';
  static const String appleHealthPng = 'assets/providers/apple_health.png';
  static const String googleFitPng   = 'assets/providers/google_fit.png';
  static const String stravaPng      = 'assets/providers/strava.png';
  static const String polarPng       = 'assets/providers/polar.png';

  static String assetFor(String providerId) {
    switch (providerId) {
      case 'fitbit':     return fitbitPng;
      case 'garmin':     return garminPng;
      case 'oura':       return ouraPng;
      case 'whoop':      return whoopPng;
      case 'apple':      return appleHealthPng;
      case 'googlefit':  return googleFitPng;
      case 'strava':     return stravaPng;
      case 'polar':      return polarPng;
      default:           return fitbitPng;
    }
  }

  static Color colorFor(String providerId) {
    switch (providerId) {
      case 'fitbit':     return fitbit;
      case 'garmin':     return garmin;
      case 'oura':       return oura;
      case 'whoop':      return whoop;
      case 'apple':      return apple;
      case 'googlefit':  return google;
      case 'strava':     return strava;
      case 'polar':      return polar;
      default:           return Colors.blueGrey;
    }
  }

  // Simple fallback icon if asset missing
  static IconData fallbackIconFor(String providerId) {
    switch (providerId) {
      case 'fitbit':     return Icons.watch_outlined;
      case 'garmin':     return Icons.explore_outlined;
      case 'oura':       return Icons.brightness_3_outlined;
      case 'whoop':      return Icons.favorite_border;
      case 'apple':      return Icons.health_and_safety_outlined;
      case 'googlefit':  return Icons.monitor_heart_outlined;
      case 'strava':     return Icons.directions_run;
      case 'polar':      return Icons.fitness_center_outlined;
      default:           return Icons.watch_outlined;
    }
  }

  // Small helper to open URLs safely
  static Future<void> tryLaunchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Cannot launch $url';
    }
  }
}
