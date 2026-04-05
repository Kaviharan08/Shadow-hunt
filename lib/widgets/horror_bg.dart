import 'package:flutter/material.dart';
import 'dart:math';
import 'forest_map.dart';

class HorrorBackground extends StatefulWidget {
  final Widget child;
  final HorrorBgStyle style;
  const HorrorBackground(
      {super.key, required this.child, this.style = HorrorBgStyle.toxic});
  @override
  State<HorrorBackground> createState() => _HorrorBackgroundState();
}

enum HorrorBgStyle { toxic, blood, dark }

class _HorrorBackgroundState extends State<HorrorBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleCtrl;
  late AnimationController _fogCtrl;
  late AnimationController _flickerCtrl;
  bool _flicker = false;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
    _fogCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat(reverse: true);
    _flickerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scheduleFlicker();
  }

  void _scheduleFlicker() {
    Future.delayed(Duration(seconds: 4 + _rng.nextInt(8)), () {
      if (!mounted) return;
      setState(() => _flicker = true);
      _flickerCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _flicker = false);
        _scheduleFlicker();
      });
    });
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _fogCtrl.dispose();
    _flickerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Base
      Container(color: ToxicTheme.bg),
      // Animated bg
      AnimatedBuilder(
        animation: Listenable.merge([_particleCtrl, _fogCtrl]),
        builder: (_, __) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ToxicBgPainter(
            style: widget.style,
            particleT: _particleCtrl.value,
            fogT: _fogCtrl.value,
          ),
        ),
      ),
      // Flicker overlay
      if (_flicker)
        AnimatedBuilder(
          animation: _flickerCtrl,
          builder: (_, __) => Container(
            color: ToxicTheme.green
                .withOpacity(sin(_flickerCtrl.value * pi) * 0.04),
          ),
        ),
      widget.child,
    ]);
  }
}

class _ToxicBgPainter extends CustomPainter {
  final HorrorBgStyle style;
  final double particleT, fogT;
  _ToxicBgPainter(
      {required this.style, required this.particleT, required this.fogT});

  @override
  void paint(Canvas canvas, Size size) {
    _drawTreeSilhouettes(canvas, size);
    _drawToxicFog(canvas, size);
    _drawParticles(canvas, size);
    _drawScanlines(canvas, size);
  }

  void _drawTreeSilhouettes(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF010601);
    final fp = Paint()..color = const Color(0xFF000300);
    final rng = Random(42);
    // Back row
    for (int i = 0; i < 14; i++) {
      double x = (i / 13) * size.width;
      double s = 0.35 + rng.nextDouble() * 0.25;
      _tree(canvas, x, size.height * 0.88, s * size.height * 0.38, p);
    }
    // Front row
    for (int i = 0; i < 9; i++) {
      double x = (i / 8) * size.width * 1.1 - size.width * 0.05;
      double s = 0.65 + rng.nextDouble() * 0.35;
      _tree(canvas, x, size.height, s * size.height * 0.48, fp);
    }
  }

  void _tree(Canvas canvas, double x, double by, double h, Paint p) {
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(x, by - h * 0.08), width: h * 0.1, height: h * 0.2),
        p);
    Path t = Path()
      ..moveTo(x, by - h)
      ..lineTo(x - h * 0.3, by - h * 0.2)
      ..lineTo(x + h * 0.3, by - h * 0.2)
      ..close();
    canvas.drawPath(t, p);
    Path t2 = Path()
      ..moveTo(x, by - h * 0.7)
      ..lineTo(x - h * 0.38, by - h * 0.1)
      ..lineTo(x + h * 0.38, by - h * 0.1)
      ..close();
    canvas.drawPath(t2, p);
  }

  void _drawToxicFog(Canvas canvas, Size size) {
    final rng = Random(77);
    for (int i = 0; i < 5; i++) {
      double x = (i / 4) * size.width + fogT * size.width * 0.1;
      double y = size.height * (0.55 + rng.nextDouble() * 0.35);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x % size.width, y),
              width: size.width * (0.3 + rng.nextDouble() * 0.3),
              height: 35 + rng.nextDouble() * 50),
          Paint()
            ..color = ToxicTheme.green.withOpacity(0.04 + fogT * 0.02)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25));
    }
    // Ground toxic mist
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              ToxicTheme.green.withOpacity(0.08),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(
              0, size.height * 0.72, size.width, size.height * 0.28)));
  }

  void _drawParticles(Canvas canvas, Size size) {
    final rng = Random(55);
    for (int i = 0; i < 25; i++) {
      double t = (particleT + rng.nextDouble()) % 1.0;
      double x = rng.nextDouble() * size.width + sin(t * pi * 2) * 20;
      double y = size.height * (1 - t);
      double r = 1.0 + rng.nextDouble() * 2.5;
      double alpha = sin(t * pi) * 0.5;
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = ToxicTheme.greenGlow.withOpacity(alpha));
    }
  }

  void _drawScanlines(Canvas canvas, Size size) {
    // Subtle CRT scanline effect for horror atmosphere
    final p = Paint()..color = Colors.black.withOpacity(0.03);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ToxicBgPainter old) =>
      old.particleT != particleT || old.fogT != fogT;
}

// ── Hunter Portrait ──────────────────────────────────────────────────────────
class HunterPortrait extends StatefulWidget {
  final String hunterType;
  final double size;
  final bool isSelected;
  const HunterPortrait(
      {super.key,
      required this.hunterType,
      this.size = 120,
      this.isSelected = false});
  @override
  State<HunterPortrait> createState() => _HunterPortraitState();
}

