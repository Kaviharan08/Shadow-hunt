import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class GameOverScreen extends StatefulWidget {
  final String winnerRole;
  final String myRole;
  final String killerName;
  const GameOverScreen({
    super.key, required this.winnerRole,
    required this.myRole, required this.killerName,
  });
  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  bool get _iWon =>
      (widget.myRole == 'killer' && widget.winnerRole == 'killer') ||
      (widget.myRole == 'survivor' && widget.winnerRole == 'survivors');

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    context.read<AuthService>().updateStats(won: _iWon);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    Color mainColor = _iWon ? Colors.green : Colors.red;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gradient bg
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center, radius: 1.0,
                colors: [mainColor.withOpacity(0.08), Colors.black],
              ),
            ),
          ),
          // Dark trees at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Opacity(
              opacity: 0.3,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 160),
                painter: _TreesBgPainter(),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (ctx, child) => FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Big animated result
                      Transform.scale(
                        scale: _scale.value,
                        child: Column(children: [
                          Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: mainColor.withOpacity(0.15),
                              border: Border.all(color: mainColor.withOpacity(0.5), width: 2),
                              boxShadow: [BoxShadow(color: mainColor.withOpacity(0.3),
                                  blurRadius: 50, spreadRadius: 10)],
                            ),
                            child: Icon(
                              _iWon ? Icons.emoji_events : Icons.skull,
                              color: mainColor, size: 64,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _iWon ? 'VICTORY!' : 'DEFEATED',
                            style: TextStyle(
                              color: mainColor, fontSize: 44,
                              fontWeight: FontWeight.bold, letterSpacing: 6,
                              shadows: [Shadow(color: mainColor, blurRadius: 20)],
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        widget.winnerRole == 'killer'
                            ? '${widget.killerName} hunted everyone down'
                            : 'Survivors completed all tasks and escaped!',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Stats card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1F0D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: mainColor.withOpacity(0.2)),
                        ),
                        child: Column(children: [
                          _row('Your Role', widget.myRole.toUpperCase(),
                              widget.myRole == 'killer' ? Colors.red : Colors.blue),
                          const Divider(color: Color(0xFF1A3A1A)),
                          _row('Winner', widget.winnerRole.toUpperCase(), mainColor),
                          const Divider(color: Color(0xFF1A3A1A)),
                          _row('Result', _iWon ? 'WIN' : 'LOSS', mainColor),
                        ]),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushAndRemoveUntil(context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('BACK TO MENU', style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Color(0xFF446644), fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor,
            fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
      ]),
    );
  }
}

class _TreesBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF050F05);
    const trees = [
      [0.05, 0.9, 0.6], [0.18, 0.82, 0.9], [0.32, 0.87, 0.75],
      [0.48, 0.8, 1.0], [0.62, 0.88, 0.7], [0.75, 0.83, 0.85], [0.9, 0.9, 0.65],
    ];
    for (var t in trees) {
      double x = size.width * t[0], y = size.height * t[1], s = t[2];
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 14 * s), width: 7 * s, height: 26 * s), paint);
      Path p1 = Path()
        ..moveTo(x, y - 52 * s)..lineTo(x - 25 * s, y)..lineTo(x + 25 * s, y)..close();
      canvas.drawPath(p1, paint);
      Path p2 = Path()
        ..moveTo(x, y - 34 * s)..lineTo(x - 30 * s, y + 10 * s)..lineTo(x + 30 * s, y + 10 * s)..close();
      canvas.drawPath(p2, paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
