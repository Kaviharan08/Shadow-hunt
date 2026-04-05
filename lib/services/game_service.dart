import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';

class GameService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  String _code() {
    const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => c[Random().nextInt(c.length)]).join();
  }

  Future<String> createRoom(String hostUid, String username, bool isSolo, String hunterType) async {
    final roomId = _code();
    final room = RoomModel(
      roomId: roomId,
      hostUid: hostUid,
      isSoloMode: isSolo,
      maxPlayers: isSolo ? 1 : 4,
      round: 1,
      phase: 'waiting',
    );
    final host = PlayerModel(uid: hostUid, username: username, hunterType: hunterType, x: 600, y: 600);
    room.players[hostUid] = host;
    await _db.ref('rooms/$roomId').set(room.toMap());
    return roomId;
  }

  Future<bool> joinRoom(String roomId, String uid, String username, String hunterType) async {
    try {
      final snap = await _db.ref('rooms/$roomId').get();
      if (!snap.exists) return false;
      final room = RoomModel.fromMap(snap.value as Map);
      if (room.status != 'waiting') return false;
      if (room.players.length >= room.maxPlayers) return false;
      final player = PlayerModel(
        uid: uid,
        username: username,
        hunterType: hunterType,
        x: 300 + Random().nextInt(500).toDouble(),
        y: 300 + Random().nextInt(400).toDouble(),
      );
      await _db.ref('rooms/$roomId/players/$uid').set(player.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> startGame(String roomId, RoomModel room) async {
    final ids = room.players.keys.toList()..shuffle();
    final killerId = ids.first;
    final updates = <String, dynamic>{
      'rooms/$roomId/status': 'playing',
      'rooms/$roomId/phase': 'round1',
      'rooms/$roomId/round': 1,
      'rooms/$roomId/winnerRole': null,
      'rooms/$roomId/portalDeadlineMs': null,
    };
    for (final pid in ids) {
      updates['rooms/$roomId/players/$pid/role'] = pid == killerId ? 'killer' : 'survivor';
      updates['rooms/$roomId/players/$pid/x'] = 200 + Random().nextInt(800).toDouble();
      updates['rooms/$roomId/players/$pid/y'] = 200 + Random().nextInt(600).toDouble();
      updates['rooms/$roomId/players/$pid/health'] = 100;
      updates['rooms/$roomId/players/$pid/isAlive'] = true;
      updates['rooms/$roomId/players/$pid/tasksCompleted'] = 0;
      updates['rooms/$roomId/players/$pid/totalTasks'] = pid == killerId ? 0 : 3;
      updates['rooms/$roomId/players/$pid/isInvisible'] = false;
      updates['rooms/$roomId/players/$pid/portalEntered'] = false;
    }
    await _db.ref().update(updates);
  }

  Future<void> startGameWithRole(String roomId, RoomModel room, String playerUid, String playerRole) async {
    final updates = <String, dynamic>{
      'rooms/$roomId/players/$playerUid/role': playerRole,
      'rooms/$roomId/players/$playerUid/x': 400 + Random().nextInt(200).toDouble(),
      'rooms/$roomId/players/$playerUid/y': 400 + Random().nextInt(200).toDouble(),
      'rooms/$roomId/players/$playerUid/health': 100,
      'rooms/$roomId/players/$playerUid/isAlive': true,
      'rooms/$roomId/players/$playerUid/tasksCompleted': 0,
      'rooms/$roomId/players/$playerUid/portalEntered': false,
      'rooms/$roomId/players/$playerUid/isInvisible': false,
      'rooms/$roomId/status': 'playing',
      'rooms/$roomId/phase': 'round1',
      'rooms/$roomId/round': 1,
      'rooms/$roomId/winnerRole': null,
    };
    await _db.ref().update(updates);
  }

  Future<void> updatePosition(String roomId, String uid, double x, double y) async {
    await _db.ref('rooms/$roomId/players/$uid').update({'x': x, 'y': y});
  }

  Future<void> updateHealth(String roomId, String uid, int health) async {
    await _db.ref('rooms/$roomId/players/$uid').update({'health': health, 'isAlive': health > 0});
    await checkWinCondition(roomId);
  }

  Future<void> updateInvisibility(String roomId, String uid, bool isInvisible) async {
    await _db.ref('rooms/$roomId/players/$uid/isInvisible').set(isInvisible);
  }

  Future<void> attackPlayer(String roomId, String targetUid, int damage) async {
    final playerSnap = await _db.ref('rooms/$roomId/players/$targetUid').get();
    if (!playerSnap.exists) return;
    final player = PlayerModel.fromMap(playerSnap.value as Map);
    if (player.isInvisible || !player.isAlive) return;
    final int newHp = (player.health - damage).clamp(0, 100).toInt();
    await _db.ref('rooms/$roomId/players/$targetUid').update({'health': newHp, 'isAlive': newHp > 0});
    if (newHp <= 0) await checkWinCondition(roomId);
  }

  Future<void> completeTask(String roomId, String uid) async {
    final roomSnap = await _db.ref('rooms/$roomId').get();
    if (!roomSnap.exists) return;
    final room = RoomModel.fromMap(roomSnap.value as Map);
    final player = room.players[uid];
    if (player == null) return;
    final done = player.tasksCompleted + 1;
    await _db.ref('rooms/$roomId/players/$uid').update({'tasksCompleted': done});
    await checkWinCondition(roomId);
  }

  Future<void> enterPortal(String roomId, String uid) async {
    await _db.ref('rooms/$roomId/players/$uid/portalEntered').set(true);
    await checkPortalProgress(roomId);
  }

  Future<void> checkPortalProgress(String roomId) async {
    final snap = await _db.ref('rooms/$roomId').get();
    if (!snap.exists) return;
    final room = RoomModel.fromMap(snap.value as Map);
    if (room.phase != 'portal') return;

    final survivors = room.players.values.where((p) => p.role == 'survivor' && p.isAlive).toList();
    final entered = survivors.where((p) => p.portalEntered).toList();
    final deadline = room.portalDeadlineMs ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (survivors.isNotEmpty && entered.length == survivors.length) {
      await startRoundTwo(roomId, room);
      return;
    }

    if (deadline > 0 && now >= deadline) {
      final updates = <String, dynamic>{};
      for (final s in survivors.where((p) => !p.portalEntered)) {
        updates['rooms/$roomId/players/${s.uid}/health'] = 0;
        updates['rooms/$roomId/players/${s.uid}/isAlive'] = false;
      }
      if (updates.isNotEmpty) {
        await _db.ref().update(updates);
      }
      final refreshedSnap = await _db.ref('rooms/$roomId').get();
      final refreshed = RoomModel.fromMap(refreshedSnap.value as Map);
      final aliveEntered = refreshed.players.values.where((p) => p.role == 'survivor' && p.isAlive && p.portalEntered).toList();
      if (aliveEntered.isEmpty) {
        await _db.ref('rooms/$roomId').update({'status': 'finished', 'phase': 'finished', 'winnerRole': 'killer'});
      } else {
        await startRoundTwo(roomId, refreshed);
      }
    }
  }

  Future<void> startRoundTwo(String roomId, RoomModel room) async {
    final aliveSurvivors = room.players.values.where((p) => p.role == 'survivor' && p.isAlive && p.portalEntered).toList();
    final int taskCount = (aliveSurvivors.length + 3).clamp(4, 8).toInt();
    final updates = <String, dynamic>{
      'rooms/$roomId/status': 'playing',
      'rooms/$roomId/phase': 'round2',
      'rooms/$roomId/round': 2,
      'rooms/$roomId/portalDeadlineMs': null,
    };

    for (final p in room.players.values) {
      final spawnX = 150 + Random().nextInt(1000).toDouble();
      final spawnY = 150 + Random().nextInt(850).toDouble();
      updates['rooms/$roomId/players/${p.uid}/x'] = spawnX;
      updates['rooms/$roomId/players/${p.uid}/y'] = spawnY;
      updates['rooms/$roomId/players/${p.uid}/tasksCompleted'] = 0;
      updates['rooms/$roomId/players/${p.uid}/portalEntered'] = false;
      updates['rooms/$roomId/players/${p.uid}/isInvisible'] = false;
      if (p.role == 'survivor') {
        updates['rooms/$roomId/players/${p.uid}/totalTasks'] = taskCount;
        if (!p.isAlive || !p.portalEntered) {
          updates['rooms/$roomId/players/${p.uid}/health'] = 0;
          updates['rooms/$roomId/players/${p.uid}/isAlive'] = false;
        } else {
          updates['rooms/$roomId/players/${p.uid}/health'] = (p.health + 15).clamp(1, 100).toInt();
          updates['rooms/$roomId/players/${p.uid}/isAlive'] = true;
        }
      }
    }
    await _db.ref().update(updates);
  }

  Future<void> checkWinCondition(String roomId) async {
    final snap = await _db.ref('rooms/$roomId').get();
    if (!snap.exists) return;
    final room = RoomModel.fromMap(snap.value as Map);
    final survivors = room.players.values.where((p) => p.role == 'survivor').toList();
    final aliveSurvivors = survivors.where((p) => p.isAlive).toList();

    if (aliveSurvivors.isEmpty) {
      await _db.ref('rooms/$roomId').update({'status': 'finished', 'phase': 'finished', 'winnerRole': 'killer'});
      return;
    }

    if (room.round == 1) {
      if (aliveSurvivors.every((p) => p.tasksCompleted >= p.totalTasks)) {
        final deadline = DateTime.now().millisecondsSinceEpoch + const Duration(minutes: 2).inMilliseconds;
        final updates = <String, dynamic>{
          'rooms/$roomId/status': 'portal',
          'rooms/$roomId/phase': 'portal',
          'rooms/$roomId/portalDeadlineMs': deadline,
          'rooms/$roomId/winnerRole': null,
        };
        for (final s in aliveSurvivors) {
          updates['rooms/$roomId/players/${s.uid}/portalEntered'] = false;
        }
        await _db.ref().update(updates);
      }
      return;
    }

    if (aliveSurvivors.every((p) => p.tasksCompleted >= p.totalTasks)) {
      await _db.ref('rooms/$roomId').update({'status': 'finished', 'phase': 'finished', 'winnerRole': 'survivors'});
    }
  }

  Stream<RoomModel?> streamRoom(String roomId) => _db.ref('rooms/$roomId').onValue.map((e) => e.snapshot.exists ? RoomModel.fromMap(e.snapshot.value as Map) : null);

  Future<void> deleteRoom(String roomId) async => _db.ref('rooms/$roomId').remove();
}
