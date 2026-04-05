import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/forest_map.dart';
import 'auth/login_screen.dart';
import 'leaderboard_screen.dart';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _emberCtrl;
  late final Animation<double> _float;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _emberCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _float = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await context.read<AuthService>().getUsername();
    if (mounted) setState(() => _username = name);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _emberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090304),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _emberCtrl,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _BloodMenuPainter(t: _emberCtrl.value),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1020),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF251414),
                        width: 3,
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF241111), Color(0xFF110809)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 30,
                          offset: Offset(0, 18),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(painter: _PanelGrainPainter()),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 24, 30, 24),
                            child: LayoutBuilder(
                              builder: (context, c) {
                                final compact = c.maxWidth < 820;
                                return Column(
                                  children: [
                                    _buildTopBar(),
                                    const SizedBox(height: 14),
                                    Expanded(
                                      child: compact
                                          ? _buildCompactLayout()
                                          : _buildWideLayout(),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '"WE WILL FIND YOU."',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFFCF332D)
                                            .withOpacity(0.95),
                                        fontSize: compact ? 18 : 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 8,
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFFFF6158), Color(0xFF9D0F13)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(rect),
                child: const Text(
                  'SHADOW HUNT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'USER INFO:',
                style: TextStyle(
                  color: Colors.red.shade200,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _username.isEmpty ? 'UNKNOWN SURVIVOR' : _username.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFF7B73),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _DangerButton(
          label: 'ESCAPE?',
          onTap: () async {
            await context.read<AuthService>().logout();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        const Expanded(flex: 2, child: _SideArrowColumn(alignment: CrossAxisAlignment.end)),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _float,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _float.value),
                  child: const _SkullEmblem(size: 250),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '"WHO ARE YOU RUNNING FROM?"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFF524B),
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'THE FOREST REMEMBERS EVERY FOOTSTEP.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE6B5AB),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const Spacer(),
              _buildMenuButtons(),
            ],
          ),
        ),
        const Expanded(flex: 2, child: _SideArrowColumn(alignment: CrossAxisAlignment.start)),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _float,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _float.value),
              child: const _SkullEmblem(size: 180),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '"WHO ARE YOU RUNNING FROM?"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFF524B),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black, blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'THE FOREST REMEMBERS EVERY FOOTSTEP.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE6B5AB),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          _buildMenuButtons(vertical: true),
        ],
      ),
    );
  }

  Widget _buildMenuButtons({bool vertical = false}) {
    final buttons = [
      _BoneMenuButton(
        label: 'ONLINE GAME',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LobbyScreen(isSolo: false)),
        ),
      ),
      _BoneMenuButton(
        label: 'SOLO VS BOTS',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LobbyScreen(isSolo: true)),
        ),
      ),
      _BoneMenuButton(
        label: 'LEADERBOARD',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
        ),
      ),
    ];

    if (vertical) {
      return Column(
        children: [
          for (final btn in buttons) ...[
            btn,
            const SizedBox(height: 14),
          ]
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          Expanded(child: buttons[i]),
          if (i != buttons.length - 1) const SizedBox(width: 18),
        ]
      ],
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF513231), Color(0xFF220E0E)],
          ),
          border: Border.all(color: const Color(0xFF090303), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 5))
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFF5D56),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class _BoneMenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _BoneMenuButton({required this.label, required this.onTap});

  @override
  State<_BoneMenuButton> createState() => _BoneMenuButtonState();
}

class _BoneMenuButtonState extends State<_BoneMenuButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: _hover ? 1.04 : 1,
          child: SizedBox(
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BoneButtonPainter(glow: _hover),
                  ),
                ),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4A170F),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: Colors.white38, blurRadius: 2)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideArrowColumn extends StatelessWidget {
  final CrossAxisAlignment alignment;
  const _SideArrowColumn({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: alignment,
      children: const [
        _ArrowBlade(size: 62),
        SizedBox(height: 22),
        _ArrowBlade(size: 72),
        SizedBox(height: 22),
        _ArrowBlade(size: 82),
      ],
    );
  }
}

class _ArrowBlade extends StatelessWidget {
  final double size;
  const _ArrowBlade({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.42),
      painter: _ArrowBladePainter(),
    );
  }
}

