import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'lobby_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -10, end: 10)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final name = await context.read<AuthService>().getUsername();
    if (mounted) setState(() => _username = name);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Container(decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF000000), Color(0xFF030A03), Color(0xFF000000)]),
        )),
        // Atmospheric red glow
        Positioned(top: 80, left: 0, right: 0,
          child: Center(child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.08),
                  blurRadius: 100, spreadRadius: 40)]),
          )),
        ),
        // Tree silhouettes
        Positioned(bottom: 0, left: 0, right: 0,
          child: Opacity(opacity: 0.35,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 200),
              painter: _TreesBgPainter(),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(children: [
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFF2222), Color(0xFF8B0000)]).createShader(b),
                    child: const Text('SHADOW HUNT', style: TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 5)),
                  ),
                  Text('Welcome back, $_username',
                      style: const TextStyle(color: Color(0xFF334433), fontSize: 12)),
                ]),
                IconButton(
                  onPressed: () async {
                    await context.read<AuthService>().logout();
                    if (mounted) Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFF334433), size: 20),
                ),
              ]),
              const SizedBox(height: 28),
              // Killer silhouette
              AnimatedBuilder(
                animation: _float,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _float.value),
                  child: Stack(alignment: Alignment.center, children: [
                    Container(width: 160, height: 160,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.18),
                            blurRadius: 70, spreadRadius: 25)]),
                    ),
                    CustomPaint(size: const Size(85, 136), painter: _KillerPainter()),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              const Text('"No one escapes the forest"',
                  style: TextStyle(color: Color(0xFF2A3A2A),
                      fontStyle: FontStyle.italic, fontSize: 12)),
              const SizedBox(height: 30),
              _btn(icon: Icons.wifi, label: 'ONLINE GAME',
                  sub: 'Play with friends via room code',
                  color: const Color(0xFF1A0000),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LobbyScreen(isSolo: false)))),
              const SizedBox(height: 12),
              _btn(icon: Icons.smart_toy_outlined, label: 'SOLO vs BOTS',
                  sub: 'Hunt or survive against AI',
                  color: const Color(0xFF001500),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LobbyScreen(isSolo: true)))),
              const SizedBox(height: 12),
              _btn(icon: Icons.leaderboard, label: 'LEADERBOARD',
                  sub: 'Top hunters worldwide',
                  color: const Color(0xFF08081A),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _btn({required IconData icon, required String label, required String sub,
      required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          Icon(icon, color: const Color(0xFFCC2222), size: 24),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
            Text(sub, style: const TextStyle(color: Color(0xFF334433), fontSize: 11)),
          ]),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Color(0xFF2A3A2A), size: 20),
        ]),
      ),
    );
  }
}

class _TreesBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF050F05);
    const ts = [[0.05,0.9,0.7],[0.15,0.82,0.95],[0.28,0.88,0.75],[0.42,0.8,1.1],
                 [0.55,0.88,0.65],[0.68,0.83,0.9],[0.8,0.86,0.8],[0.92,0.9,0.65]];
    for (var t in ts) {
      double x = size.width*t[0], y = size.height*t[1], s = t[2];
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y+14*s), width: 7*s, height: 26*s), p);
      canvas.drawPath(Path()..moveTo(x, y-55*s)..lineTo(x-26*s, y)..lineTo(x+26*s, y)..close(), p);
      canvas.drawPath(Path()..moveTo(x, y-35*s)..lineTo(x-32*s, y+10*s)..lineTo(x+32*s, y+10*s)..close(), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _KillerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFCC0000);
    double w = size.width, h = size.height;
    canvas.drawCircle(Offset(w/2, h*0.14), w*0.18, p);
    canvas.drawPath(Path()
      ..moveTo(w*0.28, h*0.28)..lineTo(w*0.18, h*0.60)..lineTo(w*0.34, h*0.60)
      ..lineTo(w*0.40, h*0.46)..lineTo(w*0.60, h*0.46)..lineTo(w*0.66, h*0.60)
      ..lineTo(w*0.82, h*0.60)..lineTo(w*0.72, h*0.28)..close(), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*0.22, h*0.58, w*0.22, h*0.42),
        const Radius.circular(6)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*0.56, h*0.58, w*0.22, h*0.42),
        const Radius.circular(6)), p);
    final wp = Paint()..color = const Color(0xFFAAAAAA)..strokeWidth = 3
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w*0.78, h*0.32), Offset(w*1.1, h*0.04), wp);
    canvas.drawPath(Path()..moveTo(w*1.06, h*0.06)..lineTo(w*0.86, h*0.02)
        ..lineTo(w*0.93, h*0.16)..close(), Paint()..color = const Color(0xFFCCCCCC));
  }
  @override
  bool shouldRepaint(_) => false;
}