class _HunterPortraitState extends State<HunterPortrait>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(_ctrl);
    _float = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.hunterType) {
      case 'stalker':
        return const Color(0xFF9900CC);
      case 'rusher':
        return const Color(0xFFFF6600);
      case 'trapper':
        return const Color(0xFF996600);
      case 'berserk':
        return ToxicTheme.red;
      default:
        return ToxicTheme.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Transform.scale(
          scale: widget.isSelected ? _pulse.value : 1.0,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _color.withOpacity(0.25),
                    _color.withOpacity(0.05),
                    Colors.transparent,
                  ]),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                              color: _color.withOpacity(0.4),
                              blurRadius: 28,
                              spreadRadius: 5)
                        ]
                      : [],
                ),
              ),
              // Toxic ring
              if (widget.isSelected)
                Container(
                  width: widget.size - 8,
                  height: widget.size - 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: ToxicTheme.green.withOpacity(0.3),
                        width: 1),
                  ),
                ),
              CustomPaint(
                size: Size(widget.size * 0.65, widget.size * 0.88),
                painter:
                    _PortraitPainter(type: widget.hunterType, t: _ctrl.value),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  final String type;
  final double t;
  _PortraitPainter({required this.type, required this.t});

  Color get _body {
    switch (type) {
      case 'stalker':
        return const Color(0xFF660099);
      case 'rusher':
        return const Color(0xFFCC4400);
      case 'trapper':
        return const Color(0xFF664400);
      case 'berserk':
        return const Color(0xFF990000);
      default:
        return const Color(0xFF990000);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _body;
    double w = size.width, h = size.height;

    // Cloak
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.1, h * 0.3)
          ..quadraticBezierTo(0, h * 0.8, w * 0.12, h)
          ..lineTo(w * 0.88, h)
          ..quadraticBezierTo(w, h * 0.8, w * 0.9, h * 0.3)
          ..close(),
        Paint()..color = _body.withOpacity(0.4));

    // Head
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, h * 0.19), width: w * 0.40, height: w * 0.42),
        p);

    // Glowing eyes
    double eyeGlow = 0.5 + sin(t * pi * 2) * 0.5;
    Color eyeC = type == 'stalker'
        ? const Color(0xFFCC44FF)
        : type == 'rusher'
            ? const Color(0xFFFFAA00)
            : ToxicTheme.greenGlow;
    for (double ex in [w * 0.37, w * 0.63]) {
      canvas.drawCircle(
          Offset(ex, h * 0.185),
          5,
          Paint()
            ..color = eyeC.withOpacity(eyeGlow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(Offset(ex, h * 0.185), 3, Paint()..color = eyeC);
    }

    // Body
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.26, h * 0.34)
          ..lineTo(w * 0.15, h * 0.70)
          ..lineTo(w * 0.32, h * 0.70)
          ..lineTo(w * 0.38, h * 0.53)
          ..lineTo(w * 0.62, h * 0.53)
          ..lineTo(w * 0.68, h * 0.70)
          ..lineTo(w * 0.85, h * 0.70)
          ..lineTo(w * 0.74, h * 0.34)
          ..close(),
        p);

    // Legs
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, h * 0.68, w * 0.22, h * 0.32),
            const Radius.circular(7)),
        p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.58, h * 0.68, w * 0.22, h * 0.32),
            const Radius.circular(7)),
        p);

    // Toxic drip effect
    for (int i = 0; i < 3; i++) {
      double dripY = h * (0.68 + (t + i * 0.33) % 1.0 * 0.18);
      double dripX = w * (0.35 + i * 0.15);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(dripX, dripY), width: 4, height: 7),
          Paint()..color = ToxicTheme.green.withOpacity(0.5));
    }
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter old) => old.t != t;
}

// ── Particle System ──────────────────────────────────────────────────────────
class ParticleSystem extends StatefulWidget {
  final int count;
  final Color color;
  const ParticleSystem(
      {super.key, this.count = 30, this.color = ToxicTheme.greenGlow});
  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_P> _ps;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _ps = List.generate(
        widget.count,
        (_) => _P(
              x: rng.nextDouble(),
              y: rng.nextDouble(),
              spd: 0.001 + rng.nextDouble() * 0.003,
              r: 1 + rng.nextDouble() * 3,
              ph: rng.nextDouble() * pi * 2,
              wb: 0.01 + rng.nextDouble() * 0.025,
            ));
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _PPainter(ps: _ps, t: _ctrl.value, color: widget.color),
      ),
    );
  }
}

class _P {
  final double x, y, spd, r, ph, wb;
  _P(
      {required this.x,
      required this.y,
      required this.spd,
      required this.r,
      required this.ph,
      required this.wb});
}

class _PPainter extends CustomPainter {
  final List<_P> ps;
  final double t;
  final Color color;
  _PPainter({required this.ps, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in ps) {
      double prog = (t * p.spd * 1000) % 1.0;
      double y = (p.y - prog) % 1.0;
      double x = p.x + sin(prog * pi * 4 + p.ph) * p.wb;
      double alpha = sin(prog * pi) * 0.6;
      canvas.drawCircle(
          Offset(x * size.width, y * size.height),
          p.r * (1 - prog * 0.4),
          Paint()..color = color.withOpacity(alpha));
    }
  }

  @override
  bool shouldRepaint(covariant _PPainter old) => old.t != t;
}
