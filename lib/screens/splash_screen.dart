import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/horror_bg.dart';
import '../widgets/forest_map.dart';
import 'home_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _mainCtrl, curve: const Interval(0, 0.5)));
    _scale = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.elasticOut));
    _textFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.5, 1.0)));
    _mainCtrl.forward();
    Future.delayed(const Duration(seconds: 5), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) =>
          user != null ? const HomeScreen() : const LoginScreen(),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    ));
  }

  @override
  void dispose() { _mainCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: HorrorBackground(
        child: Stack(children: [
          const ParticleSystem(count: 30, color: ToxicTheme.greenGlow),
          Center(
            child: AnimatedBuilder(
              animation: _mainCtrl,
              builder: (_, __) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fade,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Stack(alignment: Alignment.center, children: [
                        // Outer glow ring
                        Container(
                          width: 180, height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: ToxicTheme.green.withOpacity(0.2), width: 1),
                            boxShadow: [BoxShadow(
                                color: ToxicTheme.greenGlow.withOpacity(0.3),
                                blurRadius: 60, spreadRadius: 20)],
                          ),
                        ),
                        const HunterPortrait(
                            hunterType: 'stalker', size: 150, isSelected: true),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _textFade,
                    child: Column(children: [
                      // Title with toxic green
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [ToxicTheme.greenGlow, ToxicTheme.green, ToxicTheme.greenDim],
                        ).createShader(b),
                        child: const Text('SHADOW HUNT',
                          style: TextStyle(
                            color: Colors.white, fontSize: 38,
                            fontWeight: FontWeight.bold, letterSpacing: 10,
                            fontFamily: 'monospace',
                          )),
                      ),
                      const SizedBox(height: 6),
                      // Blood drips in green
                      CustomPaint(size: const Size(300, 14), painter: _DripPainter()),
                      const SizedBox(height: 12),
                      const Text('> SYSTEM ONLINE. HUNT INITIATED. <',
                          style: TextStyle(color: ToxicTheme.greenDim,
                              fontSize: 11, letterSpacing: 3, fontFamily: 'monospace')),
                      const SizedBox(height: 48),
                      // Loading bar
                      SizedBox(
                        width: 200,
                        child: Column(children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('LOADING...',
                                  style: TextStyle(color: ToxicTheme.greenDim,
                                      fontSize: 10, letterSpacing: 2, fontFamily: 'monospace')),
                              Text('${(_mainCtrl.value * 100).toInt()}%',
                                  style: const TextStyle(color: ToxicTheme.green,
                                      fontSize: 10, fontFamily: 'monospace')),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: const LinearProgressIndicator(
                              backgroundColor: ToxicTheme.greenDark,
                              valueColor: AlwaysStoppedAnimation(ToxicTheme.greenGlow),
                              minHeight: 3,
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = ToxicTheme.green;
    const xs = [0.05, 0.18, 0.32, 0.48, 0.62, 0.75, 0.88, 0.96];
    final hs = [10.0, 7.0, 13.0, 9.0, 11.0, 8.0, 12.0, 7.0];
    for (int i = 0; i < xs.length; i++) {
      canvas.drawOval(Rect.fromCenter(
          center: Offset(xs[i] * size.width, hs[i] / 2),
          width: 4, height: hs[i]), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
