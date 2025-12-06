// home screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/task_model.dart';
import '../tasks/add_edit_task_screen.dart';
import '../../widgets/task_card.dart';

enum TaskFilter { all, completed, pending }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  TaskFilter _currentFilter = TaskFilter.all;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    switch (_currentFilter) {
      case TaskFilter.completed:
        return tasks.where((t) => t.completed).toList();
      case TaskFilter.pending:
        return tasks.where((t) => !t.completed).toList();
      case TaskFilter.all:
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final authSvc = ref.watch(authServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              // Custom App Bar
              _buildAppBar(context, authSvc, isDark),

              // Statistics Cards
              tasksAsync.when(
                data: (tasks) => _buildStatistics(tasks, isDark),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),

              // Filter Chips
              _buildFilterChips(isDark),

              const SizedBox(height: 16),

              // Tasks List
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) {
                    final filteredTasks = _filterTasks(tasks);

                    if (filteredTasks.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(tasksStreamProvider);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 300 + (index * 50)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: TaskCard(task: task),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: isDark ? Colors.white : const Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your tasks...',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: isDark ? Colors.white54 : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            _fabAnimationController.reverse().then((_) {
              _fabAnimationController.forward();
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddEditTaskScreen(),
              ),
            );
          },
          backgroundColor: const Color(0xFF6366F1),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Task',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic authSvc, bool isDark) {
    final user = authSvc.currentUser();
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
    if (hour >= 17) greeting = 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  user?.email?.split('@').first ?? 'User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Theme toggle
          IconButton(
            onPressed: () async {
              final notifier = ref.read(themeModeProvider.notifier);
              await notifier.toggleTheme();
            },
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white : Colors.black87,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),

          const SizedBox(width: 8),

          // Logout
          IconButton(
            onPressed: () => _showLogoutDialog(context, authSvc),
            icon: Icon(
              Icons.logout_rounded,
              color: isDark ? Colors.white : Colors.red,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.red.withOpacity(0.2)
                  : Colors.red.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(List<TaskModel> tasks, bool isDark) {
    final total = tasks.length;
    final completed = tasks.where((t) => t.completed).length;
    final pending = tasks.where((t) => !t.completed).length;
    final overdue = tasks
        .where((t) => !t.completed && t.dueDate.isBefore(DateTime.now()))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              total.toString(),
              Icons.list_alt,
              const Color(0xFF6366F1),
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Completed',
              completed.toString(),
              Icons.check_circle,
              Colors.green,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              pending.toString(),
              Icons.pending,
              Colors.orange,
              isDark,
            ),
          ),
          if (overdue > 0) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Overdue',
                overdue.toString(),
                Icons.warning,
                Colors.red,
                isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 90,
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
          color.withOpacity(0.5),
          color.withOpacity(0.2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: TaskFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                _getFilterLabel(filter),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              avatar: Icon(
                _getFilterIcon(filter),
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              onSelected: (_) {
                setState(() => _currentFilter = filter);
              },
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              selectedColor: const Color(0xFF6366F1),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : (isDark ? Colors.white24 : Colors.black12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEmptyStateIcon(),
              size: 64,
              color: isDark ? Colors.white54 : const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.completed:
        return 'Completed';
      case TaskFilter.pending:
        return 'Pending';
    }
  }

  IconData _getFilterIcon(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return Icons.list_rounded;
      case TaskFilter.completed:
        return Icons.check_circle_outline;
      case TaskFilter.pending:
        return Icons.pending_outlined;
    }
  }

  IconData _getEmptyStateIcon() {
    switch (_currentFilter) {
      case TaskFilter.all:
        return Icons.inbox_outlined;
      case TaskFilter.completed:
        return Icons.celebration_outlined;
      case TaskFilter.pending:
        return Icons.pending_actions_outlined;
    }
  }

  String _getEmptyStateTitle() {
    switch (_currentFilter) {
      case TaskFilter.all:
        return 'No tasks yet';
      case TaskFilter.completed:
        return 'No completed tasks';
      case TaskFilter.pending:
        return 'No pending tasks';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_currentFilter) {
      case TaskFilter.all:
        return 'Tap the + button to create your first task';
      case TaskFilter.completed:
        return 'Complete some tasks to see them here';
      case TaskFilter.pending:
        return 'All tasks are completed! Great job!';
    }
  }

  void _showLogoutDialog(BuildContext context, dynamic authSvc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await authSvc.logout();

              // Close dialog
              Navigator.pop(ctx);

              // Navigate to login screen (not splash)
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

}