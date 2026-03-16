import 'package:flutter/material.dart';
import 'dart:math';

// ─────────────────────────────────────────
//  Reusable Horror Crewmate Character
// ─────────────────────────────────────────
class HorrorCrewmate extends StatefulWidget {
  final Color bodyColor;
  final bool isDead;
  final bool isHunter;
  final double size;

  const HorrorCrewmate({
    super.key,
    this.bodyColor = const Color(0xFF8B0000),
    this.isDead = false,
    this.isHunter = false,
    this.size = 100,
  });

  @override
  State<HorrorCrewmate> createState() => _HorrorCrewmateState();
}

class _HorrorCrewmateState extends State<HorrorCrewmate>
    with TickerProviderStateMixin {
  late AnimationController _walkController;
  late AnimationController _floatController;
  late AnimationController _eyeController;
  late Animation<double> _walkAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _eyeAnim;

  @override
  void initState() {
    super.initState();

    // Walking bob animation
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Floating animation (for dead/ghost)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Eye blink animation
    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _walkAnim = Tween<double>(begin: -3, end: 3).animate(
        CurvedAnimation(parent: _walkController, curve: Curves.easeInOut));

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _eyeAnim = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _eyeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _walkController.dispose();
    _floatController.dispose();
    _eyeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_walkController, _floatController, _eyeController]),
      builder: (context, child) {
        double offsetY = widget.isDead ? _floatAnim.value : _walkAnim.value;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: CustomPaint(
            size: Size(widget.size, widget.size * 1.3),
            painter: CrewmatePainter(
              bodyColor: widget.bodyColor,
              isDead: widget.isDead,
              isHunter: widget.isHunter,
              eyeScale: _eyeAnim.value > 0.9 ? 0.1 : 1.0, // blink
              walkValue: _walkController.value,
            ),
          ),
        );
      },
    );
  }
}

class CrewmatePainter extends CustomPainter {
  final Color bodyColor;
  final bool isDead;
  final bool isHunter;
  final double eyeScale;
  final double walkValue;

  CrewmatePainter({
    required this.bodyColor,
    required this.isDead,
    required this.isHunter,
    required this.eyeScale,
    required this.walkValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = bodyColor;
    final darkPaint = Paint()
      ..color = bodyColor.withOpacity(0.6);
    final visorPaint = Paint()
      ..color = isDead
          ? Colors.grey.withOpacity(0.5)
          : (isHunter ? const Color(0xFFFF4444) : const Color(0xFF44CCFF));
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3);

    // ── Body shadow ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.25, w * 0.78, h * 0.62),
        Radius.circular(w * 0.22),
      ),
      shadowPaint,
    );

    // ── Main body ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.22, w * 0.76, h * 0.60),
        Radius.circular(w * 0.22),
      ),
      bodyPaint,
    );

    // ── Head (top rounded part) ──
    canvas.drawOval(
      Rect.fromLTWH(w * 0.1, h * 0.04, w * 0.72, h * 0.42),
      bodyPaint,
    );

    // ── Visor ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.08, w * 0.56, h * 0.26),
        Radius.circular(w * 0.12),
      ),
      visorPaint,
    );

    // ── Visor shine ──
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.4);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.22, h * 0.10, w * 0.18, h * 0.10),
      shinePaint,
    );

    // ── Backpack ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.72, h * 0.30, w * 0.22, h * 0.32),
        Radius.circular(w * 0.08),
      ),
      darkPaint,
    );

    // ── Legs ──
    double leftLegAngle = sin(walkValue * pi) * 0.3;
    double rightLegAngle = -sin(walkValue * pi) * 0.3;

    if (isDead) {
      // Dead — legs spread out like ghost
      leftLegAngle = -0.4;
      rightLegAngle = 0.4;
    }

    _drawLeg(canvas, w * 0.25, h * 0.76, w * 0.14, h * 0.2,
        leftLegAngle, bodyColor);
    _drawLeg(canvas, w * 0.53, h * 0.76, w * 0.14, h * 0.2,
        rightLegAngle, bodyColor);

    // ── If dead: X eyes on visor ──
    if (isDead) {
      final xPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Left X
      canvas.drawLine(
          Offset(w * 0.26, h * 0.13), Offset(w * 0.36, h * 0.23), xPaint);
      canvas.drawLine(
          Offset(w * 0.36, h * 0.13), Offset(w * 0.26, h * 0.23), xPaint);

      // Right X
      canvas.drawLine(
          Offset(w * 0.52, h * 0.13), Offset(w * 0.62, h * 0.23), xPaint);
      canvas.drawLine(
          Offset(w * 0.62, h * 0.13), Offset(w * 0.52, h * 0.23), xPaint);
    }

    // ── If hunter: knife accessory ──
    if (isHunter) {
      _drawKnife(canvas, w * 0.0, h * 0.35, w, h);
    }
  }

  void _drawLeg(Canvas canvas, double x, double y, double w, double h,
      double angle, Color color) {
    canvas.save();
    canvas.translate(x + w / 2, y);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, 0, w, h),
        Radius.circular(w * 0.4),
      ),
      Paint()..color = color,
    );
    canvas.restore();
  }

  void _drawKnife(Canvas canvas, double x, double y, double w, double h) {
    final knifePaint = Paint()..color = Colors.grey.shade300;
    final handlePaint = Paint()..color = const Color(0xFF5D3A1A);

    // Blade
    final bladePath = Path();
    bladePath.moveTo(x - w * 0.08, y + h * 0.05);
    bladePath.lineTo(x - w * 0.02, y - h * 0.08);
    bladePath.lineTo(x + w * 0.02, y + h * 0.05);
    bladePath.close();
    canvas.drawPath(bladePath, knifePaint);

    // Handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w * 0.04, y + h * 0.05, w * 0.08, h * 0.1),
        const Radius.circular(3),
      ),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(CrewmatePainter oldDelegate) => true;
}


// ─────────────────────────────────────────
//  Walking Row of Characters (for lobby/home)
// ─────────────────────────────────────────
class WalkingCrewmates extends StatefulWidget {
  const WalkingCrewmates({super.key});

  @override
  State<WalkingCrewmates> createState() => _WalkingCrewmatesState();
}

class _WalkingCrewmatesState extends State<WalkingCrewmates>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnim;

  final List<Color> colors = [
    const Color(0xFF8B0000),
    const Color(0xFF1A1A6E),
    const Color(0xFF006400),
    const Color(0xFF4B0082),
    const Color(0xFF8B4513),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _moveAnim = Tween<double>(begin: -0.3, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: AnimatedBuilder(
        animation: _moveAnim,
        builder: (context, child) {
          return Stack(
            children: List.generate(colors.length, (i) {
              double offset = (_moveAnim.value + i * 0.22) % 1.4 - 0.2;
              return Positioned(
                left: MediaQuery.of(context).size.width * offset,
                bottom: 0,
                child: HorrorCrewmate(
                  bodyColor: colors[i],
                  size: 50,
                  isHunter: i == 0,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}


// ─────────────────────────────────────────
//  Ghost Float (for dead survivors)
// ─────────────────────────────────────────
class GhostCrewmate extends StatelessWidget {
  final Color bodyColor;
  final double size;

  const GhostCrewmate({
    super.key,
    this.bodyColor = Colors.white,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: HorrorCrewmate(
        bodyColor: bodyColor,
        isDead: true,
        size: size,
      ),
    );
  }
}
