import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/tasks_provider.dart';
import '../../services/notification_service.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? editing;

  const AddEditTaskScreen({this.editing, super.key});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  Priority _priority = Priority.medium;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    if (widget.editing != null) {
      _titleController.text = widget.editing!.title;
      _descriptionController.text = widget.editing!.description;
      _dueDate = DateTime(
        widget.editing!.dueDate.year,
        widget.editing!.dueDate.month,
        widget.editing!.dueDate.day,
      );
      _dueTime = TimeOfDay(
        hour: widget.editing!.dueDate.hour,
        minute: widget.editing!.dueDate.minute,
      );
      _priority = widget.editing!.priority;
    } else {
      final now = DateTime.now();
      _dueDate = now.add(const Duration(days: 1));
      _dueTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  DateTime? get _fullDueDateTime {
    if (_dueDate == null || _dueTime == null) return null;
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime!.hour,
      _dueTime!.minute,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fullDueDateTime == null) {
      setState(() => _errorMessage = 'Please select a date and time');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final actions = ref.read(tasksActionsProvider);

      if (widget.editing == null) {
        await actions.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _fullDueDateTime!,
          priority: _priority,
        );
      } else {
        final updated = TaskModel(
          id: widget.editing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _fullDueDateTime!,
          priority: _priority,
          completed: widget.editing!.completed,
          createdAt: widget.editing!.createdAt,
        );
        await actions.update(updated);
      }

      // Schedule notification 30 minutes before due date
      final notifyTime = _fullDueDateTime!.subtract(const Duration(minutes: 30));
      if (notifyTime.isAfter(DateTime.now())) {
        await NotificationService().scheduleNotification(
          id: widget.editing?.id.hashCode ??
              DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: 'Task Reminder',
          body: _titleController.text.trim(),
          scheduledAt: notifyTime,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save task. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.editing != null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF0F1419),
              const Color(0xFF1A1F29),
            ]
                : [
              const Color(0xFFF8F9FF),
              const Color(0xFFE0E7FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context, isDark, isEditing),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title field
                            _buildTextField(
                              controller: _titleController,
                              label: 'Task Title',
                              hint: 'Enter task title',
                              icon: Icons.title,
                              isDark: isDark,
                              maxLines: 1,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Description field
                            _buildTextField(
                              controller: _descriptionController,
                              label: 'Description',
                              hint: 'Enter task description (optional)',
                              icon: Icons.description,
                              isDark: isDark,
                              maxLines: 4,
                            ),

                            const SizedBox(height: 24),

                            // Date & Time section
                            _buildSectionTitle(
                                'Due Date & Time', Icons.schedule, isDark),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateTimeCard(
                                    icon: Icons.calendar_today,
                                    label: 'Date',
                                    value: _dueDate != null
                                        ? DateFormat('MMM dd, yyyy')
                                        .format(_dueDate!)
                                        : 'Select Date',
                                    onTap: _pickDate,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateTimeCard(
                                    icon: Icons.access_time,
                                    label: 'Time',
                                    value: _dueTime != null
                                        ? _dueTime!.format(context)
                                        : 'Select Time',
                                    onTap: _pickTime,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Priority section
                            _buildSectionTitle('Priority Level', Icons.flag, isDark),
                            const SizedBox(height: 12),

                            _buildPrioritySelector(isDark),

                            const SizedBox(height: 24),

                            // Error message
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Save button
                            _buildSaveButton(isEditing),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black87,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditing ? 'Edit Task' : 'New Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    // REMOVED fixed height -> let content size naturally
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,  // reduced from 100
      borderRadius: 16,
      blur: 10,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: isDark
            ? [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ]
            : [
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.4),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          const Color(0xFF6366F1).withOpacity(0.3),
          const Color(0xFF6366F1).withOpacity(0.1),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          // padding replaced to define natural height
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF6366F1), size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(bool isDark) {
    return Row(
      children: Priority.values.map((priority) {
        final isSelected = _priority == priority;
        final color = _getPriorityColor(priority);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GlassmorphicContainer(
                width: double.infinity,
                height: 100,
                borderRadius: 12,
                blur: 10,
                alignment: Alignment.center,
                border: 2,

              linearGradient: LinearGradient(
                colors: isSelected
                    ? [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ]
                    : isDark
                    ? [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ]
                    : [
                  Colors.white.withOpacity(0.6),
                  Colors.white.withOpacity(0.3),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  color.withOpacity(isSelected ? 0.8 : 0.3),
                  color.withOpacity(isSelected ? 0.4 : 0.1),
                ],
              ),
              child: InkWell(
                onTap: () => setState(() => _priority = priority),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  // padding defines natural height and prevents overflow
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        color: color,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(isEditing ? Icons.save : Icons.add, color: Colors.white),
        label: Text(
          isEditing ? 'Save Changes' : 'Create Task',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
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
}
