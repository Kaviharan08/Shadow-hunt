import 'dart:ui';

class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final String type;
  bool isCompleted;
  final Offset position;

  TaskModel({
    required this.taskId, required this.title,
    required this.description, required this.type,
    required this.position, this.isCompleted = false,
  });

  static List<TaskModel> getForestTasks() => [
    TaskModel(taskId: 'task_1', title: 'Light the Campfire',
        description: 'Tap rapidly 10 times', type: 'tap',
        position: const Offset(360, 300)),
    TaskModel(taskId: 'task_2', title: 'Send Signal Flare',
        description: 'Hold for 3 seconds', type: 'hold',
        position: const Offset(900, 500)),
    TaskModel(taskId: 'task_3', title: 'Fix the Generator',
        description: 'Shake phone 5 times', type: 'shake',
        position: const Offset(280, 800)),
  ];
}
