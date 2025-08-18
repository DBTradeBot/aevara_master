<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class ProfileBanner extends StatelessWidget {
  const ProfileBanner({super.key});
  @override
  Widget build(BuildContext c) => Row(children: [
        const CircleAvatar(radius: 28, child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Aevara User',
              style: Theme.of(c)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.w700)),
          Text('@username Ã¢â‚¬Â¢ Streak 5 Ã¢â‚¬Â¢ Badges 8',
              style: Theme.of(c).textTheme.bodySmall)
        ]))
      ]);
}