class _SkullEmblem extends StatelessWidget {
  final double size;
  const _SkullEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.95,
            height: size * 0.95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D47).withOpacity(0.18),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _SkullEmblemPainter(),
          ),
        ],
      ),
    );
  }
}

class _BloodMenuPainter extends CustomPainter {
  final double t;
  _BloodMenuPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF120808), Color(0xFF090404), Color(0xFF050202)],
        ).createShader(rect),
    );

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x88B32020),
          const Color(0x33401010),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.45),
          radius: size.shortestSide * 0.6,
        ),
      );
    canvas.drawRect(rect, glow);

    final treePaint = Paint()..color = const Color(0xFF1B0B0B);
    final rng = Random(19);
    for (int i = 0; i < 8; i++) {
      final x = (i / 7) * size.width;
      final h = size.height * (0.52 + rng.nextDouble() * 0.32);
      _drawTree(canvas, Offset(x, size.height), h, treePaint, left: i.isEven);
    }

    final emberPaint = Paint();
    final emberRng = Random(42);
    for (int i = 0; i < 34; i++) {
      final phase = (t + emberRng.nextDouble()) % 1.0;
      final x = emberRng.nextDouble() * size.width;
      final y = size.height * (0.15 + ((1 - phase) * 0.75));
      final radius = 1.5 + emberRng.nextDouble() * 3.2;
      emberPaint.color = Color.lerp(
        const Color(0xFFFD3B3B),
        const Color(0xFFFF8A63),
        emberRng.nextDouble(),
      )!
          .withOpacity(0.45 + sin(phase * pi) * 0.4);
      canvas.drawCircle(Offset(x, y), radius, emberPaint);
      canvas.drawCircle(
        Offset(x, y),
        radius * 3.2,
        Paint()
          ..color = emberPaint.color.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.82)],
        stops: const [0.55, 1],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  void _drawTree(Canvas canvas, Offset base, double h, Paint paint,
      {required bool left}) {
    final trunk = Rect.fromLTWH(base.dx - 10, base.dy - h, 20, h);
    canvas.drawRect(trunk, paint);
    final path = Path()..moveTo(base.dx, base.dy - h * 0.78);
    path.quadraticBezierTo(
      base.dx + (left ? -60 : 60),
      base.dy - h * 0.82,
      base.dx + (left ? -120 : 120),
      base.dy - h,
    );
    path.moveTo(base.dx, base.dy - h * 0.56);
    path.quadraticBezierTo(
      base.dx + (left ? 56 : -56),
      base.dy - h * 0.62,
      base.dx + (left ? 110 : -110),
      base.dy - h * 0.78,
    );
    path.moveTo(base.dx, base.dy - h * 0.38);
    path.quadraticBezierTo(
      base.dx + (left ? -40 : 40),
      base.dy - h * 0.42,
      base.dx + (left ? -88 : 88),
      base.dy - h * 0.58,
    );
    final branchPaint = Paint()
      ..color = paint.color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, branchPaint);
  }

  @override
  bool shouldRepaint(covariant _BloodMenuPainter oldDelegate) => oldDelegate.t != t;
}

