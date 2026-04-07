import 'dart:math';
import 'package:flutter/material.dart';

class ToxicTheme {
  static const Color bg = Color(0xFF060812);
  static const Color bgDark = Color(0xFF0A0F1F);
  static const Color green = Color(0xFF5BE7FF);
  static const Color greenDim = Color(0xFF72B7FF);
  static const Color greenDark = Color(0xFF1A3A68);
  static const Color greenGlow = Color(0xFF8AF5FF);
  static const Color red = Color(0xFFFF3B5F);
  static const Color redDim = Color(0xFF6D1126);
  static const Color white = Color(0xFFEAF6FF);
  static const Color grey = Color(0xFF161D2C);
  static const Color purple = Color(0xFF8F5BFF);
  static const Color cyan = Color(0xFF33D6FF);
}

const double kMapW = 1400;
const double kMapH = 1200;

class ForestMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF070C18));
    final rng = Random(13);
    for (int i = 0; i < 220; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        6 + rng.nextDouble() * 20,
        Paint()..color = Color.lerp(const Color(0xFF070C18), const Color(0xFF101B34), rng.nextDouble())!,
      );
    }

    final pathPaint = Paint()
      ..color = const Color(0xFF10192D)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), pathPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), pathPaint);
    pathPaint.strokeWidth = 18;
    canvas.drawLine(const Offset(120, 120), Offset(size.width * 0.38, size.height * 0.38), pathPaint);
    canvas.drawLine(Offset(size.width - 120, 120), Offset(size.width * 0.62, size.height * 0.38), pathPaint);
    canvas.drawLine(Offset(120, size.height - 120), Offset(size.width * 0.38, size.height * 0.62), pathPaint);
    canvas.drawLine(Offset(size.width - 120, size.height - 120), Offset(size.width * 0.62, size.height * 0.62), pathPaint);

    final pools = [
      const Offset(320, 420), const Offset(750, 280), const Offset(1100, 600),
      const Offset(450, 900), const Offset(900, 1050), const Offset(180, 650), const Offset(1200, 350),
    ];
    for (final c in pools) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 120, height: 70),
        Paint()
          ..color = ToxicTheme.green.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawOval(Rect.fromCenter(center: c, width: 76, height: 44), Paint()..color = ToxicTheme.greenDark.withOpacity(0.8));
    }

    for (int i = 0; i < 80; i++) {
      final x = 50 + rng.nextDouble() * (size.width - 100);
      final y = 50 + rng.nextDouble() * (size.height - 100);
      final s = 0.7 + rng.nextDouble() * 0.9;
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 12 * s), width: 7 * s, height: 18 * s), Paint()..color = const Color(0xFF161A22));
      for (int layer = 0; layer < 3; layer++) {
        canvas.drawCircle(Offset(x, y - layer * 11 * s), (20 - layer * 3) * s, Paint()..color = const Color(0xFF0F1630));
      }
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = RadialGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.82)], stops: const [0.45, 1]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NightmareMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF05000A), Color(0xFF090013), Color(0xFF000000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final rng = Random(77);
    for (int i = 0; i < 180; i++) {
      final r = 10 + rng.nextDouble() * 30;
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        r,
        Paint()..color = Color.lerp(const Color(0xFF10031A), const Color(0xFF001C24), rng.nextDouble())!,
      );
    }

    final neonGrid = Paint()
      ..color = ToxicTheme.purple.withOpacity(0.16)
      ..strokeWidth = 2;
    for (double x = 120; x < size.width; x += 220) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), neonGrid);
    }
    for (double y = 120; y < size.height; y += 220) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), neonGrid);
    }

    final lava = [
      const Offset(260, 250), const Offset(1080, 300), const Offset(1140, 760),
      const Offset(760, 980), const Offset(240, 920),
    ];
    for (final c in lava) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 150, height: 90), Paint()..color = ToxicTheme.cyan.withOpacity(0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26));
      canvas.drawOval(Rect.fromCenter(center: c, width: 90, height: 54), Paint()..color = ToxicTheme.purple.withOpacity(0.6));
      canvas.drawOval(Rect.fromCenter(center: Offset(c.dx - 10, c.dy - 6), width: 38, height: 18), Paint()..color = Colors.white.withOpacity(0.12));
    }

    final wall = Paint()
      ..color = const Color(0xFF110B1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    canvas.drawRect(const Rect.fromLTWH(140, 140, 1120, 920), wall);
    wall.strokeWidth = 16;
    canvas.drawLine(const Offset(140, 600), const Offset(1260, 600), wall);
    canvas.drawLine(const Offset(700, 140), const Offset(700, 1060), wall);
    canvas.drawLine(const Offset(280, 260), const Offset(520, 520), wall);
    canvas.drawLine(const Offset(1120, 260), const Offset(880, 520), wall);
    canvas.drawLine(const Offset(320, 960), const Offset(540, 740), wall);
    canvas.drawLine(const Offset(1080, 960), const Offset(860, 740), wall);

    final runePaint = Paint()
      ..color = ToxicTheme.cyan.withOpacity(0.18)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final c in [const Offset(700, 210), const Offset(230, 600), const Offset(1170, 600), const Offset(700, 990)]) {
      canvas.drawCircle(c, 46, runePaint);
      canvas.drawCircle(c, 24, runePaint);
      canvas.drawLine(Offset(c.dx - 32, c.dy), Offset(c.dx + 32, c.dy), runePaint);
      canvas.drawLine(Offset(c.dx, c.dy - 32), Offset(c.dx, c.dy + 32), runePaint);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = RadialGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.84)], stops: const [0.40, 1]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TaskMarker extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback? onTap;
  const TaskMarker({super.key, this.isCompleted = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? ToxicTheme.greenDark : const Color(0xFF041008),
          border: Border.all(color: isCompleted ? ToxicTheme.green : ToxicTheme.greenGlow, width: 2),
          boxShadow: [BoxShadow(color: (isCompleted ? ToxicTheme.green : ToxicTheme.greenGlow).withOpacity(0.35), blurRadius: 12, spreadRadius: 1)],
        ),
        child: Icon(isCompleted ? Icons.check : Icons.assignment, color: isCompleted ? ToxicTheme.green : ToxicTheme.white, size: 18),
      ),
    );
  }
}

