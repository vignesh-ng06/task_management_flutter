import 'package:flutter/material.dart';
import '../../../../core/widgets/shimmer_box.dart';

class UserTileSkeleton extends StatelessWidget {
  const UserTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const ShimmerBox(width: 44, height: 44, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 140, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 180, height: 11),
                SizedBox(height: 6),
                ShimmerBox(width: 60, height: 14, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}