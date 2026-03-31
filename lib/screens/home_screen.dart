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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -8, end: 8)
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF000000), Color(0xFF050F05), Color(0xFF000000)],
              ),
            ),
          ),
          // Tree silhouettes at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Opacity(
              opacity: 0.4,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 180),
                painter: _HomeBgPainter(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('SHADOW HUNT',
                            style: TextStyle(color: Color(0xFFCC2222), fontSize: 20,
                                fontWeight: FontWeight.bold, letterSpacing: 4)),
                        Text('Welcome, $_username',
                            style: const TextStyle(color: Color(0xFF446644), fontSize: 13)),
                      ]),
                      IconButton(
                        onPressed: () async {
                          await context.read<AuthService>().logout();
                          if (mounted) Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        icon: const Icon(Icons.logout, color: Color(0xFF446644)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Floating killer
                  AnimatedBuilder(
                    animation: _float,
                    builder: (ctx, child) => Transform.translate(
                      offset: Offset(0, _float.value),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140, height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.red.withOpacity(0.2),
                                    blurRadius: 60, spreadRadius: 20),
                              ],
                            ),
                          ),
                          CustomPaint(
                            size: const Size(90, 145),
                            painter: _KillerHomePainter(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('"No one escapes the forest"',
                      style: TextStyle(color: Color(0xFF334433),
                          fontStyle: FontStyle.italic, fontSize: 13)),
                  const SizedBox(height: 36),
                  // Menu buttons
                  _menuBtn(
                    icon: Icons.wifi,
                    label: 'ONLINE GAME',
                    subtitle: 'Play with friends via room code',
                    color: const Color(0xFF1A0000),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LobbyScreen(isSolo: false))),
                  ),
                  const SizedBox(height: 14),
                  _menuBtn(
                    icon: Icons.smart_toy_outlined,
                    label: 'SOLO vs BOTS',
                    subtitle: 'Hunt or survive against AI',
                    color: const Color(0xFF001A00),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LobbyScreen(isSolo: true))),
                  ),
                  const SizedBox(height: 14),
                  _menuBtn(
                    icon: Icons.leaderboard,
                    label: 'LEADERBOARD',
                    subtitle: 'Top hunters worldwide',
                    color: const Color(0xFF0A0A1A),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuBtn({
    required IconData icon, required String label,
    required String subtitle, required VoidCallback onTap, required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          Icon(icon, color: const Color(0xFFCC2222), size: 26),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF446644), fontSize: 11)),
          ]),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Color(0xFF334433)),
        ]),
      ),
    );
  }
}

class _HomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF050F05);
    const positions = [
      [0.05, 0.9, 0.7], [0.15, 0.82, 0.95], [0.28, 0.88, 0.75],
      [0.42, 0.8, 1.1], [0.55, 0.88, 0.65], [0.68, 0.83, 0.9],
      [0.8, 0.86, 0.8], [0.92, 0.9, 0.65],
    ];
    for (var t in positions) {
      double x = size.width * t[0], y = size.height * t[1], s = t[2];
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 15 * s), width: 7 * s, height: 28 * s), paint);
      Path tri = Path()
        ..moveTo(x, y - 55 * s)
        ..lineTo(x - 26 * s, y)
        ..lineTo(x + 26 * s, y)
        ..close();
      canvas.drawPath(tri, paint);
      Path tri2 = Path()
        ..moveTo(x, y - 35 * s)
        ..lineTo(x - 32 * s, y + 10 * s)
        ..lineTo(x + 32 * s, y + 10 * s)
        ..close();
      canvas.drawPath(tri2, paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _KillerHomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCC0000);
    double w = size.width, h = size.height;
    canvas.drawCircle(Offset(w / 2, h * 0.14), w * 0.18, paint);
    Path body = Path()
      ..moveTo(w * 0.28, h * 0.28)
      ..lineTo(w * 0.18, h * 0.6)
      ..lineTo(w * 0.34, h * 0.6)
      ..lineTo(w * 0.4, h * 0.46)
      ..lineTo(w * 0.6, h * 0.46)
      ..lineTo(w * 0.66, h * 0.6)
      ..lineTo(w * 0.82, h * 0.6)
      ..lineTo(w * 0.72, h * 0.28)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.58, w * 0.22, h * 0.42), const Radius.circular(6)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.56, h * 0.58, w * 0.22, h * 0.42), const Radius.circular(6)), paint);
    // Scythe
    final wp = Paint()
      ..color = const Color(0xFFAAAAAA)
      ..strokeWidth = 3 ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.78, h * 0.32), Offset(w * 1.1, h * 0.04), wp);
    final bp = Paint()..color = const Color(0xFFCCCCCC);
    Path blade = Path()
      ..moveTo(w * 1.06, h * 0.06)
      ..lineTo(w * 0.86, h * 0.02)
      ..lineTo(w * 0.93, h * 0.16)
      ..close();
    canvas.drawPath(blade, bp);
  }
  @override
  bool shouldRepaint(_) => false;
}
