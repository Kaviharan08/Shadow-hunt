import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../widgets/horror_crewmate.dart';
import 'game/hunter_screen.dart';
import 'game/survivor_screen.dart';

class RoleScreen extends StatefulWidget {
  final RoomModel room;
  final String myUid;
  final String myRole;
  const RoleScreen({super.key, required this.room, required this.myUid, required this.myRole});
  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    Future.delayed(const Duration(milliseconds: 600), () {
      _controller.forward();
      setState(() => _revealed = true);
    });
    Future.delayed(const Duration(seconds: 5), _goToGame);
  }

  void _goToGame() {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => widget.myRole == 'hunter'
          ? HunterScreen(room: widget.room, myUid: widget.myUid)
          : SurvivorScreen(room: widget.room, myUid: widget.myUid),
    ));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  bool get isHunter => widget.myRole == 'hunter';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('YOUR ROLE IS...', style: TextStyle(color: Colors.white54, letterSpacing: 4, fontSize: 14)),
            const SizedBox(height: 40),
            if (_revealed)
              AnimatedBuilder(
                animation: _controller,
                builder: (ctx, child) => FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: (isHunter ? Colors.red : Colors.blue).withOpacity(0.5),
                              blurRadius: 60, spreadRadius: 15,
                            )],
                          ),
                          child: HorrorCrewmate(
                            bodyColor: isHunter ? const Color(0xFF8B0000) : const Color(0xFF003399),
                            isHunter: isHunter, size: 140,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          isHunter ? '🩸 HUNTER 🩸' : '👤 SURVIVOR',
                          style: TextStyle(
                            color: isHunter ? Colors.red : Colors.blue,
                            fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 4,
                            shadows: [Shadow(color: isHunter ? Colors.red : Colors.blue, blurRadius: 20)],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isHunter ? 'Hunt down all survivors!' : 'Complete tasks and survive!',
                          style: const TextStyle(color: Colors.white60, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
            const Text('YOUR TEAM', style: TextStyle(color: Colors.white30, fontSize: 12, letterSpacing: 3)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Color(0xFF003399), const Color(0xFF006400), const Color(0xFF4B0082), const Color(0xFF8B4513)]
                  .map((color) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: HorrorCrewmate(bodyColor: color, size: 40),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 40),
            const Text('Game starting in 5 seconds...', style: TextStyle(color: Colors.white30, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
