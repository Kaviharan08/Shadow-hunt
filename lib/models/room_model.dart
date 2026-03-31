import 'player_model.dart';

class RoomModel {
  final String roomId;
  final String hostUid;
  String status; // 'waiting', 'playing', 'finished'
  Map<String, PlayerModel> players;
  String? winnerRole;
  bool isSoloMode;
  int maxPlayers;

  RoomModel({
    required this.roomId,
    required this.hostUid,
    this.status = 'waiting',
    Map<String, PlayerModel>? players,
    this.winnerRole,
    this.isSoloMode = false,
    this.maxPlayers = 4,
  }) : players = players ?? {};

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'hostUid': hostUid,
        'status': status,
        'players': players.map((k, v) => MapEntry(k, v.toMap())),
        'winnerRole': winnerRole,
        'isSoloMode': isSoloMode,
        'maxPlayers': maxPlayers,
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
      );
}
