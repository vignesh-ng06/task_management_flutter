import 'package:flutter/material.dart';
import '../../../../core/widgets/shimmer_box.dart';

class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(width: 36, height: 26, radius: 8),
          SizedBox(height: 12),
          ShimmerBox(width: 120, height: 16),
          SizedBox(height: 8),
          ShimmerBox(width: double.infinity, height: 12),
          Spacer(),
          Row(
            children: [
              ShimmerBox(width: 60, height: 12),
              Spacer(),
              ShimmerBox(width: 40, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}