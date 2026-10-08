import 'package:flutter/material.dart';
import '../../../../core/widgets/shimmer_box.dart';

class TaskCardSkeleton extends StatelessWidget {
  const TaskCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              ShimmerBox(width: 10, height: 10, radius: 5),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(width: double.infinity, height: 16)),
            ],
          ),
          SizedBox(height: 10),
          ShimmerBox(width: 200, height: 12),
          SizedBox(height: 14),
          Row(
            children: [
              ShimmerBox(width: 60, height: 22, radius: 6),
              SizedBox(width: 8),
              ShimmerBox(width: 70, height: 22, radius: 6),
              SizedBox(width: 8),
              ShimmerBox(width: 90, height: 22, radius: 6),
            ],
          ),
        ],
      ),
    );
  }
}