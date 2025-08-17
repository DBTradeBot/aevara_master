import 'package:flutter/material.dart';
import '../models.dart';

class PodiumCard extends StatelessWidget {
  final List<UserRank> top3;
  const PodiumCard({super.key, required this.top3});

  Widget _medal(UserRank u, Color color, double size, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withOpacity(.95), color.withOpacity(.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: color.withOpacity(.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Center(child: Text(u.avatarEmoji, style: TextStyle(fontSize: size * .55))),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (u.verified) const SizedBox(width: 6),
            if (u.verified) const Icon(Icons.verified, size: 14, color: Colors.blueAccent),
          ],
        ),
        const SizedBox(height: 2),
        Text('${u.score} pts', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.06),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD54F);
    const silver = Color(0xFFB0BEC5);
    const bronze = Color(0xFFBCAAA4);

    final byRank = List<UserRank>.from(top3)..sort((a,b)=>a.rank.compareTo(b.rank));
    if (byRank.length < 3) {
      while (byRank.length < 3) {
        byRank.add(UserRank(username: 'â€”', score: 0, rank: byRank.length+1, avatarEmoji: 'ðŸ™‚'));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _medal(byRank[1], silver, 64, '#2'),
            _medal(byRank[0], gold, 80, '#1'),
            _medal(byRank[2], bronze, 58, '#3'),
          ],
        ),
      ),
    );
  }
}
