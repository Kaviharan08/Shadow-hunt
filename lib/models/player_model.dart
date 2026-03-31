class PlayerModel {
  final String uid;
  final String username;
  String role; // 'killer' or 'survivor'
  double x;
  double y;
  int health; // 100
  bool isAlive;
  bool isBot;
  int tasksCompleted;
  int totalTasks;

  PlayerModel({
    required this.uid,
    required this.username,
    this.role = 'survivor',
    this.x = 100,
    this.y = 100,
    this.health = 100,
    this.isAlive = true,
    this.isBot = false,
    this.tasksCompleted = 0,
    this.totalTasks = 3,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'role': role,
        'x': x,
        'y': y,
        'health': health,
        'isAlive': isAlive,
        'isBot': isBot,
        'tasksCompleted': tasksCompleted,
        'totalTasks': totalTasks,
      };

  factory PlayerModel.fromMap(Map<dynamic, dynamic> map) => PlayerModel(
        uid: map['uid'] ?? '',
        username: map['username'] ?? 'Unknown',
        role: map['role'] ?? 'survivor',
        x: (map['x'] ?? 100).toDouble(),
        y: (map['y'] ?? 100).toDouble(),
        health: map['health'] ?? 100,
        isAlive: map['isAlive'] ?? true,
        isBot: map['isBot'] ?? false,
        tasksCompleted: map['tasksCompleted'] ?? 0,
        totalTasks: map['totalTasks'] ?? 3,
      );

  PlayerModel copyWith({
    double? x, double? y, int? health,
    bool? isAlive, int? tasksCompleted, String? role,
  }) =>
      PlayerModel(
        uid: uid, username: username,
        role: role ?? this.role,
        x: x ?? this.x, y: y ?? this.y,
        health: health ?? this.health,
        isAlive: isAlive ?? this.isAlive,
        isBot: isBot,
        tasksCompleted: tasksCompleted ?? this.tasksCompleted,
        totalTasks: totalTasks,
      );
}
