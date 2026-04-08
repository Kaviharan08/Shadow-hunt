class PlayerModel {
  final String uid;
  final String username;
  String role;
  String hunterType;
  double x;
  double y;
  int health;
  bool isAlive;
  bool isBot;
  int tasksCompleted;
  int totalTasks;
  bool isInvisible;
  bool portalEntered;

  PlayerModel({
    required this.uid,
    required this.username,
    this.role = 'survivor',
    this.hunterType = 'stalker',
    this.x = 100,
    this.y = 100,
    this.health = 100,
    this.isAlive = true,
    this.isBot = false,
    this.tasksCompleted = 0,
    this.totalTasks = 3,
    this.isInvisible = false,
    this.portalEntered = false,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'role': role,
        'hunterType': hunterType,
        'x': x,
        'y': y,
        'health': health,
        'isAlive': isAlive,
        'isBot': isBot,
        'tasksCompleted': tasksCompleted,
        'totalTasks': totalTasks,
        'isInvisible': isInvisible,
        'portalEntered': portalEntered,
      };

  factory PlayerModel.fromMap(Map<dynamic, dynamic> map) => PlayerModel(
        uid: map['uid'] ?? '',
        username: map['username'] ?? 'Unknown',
        role: map['role'] ?? 'survivor',
        hunterType: map['hunterType'] ?? 'stalker',
        x: (map['x'] ?? 100).toDouble(),
        y: (map['y'] ?? 100).toDouble(),
        health: map['health'] ?? 100,
        isAlive: map['isAlive'] ?? true,
        isBot: map['isBot'] ?? false,
        tasksCompleted: map['tasksCompleted'] ?? 0,
        totalTasks: map['totalTasks'] ?? 3,
        isInvisible: map['isInvisible'] ?? false,
        portalEntered: map['portalEntered'] ?? false,
      );

  PlayerModel copyWith({
    double? x,
    double? y,
    int? health,
    bool? isAlive,
    int? tasksCompleted,
    int? totalTasks,
    String? role,
    String? hunterType,
    bool? isInvisible,
    bool? portalEntered,
  }) =>
      PlayerModel(
        uid: uid,
        username: username,
        role: role ?? this.role,
        hunterType: hunterType ?? this.hunterType,
        x: x ?? this.x,
        y: y ?? this.y,
        health: health ?? this.health,
        isAlive: isAlive ?? this.isAlive,
        isBot: isBot,
        tasksCompleted: tasksCompleted ?? this.tasksCompleted,
        totalTasks: totalTasks ?? this.totalTasks,
        isInvisible: isInvisible ?? this.isInvisible,
        portalEntered: portalEntered ?? this.portalEntered,
      );
}
