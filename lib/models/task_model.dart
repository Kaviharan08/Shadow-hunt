class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final String type; // 'tap', 'shake', 'swipe', 'sequence'
  bool isCompleted;
  String? completedBy;

  TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.type,
    this.isCompleted = false,
    this.completedBy,
  });

  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    return TaskModel(
      taskId: map['taskId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'tap',
      isCompleted: map['isCompleted'] ?? false,
      completedBy: map['completedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'type': type,
      'isCompleted': isCompleted,
      'completedBy': completedBy,
    };
  }

  // Predefined horror-themed tasks
  static List<TaskModel> getDefaultTasks() {
    return [
      TaskModel(
        taskId: 'task_1',
        title: 'Fix the Generator',
        description: 'Tap the button 10 times rapidly to restart the generator!',
        type: 'tap',
      ),
      TaskModel(
        taskId: 'task_2',
        title: 'Shake Off the Curse',
        description: 'Shake your phone to break free from the curse!',
        type: 'shake',
      ),
      TaskModel(
        taskId: 'task_3',
        title: 'Enter the Code',
        description: 'Swipe in the correct sequence: Up, Down, Left, Right',
        type: 'sequence',
      ),
      TaskModel(
        taskId: 'task_4',
        title: 'Disable the Alarm',
        description: 'Tap 20 times quickly to disable the alarm before it alerts the hunter!',
        type: 'tap',
      ),
      TaskModel(
        taskId: 'task_5',
        title: 'Escape the Trap',
        description: 'Shake your phone violently to escape the trap!',
        type: 'shake',
      ),
    ];
  }
}
