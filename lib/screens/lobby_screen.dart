import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../models/room_model.dart';
import '../widgets/horror_bg.dart';
import '../widgets/forest_map.dart';
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
  String _soloRole = 'killer';

  Future<void> _pickHunterType() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => HunterSelectScreen(isSolo: widget.isSolo),
      ),
    );
    if (result != null) setState(() => _hunterType = result);
  }

  Future<void> _createRoom() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final username = await auth.getUsername();
    final roomId = await _gs.createRoom(
      auth.uid,
      username,
      widget.isSolo,
      _hunterType,
    );
    setState(() {
      _roomId = roomId;
      _isHost = true;
      _loading = false;
    });
    _listen(roomId);
    if (widget.isSolo) {
      await Future.delayed(const Duration(milliseconds: 500));
      final snap = await _gs.streamRoom(roomId).first;
      if (snap != null && mounted) {
        await _gs.startGameWithRole(roomId, snap, auth.uid, _soloRole);
      }
    }
  }

  Future<void> _joinRoom() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final username = await auth.getUsername();
    final ok = await _gs.joinRoom(
      _codeCtrl.text.trim().toUpperCase(),
      auth.uid,
      username,
      _hunterType,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _error = 'Room not found or full';
        _loading = false;
      });
    } else {
      setState(() {
        _roomId = _codeCtrl.text.trim().toUpperCase();
        _isHost = false;
        _loading = false;
      });
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(room: room, myUid: uid, isSolo: widget.isSolo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: HorrorBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ToxicTheme.bg.withOpacity(0.18),
                        ToxicTheme.bgDark.withOpacity(0.35),
                        Colors.black.withOpacity(0.18),
                      ],
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 18),
                    if (_roomId == null) ...[
                      _topBanner(),
                      const SizedBox(height: 16),
                      if (widget.isSolo) ...[
                        _sectionTitle('SELECT ROLE'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _roleBtn('killer', 'HUNTER', 'Lead the chase'),
                            const SizedBox(width: 12),
                            _roleBtn('survivor', 'SURVIVOR', 'Solve and escape'),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      _sectionTitle('PLAYER TYPE'),
                      const SizedBox(height: 10),
                      _glassTile(
                        onTap: _pickHunterType,
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [ToxicTheme.purple, ToxicTheme.cyan],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ToxicTheme.purple.withOpacity(0.35),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.auto_awesome, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CURRENT HUNTER',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      letterSpacing: 2.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _hunterType.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '[ CHANGE ]',
                              style: TextStyle(
                                color: ToxicTheme.cyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _actionBtn(
                        label: widget.isSolo ? 'CREATE SOLO MATCH' : 'CREATE ROOM',
                        onTap: _loading ? null : _createRoom,
                      ),
                      if (!widget.isSolo) ...[
                        const SizedBox(height: 16),
                        _sectionDivider(),
                        const SizedBox(height: 16),
                        _sectionTitle('ROOM CODE'),
                        const SizedBox(height: 10),
                        _codeField(),
                        const SizedBox(height: 12),
                        _actionBtn(
                          label: 'JOIN ROOM',
                          onTap: _loading ? null : _joinRoom,
                          secondary: true,
                        ),
                      ],
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: ToxicTheme.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ToxicTheme.cyan,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                    ] else ...[
                      if (!widget.isSolo) ...[
                        _sectionTitle('ROOM CODE'),
                        const SizedBox(height: 10),
                        _roomCodeCard(),
                        const SizedBox(height: 16),
                      ],
                      _sectionTitle('CONNECTED PLAYERS'),
                      const SizedBox(height: 10),
                      ...?_room?.players.values.map(_playerTile),
                      const SizedBox(height: 18),
                      if (_isHost && !widget.isSolo && (_room?.players.length ?? 0) >= 2)
                        _actionBtn(
                          label: 'START MATCH',
                          onTap: () => _gs.startGame(_roomId!, _room!),
                        ),
                      if (!_isHost)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              'WAITING FOR HOST TO START',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isSolo ? 'SOLO VS BOTS' : 'ONLINE GAME',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            Text(
              widget.isSolo ? 'Create a local nightmare run' : 'Create or join a cosmic room',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _topBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        gradient: LinearGradient(
          colors: [
            ToxicTheme.purple.withOpacity(0.28),
            ToxicTheme.cyan.withOpacity(0.16),
            Colors.black.withOpacity(0.25),
          ],
        ),
        boxShadow: [
          BoxShadow(color: ToxicTheme.cyan.withOpacity(0.18), blurRadius: 24),
        ],
      ),
      child: Row(
        children: [
          HunterPortrait(hunterType: _hunterType, size: 90, isSelected: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MATCH CONFIG',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isSolo
                      ? 'Forge a solo round with cinematic neon style.'
                      : 'Build a room and pull your squad into the next hunt.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
        letterSpacing: 3,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _sectionDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
      ],
    );
  }

  Widget _glassTile({required Widget child, VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF111A2E).withOpacity(0.85),
            const Color(0xFF0C1324).withOpacity(0.72),
            const Color(0xFF1B1430).withOpacity(0.72),
          ],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: content);
  }

  Widget _codeField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            ToxicTheme.cyan.withOpacity(0.24),
            ToxicTheme.purple.withOpacity(0.18),
          ],
        ),
        boxShadow: [BoxShadow(color: ToxicTheme.cyan.withOpacity(0.22), blurRadius: 24)],
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF09111F).withOpacity(0.92),
        ),
        child: TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            color: Colors.white,
            letterSpacing: 8,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: 'ROOM CODE',
            hintStyle: TextStyle(
              color: Colors.white38,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          ),
        ),
      ),
    );
  }

  Widget _roomCodeCard() {
    return _glassTile(
      child: Column(
        children: [
          Text(
            _roomId ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _roomId!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Room code copied')), 
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(colors: [ToxicTheme.purple, ToxicTheme.cyan]),
              ),
              child: const Text(
                'COPY CODE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerTile(player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        color: const Color(0xFF0A1020).withOpacity(0.82),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [ToxicTheme.purple, ToxicTheme.cyan]),
              boxShadow: [BoxShadow(color: ToxicTheme.purple.withOpacity(0.2), blurRadius: 14)],
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  player.hunterType.toUpperCase(),
                  style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.6),
                ),
              ],
            ),
          ),
          if (player.uid == _room?.hostUid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(colors: [ToxicTheme.cyan.withOpacity(0.22), ToxicTheme.purple.withOpacity(0.18)]),
              ),
              child: const Text(
                'HOST',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roleBtn(String role, String label, String sub) {
    final selected = _soloRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _soloRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? ToxicTheme.cyan : Colors.white.withOpacity(0.12),
              width: selected ? 1.8 : 1,
            ),
            gradient: LinearGradient(
              colors: selected
                  ? [ToxicTheme.purple.withOpacity(0.26), ToxicTheme.cyan.withOpacity(0.18)]
                  : [const Color(0xFF10172A).withOpacity(0.85), const Color(0xFF0A1020).withOpacity(0.70)],
            ),
            boxShadow: selected
                ? [BoxShadow(color: ToxicTheme.cyan.withOpacity(0.18), blurRadius: 18)]
                : [],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                sub,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({required String label, VoidCallback? onTap, bool secondary = false}) {
    final colors = secondary
        ? [const Color(0xFF121C32), const Color(0xFF1A1230)]
        : [ToxicTheme.cyan, ToxicTheme.purple];
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: (secondary ? ToxicTheme.purple : ToxicTheme.cyan).withOpacity(0.28),
            blurRadius: 22,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
