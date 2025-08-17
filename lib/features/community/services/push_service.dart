import 'dart:async';

/// No-op push service. Swap internals for `firebase_messaging` later.
class PushService {
  PushService._();
  static final instance = PushService._();

  final StreamController<Map<String, dynamic>> _onMessage = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _onMessage.stream;

  Future<void> requestPermissions() async {
    // Implement with Firebase Messaging on iOS/Android later.
  }

  Future<void> subscribeToCommunityTopics() async {
    // e.g. FirebaseMessaging.instance.subscribeToTopic('community')
  }

  // Simulate an incoming notification for demo/testing UI only.
  void simulate(Map<String, dynamic> payload) {
    _onMessage.add(payload);
  }
}
