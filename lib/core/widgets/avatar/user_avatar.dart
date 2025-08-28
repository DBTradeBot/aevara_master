// lib/core/widgets/avatar/user_avatar.dart
//
// UserAvatar — small helper that shows either a photo URL or initials,
// with consistent styling for tiles/headers.

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.size = 40,
    this.photoUrl,
    this.displayName,
  });

  final double size;
  final String? photoUrl;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceVariant;
    final fg = theme.colorScheme.onSurfaceVariant;

    Widget child;
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(bg, fg),
          loadingBuilder: (c, w, progress) {
            if (progress == null) return w;
            return _initials(bg, fg);
          },
        ),
      );
    } else {
      child = _initials(bg, fg);
    }

    return Semantics(
      label: 'User avatar',
      child: SizedBox(
        width: size,
        height: size,
        child: child,
      ),
    );
  }

  Widget _initials(Color bg, Color fg) {
    final initials = _nameToInitials(displayName);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.40,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _nameToInitials(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '•';
    final parts = n.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
