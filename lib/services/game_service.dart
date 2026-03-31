import 'package:firebase_database/firebase_database.dart';
import '../models/room_model.dart';
import '../models/player_model.dart';
import 'dart:math';

class GameService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<String> createRoom(String hostUid, String username, bool isSolo) async {
    String roomId = _generateRoomCode();
    RoomModel room = RoomModel(
      roomId: roomId,
      hostUid: hostUid,
      isSoloMode: isSolo,
      maxPlayers: isSolo ? 1 : 4,
    );
    PlayerModel host = PlayerModel(
      uid: hostUid,
      username: username,
      x: 400, y: 300,
    );
    room.players[hostUid] = host;
    await _db.ref('rooms/$roomId').set(room.toMap());
    return roomId;
  }

  Future<bool> joinRoom(String roomId, String uid, String username) async {
    try {
      DataSnapshot snap = await _db.ref('rooms/$roomId').get();
      if (!snap.exists) return false;
      RoomModel room = RoomModel.fromMap(snap.value as Map);
      if (room.status != 'waiting') return false;
      if (room.players.length >= room.maxPlayers) return false;
      PlayerModel player = PlayerModel(
        uid: uid, username: username,
        x: 200 + Random().nextInt(300).toDouble(),
        y: 200 + Random().nextInt(200).toDouble(),
      );
      await _db.ref('rooms/$roomId/players/$uid').set(player.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> startGame(String roomId, RoomModel room) async {
    List<String> playerIds = room.players.keys.toList();
    playerIds.shuffle();
    String killerId = playerIds.first;

    Map<String, dynamic> updates = {};
    for (String pid in playerIds) {
      String role = pid == killerId ? 'killer' : 'survivor';
      double startX = 200 + Random().nextInt(400).toDouble();
      double startY = 200 + Random().nextInt(300).toDouble();
      updates['rooms/$roomId/players/$pid/role'] = role;
      updates['rooms/$roomId/players/$pid/x'] = startX;
      updates['rooms/$roomId/players/$pid/y'] = startY;
      updates['rooms/$roomId/players/$pid/health'] = 100;
      updates['rooms/$roomId/players/$pid/isAlive'] = true;
    }
    updates['rooms/$roomId/status'] = 'playing';
    await _db.ref().update(updates);
  }

  Future<void> updatePosition(String roomId, String uid, double x, double y) async {
    await _db.ref('rooms/$roomId/players/$uid').update({'x': x, 'y': y});
  }

  Future<void> attackPlayer(String roomId, String targetUid, int damage) async {
    DataSnapshot snap = await _db.ref('rooms/$roomId/players/$targetUid/health').get();
    int currentHealth = (snap.value as int? ?? 100);
    int newHealth = (currentHealth - damage).clamp(0, 100);
    await _db.ref('rooms/$roomId/players/$targetUid').update({
      'health': newHealth,
      'isAlive': newHealth > 0,
    });
    if (newHealth <= 0) await checkWinCondition(roomId);
  }

  Future<void> completeTask(String roomId, String uid) async {
    DataSnapshot snap = await _db.ref('rooms/$roomId/players/$uid/tasksCompleted').get();
    int done = (snap.value as int? ?? 0) + 1;
    await _db.ref('rooms/$roomId/players/$uid').update({'tasksCompleted': done});
    await checkWinCondition(roomId);
  }

  Future<void> checkWinCondition(String roomId) async {
    DataSnapshot snap = await _db.ref('rooms/$roomId').get();
    if (!snap.exists) return;
    RoomModel room = RoomModel.fromMap(snap.value as Map);

    List<PlayerModel> survivors = room.players.values.where((p) => p.role == 'survivor').toList();
    bool allDead = survivors.every((p) => !p.isAlive);
    bool allTasksDone = survivors.every((p) => p.tasksCompleted >= p.totalTasks);

    if (allDead) {
      await _db.ref('rooms/$roomId').update({'status': 'finished', 'winnerRole': 'killer'});
    } else if (allTasksDone) {
      await _db.ref('rooms/$roomId').update({'status': 'finished', 'winnerRole': 'survivors'});
    }
  }

  Stream<RoomModel?> streamRoom(String roomId) {
    return _db.ref('rooms/$roomId').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return RoomModel.fromMap(event.snapshot.value as Map);
    });
  }

  Future<void> deleteRoom(String roomId) async {
    await _db.ref('rooms/$roomId').remove();
  }
}