class PowerupWidget extends StatelessWidget {
  final dynamic type;
  const PowerupWidget({super.key, required this.type});
  @override
  Widget build(BuildContext context) {
    final label = type.toString().split('.').last;
    final icon = label == 'speedBoost' ? Icons.bolt : label == 'healthPack' ? Icons.favorite : label == 'flashbang' ? Icons.flash_on : Icons.visibility_off;
    final color = label == 'speedBoost' ? ToxicTheme.green : label == 'healthPack' ? ToxicTheme.red : label == 'flashbang' ? Colors.orange : ToxicTheme.purple;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2), border: Border.all(color: color, width: 2), boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 14)]),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class TrapWidget extends StatelessWidget {
  final bool isTriggered;
  const TrapWidget({super.key, required this.isTriggered});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isTriggered ? 0.35 : 1,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(shape: BoxShape.circle, color: ToxicTheme.redDim.withOpacity(0.18), border: Border.all(color: ToxicTheme.red, width: 2)),
        child: const Icon(Icons.warning_amber_rounded, color: ToxicTheme.red, size: 16),
      ),
    );
  }
}

class PortalWidget extends StatelessWidget {
  final bool active;
  const PortalWidget({super.key, this.active = true});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [ToxicTheme.cyan.withOpacity(0.95), ToxicTheme.purple.withOpacity(0.85), Colors.transparent], stops: const [0.12, 0.6, 1]),
        boxShadow: [
          BoxShadow(color: ToxicTheme.cyan.withOpacity(active ? 0.5 : 0.1), blurRadius: 28, spreadRadius: 4),
          BoxShadow(color: ToxicTheme.purple.withOpacity(active ? 0.35 : 0.08), blurRadius: 38, spreadRadius: 6),
        ],
      ),
      child: const Center(child: Icon(Icons.change_circle_outlined, color: Colors.white, size: 42)),
    );
  }
}

class BloodSplatter extends StatelessWidget {
  const BloodSplatter({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(80, 80), painter: _BloodPainter());
  }
}

