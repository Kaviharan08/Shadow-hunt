import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 4), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => user != null ? const HomeScreen() : const LoginScreen(),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, child) => Opacity(
          opacity: _fade.value,
          child: Stack(
            children: [
              // Dark forest background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF000000), Color(0xFF0A1A0A), Color(0xFF000000)],
                  ),
                ),
              ),
              // Tree silhouettes at bottom
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: CustomPaint(
                  size: Size(MediaQuery.of(ctx).size.width, 200),
                  painter: _SplashTreesPainter(),
                ),
              ),
              // Fog effect
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF0A1A0A).withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Center(
                child: Transform.scale(
                  scale: _scale.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Killer silhouette
                      CustomPaint(
                        size: const Size(80, 130),
                        painter: _KillerSilhouettePainter(),
                      ),
                      const SizedBox(height: 24),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF3333), Color(0xFF8B0000)],
                        ).createShader(bounds),
                        child: const Text(
                          'SHADOW HUNT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'NO ONE ESCAPES THE FOREST',
                        style: TextStyle(
                          color: Color(0xFF556655),
                          fontSize: 12,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.red.withOpacity(0.7),
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashTreesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF050F05);
    // Draw several tree silhouettes
    const trees = [
      [0.05, 0.9, 0.6], [0.12, 0.85, 0.8], [0.22, 0.88, 0.7],
      [0.35, 0.82, 1.0], [0.48, 0.9, 0.65], [0.58, 0.84, 0.9],
      [0.68, 0.87, 0.75], [0.78, 0.83, 1.1], [0.88, 0.88, 0.7],
      [0.95, 0.91, 0.6],
    ];
    for (var t in trees) {
      double x = size.width * t[0];
      double y = size.height * t[1];
      double s = t[2];
      // Trunk
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 15 * s), width: 8 * s, height: 30 * s), paint);
      // Tree top
      Path tri = Path()
        ..moveTo(x, y - 60 * s)
        ..lineTo(x - 28 * s, y)
        ..lineTo(x + 28 * s, y)
        ..close();
      canvas.drawPath(tri, paint);
      Path tri2 = Path()
        ..moveTo(x, y - 40 * s)
        ..lineTo(x - 35 * s, y + 10 * s)
        ..lineTo(x + 35 * s, y + 10 * s)
        ..close();
      canvas.drawPath(tri2, paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _KillerSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCC0000);
    double w = size.width, h = size.height;
    // Head
    canvas.drawCircle(Offset(w / 2, h * 0.15), w * 0.18, paint);
    // Body
    Path body = Path()
      ..moveTo(w * 0.3, h * 0.3)
      ..lineTo(w * 0.2, h * 0.62)
      ..lineTo(w * 0.35, h * 0.62)
      ..lineTo(w * 0.4, h * 0.48)
      ..lineTo(w * 0.6, h * 0.48)
      ..lineTo(w * 0.65, h * 0.62)
      ..lineTo(w * 0.8, h * 0.62)
      ..lineTo(w * 0.7, h * 0.3)
      ..close();
    canvas.drawPath(body, paint);
    // Legs
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.6, w * 0.2, h * 0.4), const Radius.circular(6)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.56, h * 0.6, w * 0.2, h * 0.4), const Radius.circular(6)), paint);
    // Scythe
    final wp = Paint()
      ..color = const Color(0xFFAAAAAA)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.78, h * 0.35), Offset(w * 1.1, h * 0.05), wp);
    final bp = Paint()..color = const Color(0xFFCCCCCC);
    Path blade = Path()
      ..moveTo(w * 1.05, h * 0.08)
      ..lineTo(w * 0.85, h * 0.04)
      ..lineTo(w * 0.92, h * 0.18)
      ..close();
    canvas.drawPath(blade, bp);
  }
  @override
  bool shouldRepaint(_) => false;
}
