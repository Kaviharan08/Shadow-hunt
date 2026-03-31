import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../models/room_model.dart';
import 'hunter_select_screen.dart';
import 'game/game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final bool isSolo;
  const LobbyScreen({super.key, required this.isSolo});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final GameService _gs = GameService();
  final _codeCtrl = TextEditingController();
  String? _roomId;
  RoomModel? _room;
  bool _loading = false;
  String? _error;
  bool _isHost = false;
  String _hunterType = 'stalker';

  Future<void> _pickHunterType() async {
    final result = await Navigator.push<String>(context,
        MaterialPageRoute(builder: (_) => HunterSelectScreen(isSolo: widget.isSolo)));
    if (result != null) setState(() => _hunterType = result);
  }

  Future<void> _createRoom() async {
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthService>();
    final username = await auth.getUsername();
    final roomId = await _gs.createRoom(auth.uid, username, widget.isSolo, _hunterType);
    setState(() { _roomId = roomId; _isHost = true; _loading = false; });
    _listen(roomId);
    if (widget.isSolo) {
      await Future.delayed(const Duration(milliseconds: 600));
      final snap = await _gs.streamRoom(roomId).first;
      if (snap != null && mounted) await _gs.startGame(roomId, snap);
    }
  }

  Future<void> _joinRoom() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthService>();
    final username = await auth.getUsername();
    final ok = await _gs.joinRoom(
        _codeCtrl.text.trim().toUpperCase(), auth.uid, username, _hunterType);
    if (!mounted) return;
    if (!ok) {
      setState(() { _error = 'Room not found or full'; _loading = false; });
    } else {
      setState(() { _roomId = _codeCtrl.text.trim().toUpperCase(); _isHost = false; _loading = false; });
      _listen(_roomId!);
    }
  }

  void _listen(String roomId) {
    _gs.streamRoom(roomId).listen((room) {
      if (room == null || !mounted) return;
      setState(() => _room = room);
      if (room.status == 'playing') _goGame(room);
    });
  }

  void _goGame(RoomModel room) {
    final uid = context.read<AuthService>().uid;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => GameScreen(room: room, myUid: uid, isSolo: widget.isSolo),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF000000), Color(0xFF050F05)]),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF446644))),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.isSolo ? 'SOLO vs BOTS' : 'ONLINE GAME',
                      style: const TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.bold, letterSpacing: 4)),
                  Text(widget.isSolo ? 'Fight AI hunters' : 'Create or join a room',
                      style: const TextStyle(color: Color(0xFF446644), fontSize: 12)),
                ]),
              ]),
              const SizedBox(height: 20),

              if (_roomId == null) ...[
                // Hunter type picker
                GestureDetector(
                  onTap: _pickHunterType,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B0000).withValues(alpha: 0.5)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.sports_martial_arts, color: Color(0xFF8B0000), size: 20),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('HUNTER TYPE', style: TextStyle(color: Colors.white54,
                            fontSize: 10, letterSpacing: 2)),
                        Text(_hunterType.toUpperCase(), style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 14)),
                      ]),
                      const Spacer(),
                      const Text('CHANGE', style: TextStyle(color: Color(0xFF8B0000),
                          fontSize: 11, letterSpacing: 1)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Color(0xFF8B0000), size: 18),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                _actionBtn(
                  label: widget.isSolo ? 'START SOLO GAME' : 'CREATE ROOM',
                  icon: Icons.add_circle_outline,
                  onTap: _loading ? null : _createRoom,
                ),

                if (!widget.isSolo) ...[
                  const SizedBox(height: 22),
                  const Row(children: [
                    Expanded(child: Divider(color: Color(0xFF1A3A1A))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR', style: TextStyle(color: Color(0xFF334433), fontSize: 12))),
                    Expanded(child: Divider(color: Color(0xFF1A3A1A))),
                  ]),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white, letterSpacing: 5, fontSize: 20),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'ROOM CODE',
                      hintStyle: const TextStyle(color: Color(0xFF334433), letterSpacing: 4),
                      filled: true, fillColor: const Color(0xFF0D1F0D),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1A3A1A))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1A3A1A))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF8B0000), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _actionBtn(label: 'JOIN ROOM', icon: Icons.login, secondary: true,
                      onTap: _loading ? null : _joinRoom),
                ],

                if (_error != null) Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red))),
                if (_loading) const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)))),
              ] else ...[
                // Room created
                if (!widget.isSolo) ...[
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF0D1F0D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1A3A1A))),
                    child: Column(children: [
                      const Text('ROOM CODE', style: TextStyle(color: Color(0xFF446644),
                          letterSpacing: 4, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(_roomId!, style: const TextStyle(color: Colors.white,
                          fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: 10)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _roomId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied!')));
                        },
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.copy, color: Color(0xFF446644), size: 12),
                          SizedBox(width: 4),
                          Text('Copy', style: TextStyle(color: Color(0xFF446644), fontSize: 11)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_room != null) ...[
                  Text('PLAYERS (${_room!.players.length}/${_room!.maxPlayers})',
                      style: const TextStyle(color: Color(0xFF446644), letterSpacing: 3, fontSize: 11)),
                  const SizedBox(height: 10),
                  ..._room!.players.values.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFF0D1F0D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1A3A1A))),
                    child: Row(children: [
                      const Icon(Icons.person, color: Color(0xFF446644), size: 16),
                      const SizedBox(width: 8),
                      Text(p.username, style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text(p.hunterType.toUpperCase(),
                          style: const TextStyle(color: Color(0xFF8B0000), fontSize: 10)),
                      const Spacer(),
                      if (p.uid == _room!.hostUid)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF8B0000).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('HOST', style: TextStyle(color: Color(0xFFCC2222), fontSize: 9))),
                    ]),
                  )),
                ],

                const Spacer(),
                if (_isHost && !widget.isSolo && (_room?.players.length ?? 0) >= 2)
                  _actionBtn(label: 'START GAME', icon: Icons.play_arrow,
                      onTap: () => _gs.startGame(_roomId!, _room!)),
                if (!_isHost)
                  const Center(child: Text('Waiting for host...',
                      style: TextStyle(color: Color(0xFF446644)))),
              ],
            ]),
          ),
        ),
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
            fontWeight: FontWeight.bold, letterSpacing: 2)),
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary ? const Color(0xFF1A3A1A) : const Color(0xFF8B0000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
