// task provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/task_model.dart';

// Service providers
final firestoreServiceProvider = Provider((ref) => FirestoreService());
final authServiceTaskProvider = Provider((ref) => AuthService());

// Stream provider for tasks
final tasksStreamProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final auth = ref.watch(authServiceTaskProvider);
  final user = auth.currentUser();

  if (user == null) {
    return Stream.value([]);
  }

  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamTasks(user.uid);
});

// Task actions provider
final tasksActionsProvider = Provider((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(authServiceTaskProvider);
  return TasksActions(firestore, auth);
});

// Task actions class
class TasksActions {
  final FirestoreService _firestore;
  final AuthService _auth;
  final Uuid _uuid = const Uuid();

  TasksActions(this._firestore, this._auth);

  // Create new task
  Future<void> create({
    required String title,
    required String description,
    required DateTime dueDate,
    required Priority priority,
  }) async {
    final user = _auth.currentUser();
    if (user == null) throw Exception('User not authenticated');

    final task = TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      completed: false,
      createdAt: DateTime.now(),
    );

    await _firestore.addTask(user.uid, task);
  }

  // Update existing task
  Future<void> update(TaskModel task) async {
    final user = _auth.currentUser();
    if (user == null) throw Exception('User not authenticated');

    await _firestore.updateTask(user.uid, task);
  }

  // Delete task
  Future<void> delete(String taskId) async {
    final user = _auth.currentUser();
    if (user == null) throw Exception('User not authenticated');

    await _firestore.deleteTask(user.uid, taskId);
  }

  // Toggle task completion
  Future<void> toggleComplete(TaskModel task) async {
    final updated = task.copyWith(completed: !task.completed);
    await update(updated);
  }
}