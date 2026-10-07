import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  Color get _priorityColor {
    switch (task.priority) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color get _statusColor {
    switch (task.status) {
      case 'TODO':
        return Colors.grey;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'REVIEW':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + priority dot
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              // Chips row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(text: task.status, color: _statusColor),
                  _Chip(text: task.priority, color: _priorityColor),
                  if (task.projectName != 'No project')
                    _Chip(
                      text: task.projectName,
                      color: Colors.indigo,
                      icon: Icons.folder_outlined,
                    ),
                  _Chip(
                    text: task.dueDateLabel,
                    color: task.isOverdue ? Colors.red : Colors.grey,
                    icon: Icons.schedule,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Chip({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}