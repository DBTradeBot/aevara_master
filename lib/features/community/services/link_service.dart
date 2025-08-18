import 'package:flutter/material.dart';

/// Represents different deep link intents the app understands.
sealed class CommunityLink {
  const CommunityLink();
}

class InviteLink extends CommunityLink {
  final String code;
  const InviteLink(this.code);
}

class GroupLink extends CommunityLink {
  final String id;
  const GroupLink(this.id);
}

class ProfileLink extends CommunityLink {
  final String handle;
  const ProfileLink(this.handle);
}

/// No-op link service. Replace internals with `uni_links` or `firebase_dynamic_links` later.
class LinkService {
  LinkService._();
  static final instance = LinkService._();

  /// Parse a Uri into a CommunityLink. Customize your link formats here.
  CommunityLink? parse(Uri uri) {
    // Example formats (adjust to your real links):
    // aevara://invite?code=ABC123
    // https://aevara.app/invite/ABC123
    // https://aevara.app/group/xyz
    // https://aevara.app/u/@alex
    final path = uri.pathSegments;
    if (path.isNotEmpty) {
      if (path.first == 'invite' && path.length >= 2)
        return InviteLink(path[1]);
      if (path.first == 'group' && path.length >= 2) return GroupLink(path[1]);
      if (path.first == 'u' && path.length >= 2) return ProfileLink(path[1]);
    }
    if (uri.scheme == 'aevara' && uri.host == 'invite') {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) return InviteLink(code);
    }
    return null;
  }

  /// Call this at app start (or in a screen's initState) once you wire a real link listener.
  Future<void> handleInitialLink(BuildContext context) async {
    // No-op until you integrate `uni_links` or `firebase_dynamic_links`.
    // Example after wiring:
    // final Uri? initial = await getInitialUri();
    // if (initial != null) _route(context, parse(initial));
  }

  /// Call this to listen for incoming links while app is running.
  void handleIncomingLinks(BuildContext context) {
    // No-op until you integrate `uni_links`. Example:
    // uriLinkStream.listen((Uri? uri) => _route(context, parse(uri!)));
  }

  void route(BuildContext context, CommunityLink? link) {
    if (link == null) return;
    switch (link) {
      case InviteLink(code: final c):
        Navigator.pushNamed(context, '/community/friends',
            arguments: {'segment': 'Invites', 'code': c});
        break;
      case GroupLink(id: final id):
        Navigator.pushNamed(context, '/community/challenges',
            arguments: {'groupId': id});
        break;
      case ProfileLink(handle: final h):
        Navigator.pushNamed(context, '/community/friends',
            arguments: {'profile': h});
        break;
    }
  }
}
