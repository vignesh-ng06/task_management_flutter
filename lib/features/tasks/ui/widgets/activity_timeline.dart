import 'package:flutter/material.dart';
import '../../data/models/task_activity.dart';

class ActivityTimeline extends StatelessWidget {
  final List<TaskActivity> activities;
  const ActivityTimeline({super.key, required this.activities});

  IconData _iconFor(String type) {
    switch (type) {
      case 'CREATED':
        return Icons.add_circle_outline;
      case 'STATUS_CHANGED':
        return Icons.swap_horiz;
      case 'UPDATED':
        return Icons.edit_outlined;
      case 'COMMENTED':
        return Icons.comment_outlined;
      default:
        return Icons.history;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'CREATED':
        return const Color(0xFF10B981);
      case 'STATUS_CHANGED':
        return const Color(0xFF3B82F6);
      case 'UPDATED':
        return const Color(0xFFF59E0B);
      case 'COMMENTED':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No activity yet',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      );
    }

    return Column(
      children: List.generate(activities.length, (i) {
        final a = activities[i];
        final isLast = i == activities.length - 1;
        final color = _colorFor(a.type);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconFor(a.type),
                        size: 14,
                        color: color,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: a.actorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' ${a.message}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.relativeTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}