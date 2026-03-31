import 'dart:ui';

class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final String type; // 'tap', 'shake', 'hold'
  bool isCompleted;
  final Offset position; // position on the game map

  TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.type,
    required this.position,
    this.isCompleted = false,
  });

  static List<TaskModel> getForestTasks() => [
        TaskModel(
          taskId: 'task_1',
          title: 'Light the Campfire',
          description: 'Tap rapidly 10 times to start the fire',
          type: 'tap',
          position: const Offset(320, 280),
        ),
        TaskModel(
          taskId: 'task_2',
          title: 'Send Signal Flare',
          description: 'Hold for 3 seconds to launch flare',
          type: 'hold',
          position: const Offset(680, 420),
        ),
        TaskModel(
          taskId: 'task_3',
          title: 'Fix the Generator',
          description: 'Shake phone 5 times to restart it',
          type: 'shake',
          position: const Offset(180, 580),
        ),
      ];
}
