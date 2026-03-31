import 'package:firebase_database/firebase_database.dart';
import '../models/room_model.dart';
import '../models/player_model.dart';
import 'dart:math';

class GameService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<String> createRoom(String hostUid, String username,
      bool isSolo, String hunterType) async {
    String roomId = _generateCode();
    RoomModel room = RoomModel(
        roomId: roomId, hostUid: hostUid,
        isSoloMode: isSolo, maxPlayers: isSolo ? 1 : 4);
    PlayerModel host = PlayerModel(
        uid: hostUid, username: username,
        hunterType: hunterType, x: 600, y: 600);
    room.players[hostUid] = host;
    await _db.ref('rooms/$roomId').set(room.toMap());
    return roomId;
  }

  Future<bool> joinRoom(String roomId, String uid, String username, String hunterType) async {
    try {
      final snap = await _db.ref('rooms/$roomId').get();
      if (!snap.exists) return false;
      RoomModel room = RoomModel.fromMap(snap.value as Map);
      if (room.status != 'waiting') return false;
      if (room.players.length >= room.maxPlayers) return false;
      PlayerModel player = PlayerModel(
          uid: uid, username: username, hunterType: hunterType,
          x: 300 + Random().nextInt(400).toDouble(),
          y: 300 + Random().nextInt(300).toDouble());
      await _db.ref('rooms/$roomId/players/$uid').set(player.toMap());
      return true;
    } catch (_) { return false; }
  }

  Future<void> startGame(String roomId, RoomModel room) async {
    List<String> ids = room.players.keys.toList()..shuffle();
    String killerId = ids.first;
    Map<String, dynamic> updates = {};
    for (String pid in ids) {
      updates['rooms/$roomId/players/$pid/role'] =
          pid == killerId ? 'killer' : 'survivor';
      updates['rooms/$roomId/players/$pid/x'] =
          200 + Random().nextInt(800).toDouble();
      updates['rooms/$roomId/players/$pid/y'] =
          200 + Random().nextInt(600).toDouble();
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
    final snap = await _db.ref('rooms/$roomId/players/$targetUid/health').get();
    int current = (snap.value as int? ?? 100);
    int newHp = (current - damage).clamp(0, 100);
    await _db.ref('rooms/$roomId/players/$targetUid')
        .update({'health': newHp, 'isAlive': newHp > 0});
    if (newHp <= 0) await checkWinCondition(roomId);
  }

  Future<void> completeTask(String roomId, String uid) async {
    final snap = await _db.ref('rooms/$roomId/players/$uid/tasksCompleted').get();
    int done = (snap.value as int? ?? 0) + 1;
    await _db.ref('rooms/$roomId/players/$uid').update({'tasksCompleted': done});
    await checkWinCondition(roomId);
  }

  Future<void> checkWinCondition(String roomId) async {
    final snap = await _db.ref('rooms/$roomId').get();
    if (!snap.exists) return;
    RoomModel room = RoomModel.fromMap(snap.value as Map);
    List<PlayerModel> survivors =
        room.players.values.where((p) => p.role == 'survivor').toList();
    if (survivors.every((p) => !p.isAlive))
      await _db.ref('rooms/$roomId')
          .update({'status': 'finished', 'winnerRole': 'killer'});
    else if (survivors.every((p) => p.tasksCompleted >= p.totalTasks))
      await _db.ref('rooms/$roomId')
          .update({'status': 'finished', 'winnerRole': 'survivors'});
  }

  Stream<RoomModel?> streamRoom(String roomId) =>
      _db.ref('rooms/$roomId').onValue.map((e) =>
          e.snapshot.exists ? RoomModel.fromMap(e.snapshot.value as Map) : null);

  Future<void> deleteRoom(String roomId) async =>
      await _db.ref('rooms/$roomId').remove();
}
