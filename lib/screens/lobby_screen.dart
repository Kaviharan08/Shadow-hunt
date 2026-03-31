import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../models/room_model.dart';
import '../models/player_model.dart';
import 'game/game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final bool isSolo;
  const LobbyScreen({super.key, required this.isSolo});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final GameService _gameService = GameService();
  final _codeCtrl = TextEditingController();
  String? _roomId;
  RoomModel? _room;
  bool _loading = false;
  String? _error;
  bool _isHost = false;

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthService>();
    final username = await auth.getUsername();
    final roomId = await _gameService.createRoom(auth.uid, username, widget.isSolo);
    setState(() { _roomId = roomId; _isHost = true; _loading = false; });
    _listenToRoom(roomId);

    if (widget.isSolo) {
      // Start solo game immediately
      await Future.delayed(const Duration(milliseconds: 500));
      final snap = await _gameService.streamRoom(roomId).first;
      if (snap != null && mounted) _startGame(snap);
    }
  }

  Future<void> _joinRoom() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthService>();
    final username = await auth.getUsername();
    final success = await _gameService.joinRoom(
        _codeCtrl.text.trim().toUpperCase(), auth.uid, username);
    if (!mounted) return;
    if (!success) {
      setState(() { _error = 'Room not found or full'; _loading = false; });
    } else {
      setState(() { _roomId = _codeCtrl.text.trim().toUpperCase(); _isHost = false; _loading = false; });
      _listenToRoom(_roomId!);
    }
  }

  void _listenToRoom(String roomId) {
    _gameService.streamRoom(roomId).listen((room) {
      if (room == null || !mounted) return;
      setState(() => _room = room);
      if (room.status == 'playing') _goToGame(room);
    });
  }

  Future<void> _startGame(RoomModel room) async {
    await _gameService.startGame(_roomId!, room);
  }

  void _goToGame(RoomModel room) {
    final myUid = context.read<AuthService>().uid;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => GameScreen(room: room, myUid: myUid, isSolo: widget.isSolo),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF000000), Color(0xFF050F05)]),
          )),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF446644)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isSolo ? 'SOLO vs BOTS' : 'ONLINE GAME',
                    style: const TextStyle(color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.bold, letterSpacing: 4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isSolo ? 'Hunt or survive against AI bots' : 'Create or join a room',
                    style: const TextStyle(color: Color(0xFF446644), fontSize: 13),
                  ),
                  const SizedBox(height: 32),

                  if (_roomId == null) ...[
                    // Create room button
                    _actionBtn(
                      label: widget.isSolo ? 'START SOLO GAME' : 'CREATE ROOM',
                      icon: Icons.add_circle_outline,
                      onTap: _loading ? null : _createRoom,
                    ),
                    if (!widget.isSolo) ...[
                      const SizedBox(height: 24),
                      const Row(children: [
                        Expanded(child: Divider(color: Color(0xFF1A3A1A))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(color: Color(0xFF334433), fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Color(0xFF1A3A1A))),
                      ]),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 18),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'ENTER ROOM CODE',
                          hintStyle: const TextStyle(color: Color(0xFF334433), letterSpacing: 4, fontSize: 14),
                          filled: true, fillColor: const Color(0xFF0D1F0D),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1A3A1A))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1A3A1A))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF8B0000), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _actionBtn(
                        label: 'JOIN ROOM',
                        icon: Icons.login,
                        secondary: true,
                        onTap: _loading ? null : _joinRoom,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF8B0000))),
                      ),
                  ] else ...[
                    // Room created - show code and players
                    if (!widget.isSolo) ...[
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1F0D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1A3A1A)),
                        ),
                        child: Column(children: [
                          const Text('ROOM CODE', style: TextStyle(color: Color(0xFF446644),
                              letterSpacing: 4, fontSize: 11)),
                          const SizedBox(height: 8),
                          Text(_roomId!, style: const TextStyle(color: Colors.white,
                              fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 10)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _roomId!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Room code copied!')));
                            },
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.copy, color: Color(0xFF446644), size: 14),
                              SizedBox(width: 4),
                              Text('Copy code', style: TextStyle(color: Color(0xFF446644), fontSize: 12)),
                            ]),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Players list
                    if (_room != null) ...[
                      Text('PLAYERS (${_room!.players.length}/${_room!.maxPlayers})',
                          style: const TextStyle(color: Color(0xFF446644), letterSpacing: 3, fontSize: 11)),
                      const SizedBox(height: 12),
                      ..._room!.players.values.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1F0D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1A3A1A)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.person, color: Color(0xFF446644), size: 18),
                          const SizedBox(width: 10),
                          Text(p.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (p.uid == _room!.hostUid)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B0000).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('HOST', style: TextStyle(color: Color(0xFFCC2222), fontSize: 10)),
                            ),
                        ]),
                      )),
                    ],

                    const Spacer(),
                    if (_isHost && !widget.isSolo && (_room?.players.length ?? 0) >= 2)
                      _actionBtn(
                        label: 'START GAME',
                        icon: Icons.play_arrow,
                        onTap: () => _startGame(_room!),
                      ),
                    if (!_isHost)
                      const Center(child: Text('Waiting for host to start...',
                          style: TextStyle(color: Color(0xFF446644)))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({required String label, required IconData icon,
      VoidCallback? onTap, bool secondary = false}) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(label, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold, letterSpacing: 3)),
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary ? const Color(0xFF1A3A1A) : const Color(0xFF8B0000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