class _BloodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = ToxicTheme.red.withOpacity(0.65);
    final rng = Random(5);
    for (int i = 0; i < 15; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 3 + rng.nextDouble() * 9;
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class SilhouettePlayer extends StatefulWidget {
  final bool isKiller;
  final bool isMe;
  final bool isAlive;
  final bool isInvisible;
  final String username;
  final String hunterType;
  final int health;
  final double size;

  const SilhouettePlayer({
    super.key,
    required this.isKiller,
    required this.isMe,
    required this.isAlive,
    this.isInvisible = false,
    required this.username,
    required this.hunterType,
    required this.health,
    this.size = 40,
  });

  @override
  State<SilhouettePlayer> createState() => _SilhouettePlayerState();
}

class _SilhouettePlayerState extends State<SilhouettePlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isKiller ? 900 : 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = !widget.isAlive
        ? Colors.grey.shade500
        : widget.isKiller
            ? ToxicTheme.red
            : ToxicTheme.cyan;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bob = sin(_controller.value * pi * 2) * (widget.isKiller ? 2.0 : 1.4);
        final aura = 0.25 + ((_controller.value - 0.5).abs() * -2 + 1) * 0.18;
        return Opacity(
          opacity: widget.isInvisible && !widget.isMe ? 0.06 : widget.isInvisible ? 0.22 : 1,
          child: Transform.translate(
            offset: Offset(0, -bob),
            child: Column(
              children: [
                if (widget.health > 0)
                  Container(
                    width: widget.size + 10,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ToxicTheme.greenDark.withOpacity(0.8)),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (widget.health.clamp(0, 100)) / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.health > 60
                                ? [ToxicTheme.green, ToxicTheme.cyan]
                                : widget.health > 30
                                    ? [Colors.orangeAccent, Colors.deepOrangeAccent]
                                    : [ToxicTheme.red, const Color(0xFFFF8A80)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: baseColor.withOpacity(0.35), blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: widget.size * 1.05,
                      height: widget.size * 1.05,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [baseColor.withOpacity(aura), Colors.transparent],
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: Size(widget.size, widget.size * 1.32),
                      painter: _AvatarPainter(
                        color: baseColor,
                        isKiller: widget.isKiller,
                        isAlive: widget.isAlive,
                        pulse: _controller.value,
                      ),
                    ),
                    if (widget.isInvisible)
                      Positioned(
                        right: 0,
                        bottom: widget.size * 0.14,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.7),
                            border: Border.all(color: ToxicTheme.purple.withOpacity(0.8)),
                          ),
                          child: const Icon(Icons.visibility_off, color: ToxicTheme.purple, size: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xCC08111F),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.isMe ? ToxicTheme.cyan : baseColor.withOpacity(0.5),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6)],
                  ),
                  child: Text(
                    widget.isMe ? 'YOU' : widget.username,
                    style: TextStyle(
                      color: widget.isMe ? ToxicTheme.cyan : ToxicTheme.white,
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final Color color;
  final bool isKiller;
  final bool isAlive;
  final double pulse;

  _AvatarPainter({
    required this.color,
    required this.isKiller,
    required this.isAlive,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = color.withOpacity(isAlive ? 0.22 : 0.08);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = isAlive ? color : Colors.grey.shade500;

    final headCenter = Offset(w * 0.5, h * 0.2);
    canvas.drawCircle(headCenter, w * 0.14, glow);
    canvas.drawCircle(headCenter, w * 0.14, core);

    final torso = Path()
      ..moveTo(w * 0.5, h * 0.34)
      ..lineTo(w * 0.5, h * 0.72);
    canvas.drawPath(torso, glow);
    canvas.drawPath(torso, core);

    final shoulderY = h * 0.42;
    final swing = sin(pulse * pi * 2) * w * (isKiller ? 0.09 : 0.06);
    final leftArm = Path()
      ..moveTo(w * 0.5, shoulderY)
      ..lineTo(w * 0.32 - swing, h * 0.58);
    final rightArm = Path()
      ..moveTo(w * 0.5, shoulderY)
      ..lineTo(w * 0.68 + swing, h * 0.58);
    canvas.drawPath(leftArm, glow);
    canvas.drawPath(rightArm, glow);
    canvas.drawPath(leftArm, core);
    canvas.drawPath(rightArm, core);

    final leftLeg = Path()
      ..moveTo(w * 0.5, h * 0.72)
      ..lineTo(w * 0.38 - swing * 0.35, h * 1.0);
    final rightLeg = Path()
      ..moveTo(w * 0.5, h * 0.72)
      ..lineTo(w * 0.62 + swing * 0.35, h * 1.0);
    canvas.drawPath(leftLeg, glow);
    canvas.drawPath(rightLeg, glow);
    canvas.drawPath(leftLeg, core);
    canvas.drawPath(rightLeg, core);

    canvas.drawCircle(headCenter, w * 0.065, Paint()..color = Colors.white.withOpacity(isAlive ? 0.95 : 0.4));
    if (isKiller) {
      final blade = Path()
        ..moveTo(w * 0.72, h * 0.56)
        ..lineTo(w * 0.92, h * 0.4)
        ..lineTo(w * 0.86, h * 0.62)
        ..close();
      canvas.drawPath(blade, Paint()..color = const Color(0xFFE3F2FD).withOpacity(0.9));
      canvas.drawLine(
        Offset(w * 0.7, h * 0.58),
        Offset(w * 0.82, h * 0.66),
        Paint()..color = const Color(0xFF4E342E)..strokeWidth = w * 0.06..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.color != color ||
      oldDelegate.isKiller != isKiller ||
      oldDelegate.isAlive != isAlive;
}
