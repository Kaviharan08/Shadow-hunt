import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../models/room_model.dart';
import 'role_screen.dart';

class LobbyScreen extends StatefulWidget {
  final bool isHost;
  const LobbyScreen({super.key, required this.isHost});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final GameService _gameService = GameService();
  final _codeController = TextEditingController();
  RoomModel? _room;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isHost) _createRoom();
  }

  Future<void> _createRoom() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    String username = await auth.getUsername();
    RoomModel? room = await _gameService.createRoom(
        auth.currentUser!.uid, username);
    if (room != null) {
      setState(() { _room = room; _loading = false; });
      _listenToRoom(room.roomId);
    }
  }

  Future<void> _joinRoom() async {
    if (_codeController.text.length < 6) return;
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    String username = await auth.getUsername();
    RoomModel? room = await _gameService.joinRoom(
        _codeController.text.toUpperCase(),
        auth.currentUser!.uid,
        username);
    if (room != null) {
      setState(() { _room = room; _loading = false; });
      _listenToRoom(room.roomId);
    } else {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room not found or full!')));
      }
    }
  }

  void _listenToRoom(String roomId) {
    _gameService.streamRoom(roomId).listen((room) {
      if (room == null) return;
      setState(() => _room = room);

      if (room.status == 'playing') {
        final auth = context.read<AuthService>();
        String myUid = auth.currentUser!.uid;
        String myRole = room.players[myUid]?.role ?? 'survivor';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleScreen(
              room: room,
              myUid: myUid,
              myRole: myRole,
            ),
          ),
        );
      }
    });
  }

  Future<void> _startGame() async {
    if (_room == null || _room!.players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Need at least 2 players!')));
      return;
    }
    await _gameService.startGame(_room!.roomId, _room!.players);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.isHost ? 'Create Room' : 'Join Room',
            style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : _room == null
                ? _buildJoinForm()
                : _buildLobbyView(),
      ),
    );
  }

  Widget _buildJoinForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.meeting_room, color: Colors.red, size: 60),
        const SizedBox(height: 24),
        const Text('Enter Room Code',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
              color: Colors.white, fontSize: 24, letterSpacing: 8),
          textAlign: TextAlign.center,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'XXXXXX',
            hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _joinRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('JOIN ROOM',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildLobbyView() {
    final auth = context.read<AuthService>();
    bool isHost = _room!.hostUid == auth.currentUser!.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room code display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0000),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              const Text('ROOM CODE',
                  style: TextStyle(color: Colors.white54, letterSpacing: 4)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_room!.roomCode,
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12)),
                  IconButton(
                    onPressed: () => Clipboard.setData(
                        ClipboardData(text: _room!.roomCode)),
                    icon: const Icon(Icons.copy, color: Colors.white54),
                  ),
                ],
              ),
              const Text('Share this code with your friends',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('PLAYERS (${_room!.players.length}/${_room!.maxPlayers})',
            style: const TextStyle(
                color: Colors.white54, letterSpacing: 3, fontSize: 13)),
        const SizedBox(height: 12),

        // Player list
        Expanded(
          child: ListView.builder(
            itemCount: _room!.players.length,
            itemBuilder: (ctx, i) {
              final player = _room!.players.values.toList()[i];
              bool isCurrentHost = player.uid == _room!.hostUid;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person,
                        color: isCurrentHost ? Colors.red : Colors.white54),
                    const SizedBox(width: 12),
                    Text(player.username,
                        style: const TextStyle(color: Colors.white)),
                    if (isCurrentHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('HOST',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                letterSpacing: 1)),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.circle, color: Colors.green, size: 10),
                  ],
                ),
              );
            },
          ),
        ),

        if (isHost)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('START GAME',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
          )
        else
          const Center(
            child: Text('Waiting for host to start...',
                style: TextStyle(color: Colors.white54)),
          ),
      ],
    );
  }
}
