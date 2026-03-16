import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/room_model.dart';
import '../widgets/horror_crewmate.dart';
import 'home_screen.dart';

class GameOverScreen extends StatefulWidget {
  final String winnerRole;
  final String myRole;
  final RoomModel room;
  const GameOverScreen({super.key, required this.winnerRole, required this.myRole, required this.room});
  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool get _iWon => widget.winnerRole == widget.myRole ||
      (widget.myRole == 'survivor' && widget.winnerRole == 'survivors');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    context.read<AuthService>().updateStats(won: _iWon);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated crewmate result
                AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (ctx, child) => Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: (_iWon ? Colors.green : Colors.red).withOpacity(0.4),
                          blurRadius: 60, spreadRadius: 10,
                        )],
                      ),
                      child: _iWon
                          ? const HorrorCrewmate(bodyColor: Color(0xFF006400), size: 130)
                          : const GhostCrewmate(bodyColor: Colors.white70, size: 130),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _iWon ? 'VICTORY!' : 'DEFEATED',
                  style: TextStyle(
                    color: _iWon ? Colors.green : Colors.red,
                    fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 6,
                    shadows: [Shadow(color: _iWon ? Colors.green : Colors.red, blurRadius: 20)],
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  widget.winnerRole == 'hunter'
                      ? 'The Hunter eliminated all survivors!'
                      : 'The Survivors completed all tasks and escaped!',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Show row of crewmates
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HorrorCrewmate(bodyColor: Color(0xFF8B0000), isHunter: true, size: 55),
                    const SizedBox(width: 8),
                    ...[ const Color(0xFF003399), const Color(0xFF006400), const Color(0xFF4B0082)]
                        .map((c) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GhostCrewmate(bodyColor: c, size: 45),
                            ))
                        .toList(),
                  ],
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: [
                    _statRow('Your Role', widget.myRole.toUpperCase(), Colors.white),
                    const Divider(color: Colors.white12),
                    _statRow('Winner', widget.winnerRole.toUpperCase(), _iWon ? Colors.green : Colors.red),
                    const Divider(color: Colors.white12),
                    _statRow('Players', '${widget.room.players.length}', Colors.white54),
                  ]),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('BACK TO MAIN MENU',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }
}
