import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/room_model.dart';
import '../models/player_model.dart';
import '../models/task_model.dart';

class GameService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();

  // Generate a 6-character room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (i) => chars[DateTime.now().microsecond % chars.length + i % chars.length]).join();
  }

  // Create a new game room
  Future<RoomModel?> createRoom(String hostUid, String username) async {
    try {
      String roomId = _uuid.v4().substring(0, 8);
      String roomCode = _generateRoomCode();

      DatabaseReference roomRef = _db.ref('rooms/$roomId');

      RoomModel room = RoomModel(
        roomId: roomId,
        roomCode: roomCode,
        hostUid: hostUid,
      );

      await roomRef.set(room.toMap());

      // Add host as first player (role assigned later)
      PlayerModel host = PlayerModel(
        uid: hostUid,
        username: username,
        role: 'pending',
      );
      await roomRef.child('players/$hostUid').set(host.toMap());

      return room;
    } catch (e) {
      return null;
    }
  }

  // Join existing room by code
  Future<RoomModel?> joinRoom(String roomCode, String uid, String username) async {
    try {
      DatabaseEvent event = await _db.ref('rooms').orderByChild('roomCode').equalTo(roomCode).once();
      
      if (event.snapshot.value == null) return null;

      Map<dynamic, dynamic> rooms = event.snapshot.value as Map;
      String roomId = rooms.keys.first;
      RoomModel room = RoomModel.fromMap(roomId, rooms[roomId]);

      if (room.status != 'waiting') return null;
      if (room.players.length >= room.maxPlayers) return null;

      PlayerModel player = PlayerModel(
        uid: uid,
        username: username,
        role: 'pending',
      );

      await _db.ref('rooms/$roomId/players/$uid').set(player.toMap());
      return room;
    } catch (e) {
      return null;
    }
  }

  // Start game — assign roles
  Future<void> startGame(String roomId, Map<String, PlayerModel> players) async {
    List<String> playerIds = players.keys.toList();
    playerIds.shuffle();

    // First player becomes hunter, rest are survivors
    String hunterId = playerIds.first;

    for (String uid in playerIds) {
      String role = uid == hunterId ? 'hunter' : 'survivor';
      await _db.ref('rooms/$roomId/players/$uid/role').set(role);
    }

    // Add tasks to room
    List<TaskModel> tasks = TaskModel.getDefaultTasks();
    for (TaskModel task in tasks) {
      await _db.ref('rooms/$roomId/tasks/${task.taskId}').set(task.toMap());
    }

    await _db.ref('rooms/$roomId/status').set('playing');
  }

  // Mark player as caught (hunter action)
  Future<void> catchPlayer(String roomId, String targetUid) async {
    await _db.ref('rooms/$roomId/players/$targetUid/isAlive').set(false);
    await _db.ref('rooms/$roomId/events').push().set({
      'type': 'caught',
      'targetUid': targetUid,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Complete a task (survivor action)
  Future<void> completeTask(String roomId, String taskId, String uid) async {
    await _db.ref('rooms/$roomId/tasks/$taskId').update({
      'isCompleted': true,
      'completedBy': uid,
    });
    await _db.ref('rooms/$roomId/players/$uid/tasksCompleted')
        .set(ServerValue.increment(1));
  }

  // End game
  Future<void> endGame(String roomId, String winnerRole) async {
    await _db.ref('rooms/$roomId').update({
      'status': 'finished',
      'winnerRole': winnerRole,
    });
  }

  // Stream room data
  Stream<RoomModel?> streamRoom(String roomId) {
    return _db.ref('rooms/$roomId').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return RoomModel.fromMap(roomId, event.snapshot.value as Map);
    });
  }

  // Check win conditions
  Future<void> checkWinCondition(String roomId, RoomModel room) async {
    List<PlayerModel> survivors = room.players.values
        .where((p) => p.role == 'survivor')
        .toList();

    List<PlayerModel> aliveSurvivors = survivors.where((p) => p.isAlive).toList();

    // Hunter wins if all survivors are caught
    if (aliveSurvivors.isEmpty) {
      await endGame(roomId, 'hunter');
      return;
    }

    // Check if all tasks completed
    DatabaseEvent event = await _db.ref('rooms/$roomId/tasks').once();
    if (event.snapshot.value != null) {
      Map tasks = event.snapshot.value as Map;
      bool allDone = tasks.values.every((t) => t['isCompleted'] == true);
      if (allDone) {
        await endGame(roomId, 'survivors');
      }
    }
  }
}
