import 'package:flutter/foundation.dart';

/// In-memory social state for Challenges.
/// Swap with Firestore later without changing UI code.
class ChallengeSocialStore extends ChangeNotifier {
  static final ChallengeSocialStore I = ChallengeSocialStore._();
  ChallengeSocialStore._();

  // challengeId -> set of participant display names
  final Map<String, Set<String>> _participants = {};

  // Joined challenge ids (drives "Active" tab)
  final Set<String> _joined = {};

  // Incoming invites: {'challengeId': id, 'from': 'Alex'}
  final List<Map<String, String>> _invites = [];

  // Optional progress per joined challenge (0..1)
  final Map<String, double> _progress = {};

  /// Safe to call repeatedly.
  void seed({List<String>? challengeIds}) {
    if (challengeIds != null) {
      for (final id in challengeIds) {
        _participants.putIfAbsent(id, () => <String>{});
        _progress.putIfAbsent(id, () => 0.0);
      }
    }
    // Seed a couple of invites if empty.
    if (_invites.isEmpty && (challengeIds?.isNotEmpty ?? false)) {
      final ids = challengeIds!;
      if (ids.length >= 2) {
        _invites.addAll([
          {'challengeId': ids[0], 'from': 'Alex'},
          {'challengeId': ids[1], 'from': 'Sam'},
        ]);
      } else {
        _invites.add({'challengeId': ids.first, 'from': 'Alex'});
      }
    }
  }

  // ----- Queries
  Set<String> participants(String id) => _participants[id] ?? <String>{};
  bool isJoined(String id) => _joined.contains(id);
  List<Map<String, String>> get invites => List.unmodifiable(_invites);
  double progress(String id) => _progress[id] ?? 0.0;
  Iterable<String> get activeChallengeIds => _joined;

  // ----- Mutations
  void join(String id, {String me = 'You'}) {
    _joined.add(id);
    _participants.putIfAbsent(id, () => <String>{}).add(me);
    _progress[id] = _progress[id] ?? 0.0;
    notifyListeners();
  }

  void leave(String id, {String me = 'You'}) {
    _joined.remove(id);
    _participants[id]?.remove(me);
    notifyListeners();
  }

  void invite(String id, List<String> friends) {
    _participants.putIfAbsent(id, () => <String>{})
        .addAll(friends.map((e) => '$e (invited)'));
    notifyListeners();
  }

  void acceptInvite(String id, {String me = 'You'}) {
    join(id, me: me);
    _invites.removeWhere((m) => m['challengeId'] == id);
    notifyListeners();
  }

  void declineInvite(String id) {
    _invites.removeWhere((m) => m['challengeId'] == id);
    notifyListeners();
  }

  void nudgeProgress(String id, double delta) {
    final v = (_progress[id] ?? 0.0) + delta;
    _progress[id] = v.clamp(0.0, 1.0);
    notifyListeners();
  }
}
