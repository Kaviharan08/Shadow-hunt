import 'player_model.dart';

class RoomModel {
  final String roomId;
  final String roomCode;
  final String hostUid;
  String status; // 'waiting', 'playing', 'finished'
  Map<String, PlayerModel> players;
  int maxPlayers;
  String? winnerId;
  String? winnerRole; // 'hunter' or 'survivors'

  RoomModel({
    required this.roomId,
    required this.roomCode,
    required this.hostUid,
    this.status = 'waiting',
    Map<String, PlayerModel>? players,
    this.maxPlayers = 6,
    this.winnerId,
    this.winnerRole,
  }) : players = players ?? {};

  factory RoomModel.fromMap(String id, Map<dynamic, dynamic> map) {
    Map<String, PlayerModel> playersMap = {};
    if (map['players'] != null) {
      (map['players'] as Map).forEach((key, value) {
        playersMap[key] = PlayerModel.fromMap(value);
      });
    }
    return RoomModel(
      roomId: id,
      roomCode: map['roomCode'] ?? '',
      hostUid: map['hostUid'] ?? '',
      status: map['status'] ?? 'waiting',
      players: playersMap,
      maxPlayers: map['maxPlayers'] ?? 6,
      winnerId: map['winnerId'],
      winnerRole: map['winnerRole'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomCode': roomCode,
      'hostUid': hostUid,
      'status': status,
      'maxPlayers': maxPlayers,
      'winnerId': winnerId,
      'winnerRole': winnerRole,
    };
  }
}
