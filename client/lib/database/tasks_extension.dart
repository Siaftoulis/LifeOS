import 'database.dart';

class TaskData {
  final String id; final String title; final bool isCompleted;
  const TaskData(this.id, this.title, this.isCompleted);
}

extension TaskExt on AppDatabase {
  Stream<List<TaskData>> watchAllTasks() => Stream.value([const TaskData('1', 'Sample Task', false)]);
  Future<void> toggleTaskComplete(String id, bool? val) async {}
  Future<void> insertTask(String id, String title) async {}
  Future<void> deleteTask(String id) async {}
}