class _PanelGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(11);
    final linePaint = Paint()..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      linePaint.color = Colors.white.withOpacity(0.012);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (int i = 0; i < 18; i++) {
      final y = rng.nextDouble() * size.height;
      final x = rng.nextDouble() * size.width * 0.4;
      canvas.drawRect(
        Rect.fromLTWH(x, y, 70 + rng.nextDouble() * 120, 2),
        Paint()..color = const Color(0xFF8BE8FF).withOpacity(0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BoneButtonPainter extends CustomPainter {
  final bool glow;
  _BoneButtonPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(18, 16, size.width - 36, size.height - 32),
      const Radius.circular(18),
    );
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEEDCC1), Color(0xFFCBAF81), Color(0xFFEEE1CA)],
      ).createShader(Offset.zero & size);
    canvas.drawShadow(Path()..addRRect(rect), Colors.black, 8, false);
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF5F3927)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final capPaint = Paint()..color = const Color(0xFFE7D2AD);
    canvas.drawCircle(Offset(24, size.height / 2), 16, capPaint);
    canvas.drawCircle(Offset(size.width - 24, size.height / 2), 16, capPaint);
    canvas.drawCircle(
      Offset(24, size.height / 2),
      9,
      Paint()..color = const Color(0xFFF9EED8),
    );
    canvas.drawCircle(
      Offset(size.width - 24, size.height / 2),
      9,
      Paint()..color = const Color(0xFFF9EED8),
    );

    if (glow) {
      canvas.drawRRect(
        rect,
        Paint()
          ..color = const Color(0x55FF5B4D)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoneButtonPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

class _ArrowBladePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.48, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.48, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black87, 8, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7C5C53), Color(0xFF2D1716), Color(0xFF8B665A)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF160909),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SkullEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final ringPaint = Paint()
      ..color = const Color(0xFF5B332F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055;
    canvas.drawCircle(center, size.width * 0.28, ringPaint);

    final spikePaint = Paint()
      ..color = const Color(0xFFD5B08A)
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final start = center + Offset(cos(angle), sin(angle)) * size.width * 0.18;
      final end = center + Offset(cos(angle), sin(angle)) * size.width * 0.42;
      canvas.drawLine(start, end, spikePaint);
      canvas.drawCircle(end, size.width * 0.022, Paint()..color = const Color(0xFFF1DDC1));
    }

    final skullRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - size.height * 0.02),
      width: size.width * 0.34,
      height: size.height * 0.42,
    );
    final skullPath = Path()
      ..moveTo(skullRect.center.dx, skullRect.top)
      ..quadraticBezierTo(skullRect.right, skullRect.top + skullRect.height * 0.05,
          skullRect.right, skullRect.center.dy)
      ..quadraticBezierTo(skullRect.right * 0.98, skullRect.bottom - skullRect.height * 0.12,
          skullRect.center.dx + skullRect.width * 0.18, skullRect.bottom)
      ..lineTo(skullRect.center.dx - skullRect.width * 0.18, skullRect.bottom)
      ..quadraticBezierTo(skullRect.left * 1.02, skullRect.bottom - skullRect.height * 0.12,
          skullRect.left, skullRect.center.dy)
      ..quadraticBezierTo(skullRect.left, skullRect.top + skullRect.height * 0.05,
          skullRect.center.dx, skullRect.top)
      ..close();

    canvas.drawShadow(skullPath, const Color(0xFF520E0B), 18, false);
    canvas.drawPath(
      skullPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7E0D0), Color(0xFFD8B39E), Color(0xFFB88071)],
        ).createShader(skullRect),
    );

    final eyePaint = Paint()..color = const Color(0xFF200506);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - size.width * 0.07, center.dy - size.height * 0.03),
        width: size.width * 0.06,
        height: size.height * 0.09,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + size.width * 0.07, center.dy - size.height * 0.03),
        width: size.width * 0.06,
        height: size.height * 0.09,
      ),
      eyePaint,
    );

    final nose = Path()
      ..moveTo(center.dx, center.dy + size.height * 0.02)
      ..lineTo(center.dx - size.width * 0.03, center.dy + size.height * 0.12)
      ..lineTo(center.dx + size.width * 0.03, center.dy + size.height * 0.12)
      ..close();
    canvas.drawPath(nose, eyePaint);

    final jawRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size.height * 0.17),
      width: size.width * 0.16,
      height: size.height * 0.11,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(jawRect, Radius.circular(size.width * 0.02)),
      Paint()..color = const Color(0xFFE0C0AA),
    );
    final teethPaint = Paint()
      ..color = const Color(0xFF2E0B0D)
      ..strokeWidth = 2;
    for (int i = 1; i < 5; i++) {
      final x = jawRect.left + (jawRect.width / 5) * i;
      canvas.drawLine(Offset(x, jawRect.top), Offset(x, jawRect.bottom), teethPaint);
    }
    canvas.drawLine(Offset(jawRect.left, jawRect.center.dy), Offset(jawRect.right, jawRect.center.dy), teethPaint);

    final crackPaint = Paint()
      ..color = const Color(0xFF8C4337)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx + size.width * 0.01, center.dy - size.height * 0.17),
      Offset(center.dx - size.width * 0.03, center.dy - size.height * 0.02),
      crackPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
