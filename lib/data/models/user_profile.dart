// lib/data/models/user_profile.dart
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female, nonbinary, preferNotSay, other }

enum LengthUnit { cm, inch }
enum WeightUnit { kg, lb }

class UnitsPrefs {
  final LengthUnit length;
  final WeightUnit weight;
  const UnitsPrefs({this.length = LengthUnit.cm, this.weight = WeightUnit.kg});

  UnitsPrefs copyWith({LengthUnit? length, WeightUnit? weight}) =>
      UnitsPrefs(length: length ?? this.length, weight: weight ?? this.weight);

  Map<String, dynamic> toMap() => {
    'length': length.name,
    'weight': weight.name,
  };

  static UnitsPrefs? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final length = LengthUnit.values.firstWhereOrNull((e) => e.name == m['length']) ?? LengthUnit.cm;
    final weight = WeightUnit.values.firstWhereOrNull((e) => e.name == m['weight']) ?? WeightUnit.kg;
    return UnitsPrefs(length: length, weight: weight);
  }
}

class SharingPrefs {
  final bool shareAnonymized;
  final bool showOnLeaderboards;
  final bool receiveProductEmails;

  const SharingPrefs({
    this.shareAnonymized = false,
    this.showOnLeaderboards = false,
    this.receiveProductEmails = false,
  });

  SharingPrefs copyWith({
    bool? shareAnonymized,
    bool? showOnLeaderboards,
    bool? receiveProductEmails,
  }) =>
      SharingPrefs(
        shareAnonymized: shareAnonymized ?? this.shareAnonymized,
        showOnLeaderboards: showOnLeaderboards ?? this.showOnLeaderboards,
        receiveProductEmails: receiveProductEmails ?? this.receiveProductEmails,
      );

  Map<String, dynamic> toMap() => {
    'share_anonymized': shareAnonymized,
    'show_on_leaderboards': showOnLeaderboards,
    'receive_product_emails': receiveProductEmails,
  };

  static SharingPrefs? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return SharingPrefs(
      shareAnonymized: m['share_anonymized'] == true,
      showOnLeaderboards: m['show_on_leaderboards'] == true,
      receiveProductEmails: m['receive_product_emails'] == true,
    );
  }
}

/// Tolerant date converter for Firestore + legacy shapes.
DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  if (v is int) {
    try {
      // assume millisSinceEpoch
      return DateTime.fromMillisecondsSinceEpoch(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}

class UserProfile {
  final String uid;
  final String email;

  final String username;
  final String? usernameLower;

  final String? firstName;
  final String? lastName;

  final DateTime? dob;
  final Gender? gender;

  final double? heightCm;
  final double? weightKg;

  final UnitsPrefs? preferredUnits;
  final SharingPrefs? sharing;

  /// Note: stored in Firestore as `Timestamp`; converted to DateTime here.
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    this.usernameLower,
    this.firstName,
    this.lastName,
    this.dob,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.preferredUnits,
    this.sharing,
    required this.createdAt,
    required this.updatedAt,
  });

  // Minimal completion heuristic for onboarding
  bool get minComplete {
    return username.isNotEmpty &&
        dob != null &&
        gender != null &&
        (heightCm != null || weightKg != null);
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? username,
    String? usernameLower,
    String? firstName,
    String? lastName,
    DateTime? dob,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    UnitsPrefs? preferredUnits,
    SharingPrefs? sharing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      usernameLower: usernameLower ?? this.usernameLower,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      sharing: sharing ?? this.sharing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// We intentionally **omit** `created_at` and `updated_at` here.
  /// The Firestore adapter writes them with FieldValue.serverTimestamp().
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'username_lower': (usernameLower ?? username).toLowerCase(),
      'first_name': firstName,
      'last_name': lastName,
      'dob': dob?.toIso8601String(),
      'gender': gender?.name,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'preferred_units': preferredUnits?.toMap(),
      'sharing': sharing?.toMap(),
      // 'created_at': handled in adapter
      // 'updated_at': handled in adapter
    };
  }

  static UserProfile fromMap(Map<String, dynamic> m) {
    Gender? g;
    final gStr = m['gender'];
    if (gStr is String) {
      g = Gender.values.firstWhereOrNull((e) => e.name == gStr);
    }

    return UserProfile(
      uid: m['uid'] as String,
      email: (m['email'] ?? '') as String,
      username: (m['username'] ?? '') as String,
      usernameLower: (m['username_lower'] as String?)?.toLowerCase(),
      firstName: m['first_name'] as String?,
      lastName: m['last_name'] as String?,
      dob: _asDate(m['dob']),
      gender: g,
      heightCm: (m['height_cm'] as num?)?.toDouble(),
      weightKg: (m['weight_kg'] as num?)?.toDouble(),
      preferredUnits: UnitsPrefs.fromMap(m['preferred_units'] as Map<String, dynamic>?),
      sharing: SharingPrefs.fromMap(m['sharing'] as Map<String, dynamic>?),
      createdAt: _asDate(m['created_at']) ?? DateTime.now(),
      updatedAt: _asDate(m['updated_at']) ?? DateTime.now(),
    );
  }
}
