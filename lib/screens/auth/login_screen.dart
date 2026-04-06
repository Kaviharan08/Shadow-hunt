import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/forest_map.dart';
import 'register_screen.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context
        .read<AuthService>()
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _loading = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF040816),
      body: Stack(
        children: [
          const Positioned.fill(child: CosmicLoginBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _glowCtrl,
                        builder: (context, _) {
                          final blur = 26 + (_glowCtrl.value * 14);
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 34 : 18,
                              vertical: isWide ? 26 : 18,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: ToxicTheme.cyan.withOpacity(0.28),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF10152A).withOpacity(0.84),
                                  const Color(0xFF08101F).withOpacity(0.90),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ToxicTheme.purple.withOpacity(0.18),
                                  blurRadius: blur,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: ToxicTheme.cyan.withOpacity(0.12),
                                  blurRadius: blur,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWide ? 34 : 16,
                                    vertical: isWide ? 28 : 20,
                                  ),
                                  child: Column(
                                    children: [
                                      const ArcaneAvatar(),
                                      const SizedBox(height: 18),
                                      ShaderMask(
                                        shaderCallback: (rect) => const LinearGradient(
                                          colors: [
                                            ToxicTheme.greenGlow,
                                            ToxicTheme.cyan,
                                            ToxicTheme.purple,
                                          ],
                                        ).createShader(rect),
                                        child: Text(
                                          'SHADOW HUNT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isWide ? 30 : 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'IDENTIFY YOURSELF',
                                        style: TextStyle(
                                          color: ToxicTheme.white.withOpacity(0.82),
                                          letterSpacing: 3,
                                          fontSize: isWide ? 12 : 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      ArcaneField(
                                        controller: _emailCtrl,
                                        hint: 'EMAIL',
                                        icon: Icons.alternate_email_rounded,
                                      ),
                                      const SizedBox(height: 14),
                                      ArcaneField(
                                        controller: _passCtrl,
                                        hint: 'PASSWORD',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: true,
                                      ),
                                      if (_error != null) ...[
                                        const SizedBox(height: 14),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: ToxicTheme.red.withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: ToxicTheme.red.withOpacity(0.35),
                                            ),
                                          ),
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: ToxicTheme.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 18),
                                      GlowButton(
                                        text: _loading
                                            ? 'SUMMONING...'
                                            : 'SEEK THE ELDRITCH',
                                        onTap: _loading ? null : _login,
                                        loading: _loading,
                                      ),
                                      const SizedBox(height: 18),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 10,
                                        runSpacing: 2,
                                        children: [
                                          TextButton(
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const RegisterScreen(),
                                              ),
                                            ),
                                            child: const Text(
                                              '> NEW EXPLORER? REGISTER',
                                              style: TextStyle(
                                                color: ToxicTheme.greenGlow,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {},
                                            child: Text(
                                              '> LOST YOUR TRAIL? RECOVER ACCOUNT',
                                              style: TextStyle(
                                                color: ToxicTheme.white.withOpacity(0.65),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
}

class ArcaneField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;

  const ArcaneField({super.key, 
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ToxicTheme.cyan.withOpacity(0.12),
            blurRadius: 18,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          color: ToxicTheme.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: ToxicTheme.greenGlow,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: ToxicTheme.white.withOpacity(0.35),
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF111B33),
              border: Border.all(color: ToxicTheme.cyan.withOpacity(0.25)),
            ),
            child: Icon(icon, size: 18, color: ToxicTheme.greenGlow),
          ),
          filled: true,
          fillColor: const Color(0xFF091224).withOpacity(0.92),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: ToxicTheme.cyan.withOpacity(0.22)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: ToxicTheme.greenGlow, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class GlowButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;
  const GlowButton({super.key, required this.text, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF17304F), Color(0xFF144C63), Color(0xFF28406A)],
        ),
        boxShadow: [
          BoxShadow(
            color: ToxicTheme.cyan.withOpacity(0.50),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ToxicTheme.greenGlow.withOpacity(0.85), width: 1.2),
            ),
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: ToxicTheme.white,
                    ),
                  )
                : Text(
                    '[ $text ]',
                    style: const TextStyle(
                      color: ToxicTheme.greenGlow,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ArcaneAvatar extends StatelessWidget {
  const ArcaneAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ToxicTheme.purple.withOpacity(0.26),
                  ToxicTheme.cyan.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          CustomPaint(size: const Size(220, 220), painter: _RuneRingPainter()),
          CustomPaint(size: const Size(130, 150), painter: _CrystalHunterPainter()),
        ],
      ),
    );
  }
}

class CosmicLoginBackground extends StatelessWidget {
  const CosmicLoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CosmicBgPainter(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF070D22),
              const Color(0xFF08152C),
              const Color(0xFF071421),
              Colors.black.withOpacity(0.96),
            ],
          ),
        ),
      ),
    );
  }
}

