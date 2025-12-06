// firebase service
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get tasks collection reference for a specific user
  CollectionReference tasksRef(String uid) {
    return _db.collection('users').doc(uid).collection('tasks');
  }

  // Stream tasks for real-time updates
  Stream<List<TaskModel>> streamTasks(String uid) {
    return tasksRef(uid)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromDoc(doc)).toList();
    });
  }

  // Add new task
  Future<void> addTask(String uid, TaskModel task) async {
    try {
      await tasksRef(uid).doc(task.id).set(task.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update existing task
  Future<void> updateTask(String uid, TaskModel task) async {
    try {
      await tasksRef(uid).doc(task.id).update(task.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete task
  Future<void> deleteTask(String uid, String taskId) async {
    try {
      await tasksRef(uid).doc(taskId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get single task
  Future<TaskModel?> getTask(String uid, String taskId) async {
    try {
      final doc = await tasksRef(uid).doc(taskId).get();
      if (doc.exists) {
        return TaskModel.fromDoc(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}