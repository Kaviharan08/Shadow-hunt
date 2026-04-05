import 'player_model.dart';

class RoomModel {
  final String roomId;
  final String hostUid;
  String status;
  Map<String, PlayerModel> players;
  String? winnerRole;
  bool isSoloMode;
  int maxPlayers;
  int round;
  String phase;
  int? portalDeadlineMs;

  RoomModel({
    required this.roomId,
    required this.hostUid,
    this.status = 'waiting',
    Map<String, PlayerModel>? players,
    this.winnerRole,
    this.isSoloMode = false,
    this.maxPlayers = 4,
    this.round = 1,
    this.phase = 'waiting',
    this.portalDeadlineMs,
  }) : players = players ?? {};

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'hostUid': hostUid,
        'status': status,
        'players': players.map((k, v) => MapEntry(k, v.toMap())),
        'winnerRole': winnerRole,
        'isSoloMode': isSoloMode,
        'maxPlayers': maxPlayers,
        'round': round,
        'phase': phase,
        'portalDeadlineMs': portalDeadlineMs,
      };

  factory RoomModel.fromMap(Map<dynamic, dynamic> map) => RoomModel(
        roomId: map['roomId'] ?? '',
        hostUid: map['hostUid'] ?? '',
        status: map['status'] ?? 'waiting',
        players: map['players'] != null
            ? (map['players'] as Map).map(
                (k, v) => MapEntry(k.toString(), PlayerModel.fromMap(v)))
            : {},
        winnerRole: map['winnerRole'],
        isSoloMode: map['isSoloMode'] ?? false,
        maxPlayers: map['maxPlayers'] ?? 4,
        round: map['round'] ?? 1,
        phase: map['phase'] ?? 'waiting',
        portalDeadlineMs: map['portalDeadlineMs'],
      );
}