class _CosmicBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF060B19),
            Color(0xFF0A1430),
            Color(0xFF07111F),
          ],
        ).createShader(rect),
    );

    final rng = Random(7);
    for (int i = 0; i < 160; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height * 0.72;
      final radius = rng.nextDouble() * 1.8 + 0.3;
      canvas.drawCircle(
        Offset(dx, dy),
        radius,
        Paint()..color = Colors.white.withOpacity(0.55 + rng.nextDouble() * 0.35),
      );
    }

    final nebula = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    for (final data in [
      [size.width * 0.14, size.height * 0.18, 220.0, const Color(0x663E52FF)],
      [size.width * 0.82, size.height * 0.24, 180.0, const Color(0x664DE7FF)],
      [size.width * 0.52, size.height * 0.12, 210.0, const Color(0x665E2BFF)],
    ]) {
      nebula.color = data[3] as Color;
      canvas.drawCircle(Offset(data[0] as double, data[1] as double), data[2] as double, nebula);
    }

    final galaxyPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    for (final g in [
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.26, size.height * 0.40),
      Offset(size.width * 0.78, size.height * 0.22),
    ]) {
      galaxyPaint.color = Colors.white.withOpacity(0.18);
      canvas.drawOval(Rect.fromCenter(center: g, width: 140, height: 70), galaxyPaint);
      galaxyPaint.color = ToxicTheme.purple.withOpacity(0.30);
      canvas.drawOval(Rect.fromCenter(center: g, width: 100, height: 42), galaxyPaint);
    }

    final tree = Paint()
      ..color = Colors.black.withOpacity(0.85)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    void drawTree(double x, double baseY, double h) {
      final path = Path()
        ..moveTo(x, baseY)
        ..lineTo(x - 8, baseY - h * 0.45)
        ..lineTo(x + 6, baseY - h);
      canvas.drawPath(path, tree);
      for (int i = 0; i < 5; i++) {
        final y = baseY - h * (0.2 + i * 0.14);
        canvas.drawLine(Offset(x, y), Offset(x - 18 - i * 7, y - 18 - i * 6), tree);
        canvas.drawLine(Offset(x, y), Offset(x + 18 + i * 7, y - 16 - i * 6), tree);
      }
    }

    for (final x in [40.0, 110.0, size.width - 140, size.width - 70]) {
      drawTree(x, size.height * 0.98, size.height * 0.36);
    }

    final fog = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);
    fog.color = ToxicTheme.cyan.withOpacity(0.14);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.88),
        width: size.width * 0.9,
        height: size.height * 0.24,
      ),
      fog,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RuneRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = const SweepGradient(
        colors: [ToxicTheme.cyan, ToxicTheme.purple, ToxicTheme.greenGlow, ToxicTheme.cyan],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.38));

    canvas.drawCircle(center, size.width * 0.38, outer);
    canvas.drawCircle(
      center,
      size.width * 0.31,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = ToxicTheme.white.withOpacity(0.18),
    );

    final textPaint = Paint()
      ..color = ToxicTheme.greenGlow.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 9; i++) {
      final a = (i / 9) * pi * 2;
      final p = Offset(
        center.dx + cos(a) * size.width * 0.47,
        center.dy + sin(a) * size.width * 0.47,
      );
      canvas.drawLine(p.translate(-4, -7), p.translate(2, 6), textPaint);
      canvas.drawLine(p.translate(0, -4), p.translate(6, -10), textPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrystalHunterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);

    final glow = Paint()
      ..color = ToxicTheme.purple.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawCircle(center, 44, glow);

    final head = Path()
      ..moveTo(center.dx, center.dy - 38)
      ..lineTo(center.dx - 26, center.dy - 10)
      ..lineTo(center.dx - 16, center.dy + 18)
      ..lineTo(center.dx + 16, center.dy + 18)
      ..lineTo(center.dx + 26, center.dy - 10)
      ..close();

    final body = Path()
      ..moveTo(center.dx - 34, center.dy + 28)
      ..lineTo(center.dx - 44, center.dy + 78)
      ..lineTo(center.dx - 20, center.dy + 106)
      ..lineTo(center.dx, center.dy + 84)
      ..lineTo(center.dx + 20, center.dy + 106)
      ..lineTo(center.dx + 44, center.dy + 78)
      ..lineTo(center.dx + 34, center.dy + 28)
      ..close();

    const shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB670FF), Color(0xFF732BFF), Color(0xFF5AF0FF)],
    );
    final fill = Paint()..shader = shader.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withOpacity(0.26);

    canvas.drawPath(body, fill);
    canvas.drawPath(head, fill);
    canvas.drawPath(body, line);
    canvas.drawPath(head, line);

    final eye = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFFFF176), Color(0xFFFF6F00)])
          .createShader(Rect.fromLTWH(center.dx - 20, center.dy - 22, 40, 20))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 10, center.dy - 8), width: 12, height: 7), eye);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 10, center.dy - 8), width: 12, height: 7), eye);

    canvas.drawLine(Offset(center.dx - 22, center.dy + 48), Offset(center.dx + 22, center.dy + 66), line);
    canvas.drawLine(Offset(center.dx - 12, center.dy + 24), Offset(center.dx - 32, center.dy + 78), line);
    canvas.drawLine(Offset(center.dx + 12, center.dy + 24), Offset(center.dx + 32, center.dy + 78), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
