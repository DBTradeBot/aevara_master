import 'package:flutter/foundation.dart';

/// Minimal in-memory reaction store (swap with Firestore later).
class ReactionStore extends ChangeNotifier {
  static final ReactionStore I = ReactionStore._();
  ReactionStore._();

  final Map<String, Map<String, int>> counts = {};
  final Map<String, String?> userReacted = {};

  void seed(String badgeId, {Map<String, int>? initial}) {
    counts.putIfAbsent(badgeId, () => {...?initial});
    userReacted.putIfAbsent(badgeId, () => null);
  }

  Map<String, int> getCounts(String badgeId) => counts[badgeId] ?? const {};
  String? getUserEmoji(String badgeId) => userReacted[badgeId];

  void toggle(String badgeId, String emoji) {
    seed(badgeId);
    final prev = userReacted[badgeId];
    if (prev == emoji) {
      final c = counts[badgeId]!;
      c[emoji] = (c[emoji] ?? 1) - 1;
if (c[emoji]! <= 0) c.remove(emoji)
      userReacted[badgeId] = null;
    } else {
      if (prev != null) {
        final c = counts[badgeId]!;
        c[prev] = (c[prev] ?? 1) - 1;
if (c[prev]! <= 0) c.remove(prev)
      }
      counts[badgeId]![emoji] = (counts[badgeId]![emoji] ?? 0) + 1;
      userReacted[badgeId] = emoji;
    }
    notifyListeners();
  }
}


