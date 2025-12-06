import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/tasks_provider.dart';
import '../screens/tasks/add_edit_task_screen.dart';
import '../services/notification_service.dart';

class TaskCard extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskCard({required this.task, super.key});

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(tasksActionsProvider);
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    final isOverdue =
        !widget.task.completed && widget.task.dueDate.isBefore(DateTime.now());
    final isDueSoon = !widget.task.completed &&
        widget.task.dueDate.isAfter(DateTime.now()) &&
        widget.task.dueDate
            .isBefore(DateTime.now().add(const Duration(hours: 24)));

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 200,
        borderRadius: 16,
        blur: 10,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          colors: _getCardGradient(isDark, isOverdue, isDueSoon),
        ),
        borderGradient: LinearGradient(
          colors: [
            _getPriorityColor(widget.task.priority).withOpacity(0.5),
            _getPriorityColor(widget.task.priority).withOpacity(0.2),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _controller.forward().then((_) => _controller.reverse());
              _toggleComplete(actions, widget.task);
            },
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // ===================== CONTENT =====================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCheckbox(isDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContent(isDark, isOverdue, isDueSoon),
                      ),
                    ],
                  ),
                ),

                // ===================== ALWAYS VISIBLE ACTION BUTTONS =====================
                Positioned(
                  right: 8,
                  top: 8,
                  child: Row(
                    children: [
                      // EDIT BUTTON
                      _iconButton(
                        icon: Icons.edit,
                        color: const Color(0xFF6366F1),
                        onTap: () => _navigateToEdit(context, widget.task),
                      ),

                      const SizedBox(width: 8),

                      // DELETE BUTTON
                      _iconButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        onTap: () =>
                            _showDeleteDialog(context, actions, widget.task),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildContent(bool isDark, bool isOverdue, bool isDueSoon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration:
            widget.task.completed ? TextDecoration.lineThrough : null,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),

        if (widget.task.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              decoration:
              widget.task.completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ],

        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
              icon: isOverdue
                  ? Icons.warning_amber_rounded
                  : Icons.schedule,
              label: _formatDueDate(widget.task.dueDate),
              color: isOverdue
                  ? Colors.red
                  : (isDueSoon ? Colors.orange : const Color(0xFF6366F1)),
              isDark: isDark,
            ),
            _buildChip(
              icon: _getPriorityIcon(widget.task.priority),
              label: widget.task.priority.name.toUpperCase(),
              color: _getPriorityColor(widget.task.priority),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckbox(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.task.completed
              ? const Color(0xFF6366F1)
              : (isDark ? Colors.white54 : Colors.black26),
          width: 2,
        ),
        color: widget.task.completed
            ? const Color(0xFF6366F1)
            : Colors.transparent,
        boxShadow: widget.task.completed
            ? [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: widget.task.completed
          ? const Icon(
        Icons.check,
        size: 18,
        color: Colors.white,
      )
          : null,
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getCardGradient(bool isDark, bool isOverdue, bool isDueSoon) {
    if (isDark) {
      if (isOverdue) {
        return [
          Colors.red.withOpacity(0.15),
          Colors.red.withOpacity(0.05),
        ];
      }
      if (isDueSoon) {
        return [
          Colors.orange.withOpacity(0.15),
          Colors.orange.withOpacity(0.05),
        ];
      }
      return [
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(0.05),
      ];
    } else {
      if (isOverdue) {
        return [
          Colors.red.withOpacity(0.2),
          Colors.red.withOpacity(0.1),
        ];
      }
      if (isDueSoon) {
        return [
          Colors.orange.withOpacity(0.2),
          Colors.orange.withOpacity(0.1),
        ];
      }
      return [
        Colors.white.withOpacity(0.9),
        Colors.white.withOpacity(0.6),
      ];
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Icons.priority_high;
      case Priority.medium:
        return Icons.remove;
      case Priority.low:
        return Icons.arrow_downward;
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    final difference = taskDate
        .difference(today)
        .inDays;

    if (difference == 0) {
      return 'Today ${DateFormat('h:mm a').format(date)}';
    } else if (difference == 1) {
      return 'Tomorrow ${DateFormat('h:mm a').format(date)}';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference < 0) {
      return '${difference.abs()} days ago';
    } else if (difference <= 7) {
      return DateFormat('EEEE h:mm a').format(date);
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  Future<void> _toggleComplete(dynamic actions, TaskModel task) async {
    final updated = TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      completed: !task.completed,
      createdAt: task.createdAt,
    );

    await actions.update(updated);

    if (updated.completed) {
      await NotificationService().cancelNotification(task.id.hashCode);
    } else {
      // Reschedule notification if uncompleting
      final notifyTime = task.dueDate.subtract(const Duration(minutes: 30));
      if (notifyTime.isAfter(DateTime.now())) {
        await NotificationService().scheduleNotification(
          id: task.id.hashCode,
          title: 'Task Reminder',
          body: task.title,
          scheduledAt: notifyTime,
        );
      }
    }
  }

  void _navigateToEdit(BuildContext context, TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(editing: task),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context,
      dynamic actions,
      TaskModel task,) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Delete Task'),
            content: Text('Are you sure you want to delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    await actions.delete(task.id);
                    await NotificationService()
                        .cancelNotification(task.id.hashCode);
                  } catch (e) {}

                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}