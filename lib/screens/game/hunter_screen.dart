import 'package:flutter/material.dart';
import '../../models/room_model.dart';
import '../../models/player_model.dart';
import '../../services/game_service.dart';
import '../../widgets/horror_crewmate.dart';
import '../gameover_screen.dart';

class HunterScreen extends StatefulWidget {
  final RoomModel room;
  final String myUid;
  const HunterScreen({super.key, required this.room, required this.myUid});
  @override
  State<HunterScreen> createState() => _HunterScreenState();
}

class _HunterScreenState extends State<HunterScreen> with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  late AnimationController _pulseController;
  RoomModel? _currentRoom;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _gameService.streamRoom(widget.room.roomId).listen((room) {
      if (room == null) return;
      setState(() => _currentRoom = room);
      if (room.status == 'finished') {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => GameOverScreen(winnerRole: room.winnerRole ?? 'survivors', myRole: 'hunter', room: room),
        ));
      }
    });
  }

  Future<void> _catchPlayer(String targetUid) async {
    await _gameService.catchPlayer(widget.room.roomId, targetUid);
    if (_currentRoom != null) await _gameService.checkWinCondition(widget.room.roomId, _currentRoom!);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🩸 Survivor caught!'), backgroundColor: Colors.red));
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    RoomModel room = _currentRoom ?? widget.room;
    List<PlayerModel> survivors = room.players.values.where((p) => p.role == 'survivor').toList();
    List<PlayerModel> aliveSurvivors = survivors.where((p) => p.isAlive).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hunter header with crewmate
              AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, child) => Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.lerp(const Color(0xFF8B0000), const Color(0xFF4A0000), _pulseController.value),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const HorrorCrewmate(bodyColor: Color(0xFF8B0000), isHunter: true, size: 60),
                    const SizedBox(width: 12),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('YOU ARE THE HUNTER', style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
                      Text('Catch all survivors!', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              Row(children: [
                _statBox('ALIVE', '${aliveSurvivors.length}', Colors.green),
                const SizedBox(width: 12),
                _statBox('CAUGHT', '${survivors.length - aliveSurvivors.length}', Colors.red),
                const SizedBox(width: 12),
                _statBox('TOTAL', '${survivors.length}', Colors.white54),
              ]),

              const SizedBox(height: 24),
              const Text('TAP TO CATCH A SURVIVOR',
                  style: TextStyle(color: Colors.white54, letterSpacing: 3, fontSize: 12)),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: survivors.length,
                  itemBuilder: (ctx, i) {
                    final survivor = survivors[i];
                    return GestureDetector(
                      onTap: survivor.isAlive ? () => _showCatchDialog(survivor) : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: survivor.isAlive ? const Color(0xFF1A0000) : const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: survivor.isAlive ? Colors.red.withOpacity(0.4) : Colors.white12),
                        ),
                        child: Row(children: [
                          survivor.isAlive
                              ? HorrorCrewmate(
                                  bodyColor: [const Color(0xFF003399), const Color(0xFF006400),
                                    const Color(0xFF4B0082), const Color(0xFF8B4513)][i % 4],
                                  size: 55)
                              : GhostCrewmate(
                                  bodyColor: [const Color(0xFF003399), const Color(0xFF006400),
                                    const Color(0xFF4B0082), const Color(0xFF8B4513)][i % 4],
                                  size: 55),
                          const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(survivor.username, style: TextStyle(
                              color: survivor.isAlive ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              survivor.isAlive ? '${survivor.tasksCompleted} tasks done' : 'CAUGHT 🩸',
                              style: TextStyle(color: survivor.isAlive ? Colors.white38 : Colors.red, fontSize: 12)),
                          ]),
                          const Spacer(),
                          if (survivor.isAlive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFF8B0000), borderRadius: BorderRadius.circular(8)),
                              child: const Text('CATCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCatchDialog(PlayerModel survivor) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A0000),
      title: const Text('Catch Survivor?', style: TextStyle(color: Colors.white)),
      content: Row(children: [
        HorrorCrewmate(bodyColor: const Color(0xFF003399), size: 60),
        const SizedBox(width: 12),
        Text('Catch ${survivor.username}?', style: const TextStyle(color: Colors.white70)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); _catchPlayer(survivor.uid); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
          child: const Text('CATCH 🩸', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
    );
  }
}
