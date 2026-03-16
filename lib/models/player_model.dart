class PlayerModel {
  final String uid;
  final String username;
  final String role; // 'hunter' or 'survivor'
  bool isAlive;
  bool isReady;
  int tasksCompleted;
  int wins;
  int losses;

  PlayerModel({
    required this.uid,
    required this.username,
    required this.role,
    this.isAlive = true,
    this.isReady = false,
    this.tasksCompleted = 0,
    this.wins = 0,
    this.losses = 0,
  });

  factory PlayerModel.fromMap(Map<dynamic, dynamic> map) {
    return PlayerModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? 'Unknown',
      role: map['role'] ?? 'survivor',
      isAlive: map['isAlive'] ?? true,
      isReady: map['isReady'] ?? false,
      tasksCompleted: map['tasksCompleted'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'role': role,
      'isAlive': isAlive,
      'isReady': isReady,
      'tasksCompleted': tasksCompleted,
      'wins': wins,
      'losses': losses,
    };
  }
}
