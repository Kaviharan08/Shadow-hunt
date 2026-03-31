import 'package:flutter/material.dart';
import 'dart:math';

// ── Forest Map ──────────────────────────────────────────────────────────────

class ForestMapPainter extends CustomPainter {
  ForestMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0D1F0D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    _drawGround(canvas, size);
    _drawTrees(canvas, size);
    _drawPaths(canvas, size);
    _drawRocks(canvas, size);
    _drawFog(canvas, size);
  }

  void _drawGround(Canvas canvas, Size size) {
    final paint = Paint();
    final rng = Random(42);
    // Grass patches
    for (int i = 0; i < 120; i++) {
      double x = rng.nextDouble() * size.width;
      double y = rng.nextDouble() * size.height;
      paint.color = Color.lerp(
        const Color(0xFF0D1F0D),
        const Color(0xFF1A3A1A),
        rng.nextDouble(),
      )!;
      canvas.drawCircle(Offset(x, y), 8 + rng.nextDouble() * 18, paint);
    }
  }

  void _drawPaths(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A140A)
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Horizontal path
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), paint);
    // Vertical path
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), paint);
    // Diagonal
    paint.strokeWidth = 18;
    canvas.drawLine(Offset(0, 0), Offset(size.width * 0.4, size.height * 0.4), paint);
  }

  void _drawTrees(Canvas canvas, Size size) {
    final rng = Random(7);
    final trunkPaint = Paint()..color = const Color(0xFF2A1A0A);
    final leafPaint = Paint();
    final darkLeaf = Paint()..color = const Color(0xFF0A2A0A).withOpacity(0.9);

    const treePositions = [
      [60.0, 80.0], [130.0, 60.0], [220.0, 100.0], [350.0, 50.0],
      [500.0, 80.0], [620.0, 60.0], [720.0, 90.0],
      [50.0, 200.0], [760.0, 200.0], [40.0, 400.0], [770.0, 380.0],
      [60.0, 580.0], [740.0, 560.0], [150.0, 650.0], [680.0, 640.0],
      [300.0, 680.0], [480.0, 660.0], [100.0, 320.0], [700.0, 300.0],
      [250.0, 160.0], [560.0, 140.0], [420.0, 600.0],
    ];

    for (var pos in treePositions) {
      double x = pos[0];
      double y = pos[1];
      double scale = 0.7 + rng.nextDouble() * 0.6;

      // Trunk
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y + 14 * scale), width: 8 * scale, height: 20 * scale),
        trunkPaint,
      );
      // Shadow
      final shadowPaint = Paint()..color = Colors.black.withOpacity(0.3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 6, y + 22 * scale), width: 24 * scale, height: 8 * scale),
        shadowPaint,
      );
      // Leaves layers
      for (int layer = 0; layer < 3; layer++) {
        double layerY = y - layer * 12 * scale;
        double layerR = (22 - layer * 4) * scale;
        leafPaint.color = Color.lerp(
          const Color(0xFF0D2A0D),
          const Color(0xFF1A4A1A),
          rng.nextDouble(),
        )!;
        canvas.drawCircle(Offset(x, layerY), layerR, leafPaint);
        canvas.drawCircle(Offset(x, layerY), layerR * 0.7, darkLeaf);
      }
    }
  }

  void _drawRocks(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2A2A2A);
    final highlight = Paint()..color = const Color(0xFF3A3A3A);
    const rocks = [
      [160.0, 340.0, 18.0], [480.0, 240.0, 14.0], [620.0, 460.0, 20.0],
      [280.0, 520.0, 12.0], [560.0, 360.0, 16.0], [380.0, 160.0, 10.0],
    ];
    for (var r in rocks) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(r[0], r[1]), width: r[2] * 2.2, height: r[2] * 1.4),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(r[0] - 3, r[1] - 3), width: r[2], height: r[2] * 0.6),
        highlight,
      );
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, const Color(0xFF030D03).withOpacity(0.7)],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Task Marker ──────────────────────────────────────────────────────────────

class TaskMarker extends StatefulWidget {
  final String title;
  final bool isCompleted;
  final VoidCallback? onTap;
  const TaskMarker({
    super.key, required this.title, this.isCompleted = false, this.onTap,
  });
  @override
  State<TaskMarker> createState() => _TaskMarkerState();
}

class _TaskMarkerState extends State<TaskMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.2).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return Container(
        width: 28, height: 28,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (ctx, child) => Transform.scale(
          scale: _pulse.value,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withOpacity(0.9),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 10, spreadRadius: 3)],
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 18),
          ),
        ),
      ),
    );
  }
}

// ── Silhouette Characters ────────────────────────────────────────────────────

class SilhouettePlayer extends StatefulWidget {
  final bool isKiller;
  final bool isMe;
  final bool isAlive;
  final String username;
  final double size;
  const SilhouettePlayer({
    super.key,
    this.isKiller = false,
    this.isMe = false,
    this.isAlive = true,
    required this.username,
    this.size = 36,
  });
  @override
  State<SilhouettePlayer> createState() => _SilhouettePlayerState();
}

class _SilhouettePlayerState extends State<SilhouettePlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bob;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    _bob = Tween<double>(begin: -2, end: 2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    Color color = widget.isKiller
        ? const Color(0xFFCC0000)
        : (widget.isMe ? Colors.white : const Color(0xFF88AAFF));

    if (!widget.isAlive) color = color.withOpacity(0.3);

    return AnimatedBuilder(
      animation: _bob,
      builder: (ctx, child) => Transform.translate(
        offset: Offset(0, _bob.value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glow ring for self
            if (widget.isMe)
              Container(
                width: widget.size + 10,
                height: widget.size + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                ),
              ),
            CustomPaint(
              size: Size(widget.size, widget.size * 1.6),
              painter: _SilhouettePainter(
                color: color,
                isKiller: widget.isKiller,
                isAlive: widget.isAlive,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.username,
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final Color color;
  final bool isKiller;
  final bool isAlive;
  _SilhouettePainter({required this.color, required this.isKiller, required this.isAlive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    double w = size.width;
    double h = size.height;

    // Head
    canvas.drawCircle(Offset(w / 2, h * 0.18), w * 0.22, paint);

    // Body
    Path body = Path()
      ..moveTo(w * 0.28, h * 0.38)
      ..lineTo(w * 0.18, h * 0.72)
      ..lineTo(w * 0.32, h * 0.72)
      ..lineTo(w * 0.38, h * 0.55)
      ..lineTo(w * 0.62, h * 0.55)
      ..lineTo(w * 0.68, h * 0.72)
      ..lineTo(w * 0.82, h * 0.72)
      ..lineTo(w * 0.72, h * 0.38)
      ..close();
    canvas.drawPath(body, paint);

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.7, w * 0.22, h * 0.3),
        Radius.circular(w * 0.1),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.56, h * 0.7, w * 0.22, h * 0.3),
        Radius.circular(w * 0.1),
      ),
      paint,
    );

    // Killer weapon (scythe shape)
    if (isKiller) {
      final weaponPaint = Paint()
        ..color = const Color(0xFFAAAAAA)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      Path scythe = Path()
        ..moveTo(w * 0.75, h * 0.42)
        ..lineTo(w * 1.1, h * 0.1)
        ..arcToPoint(Offset(w * 0.85, h * 0.05),
            radius: const Radius.circular(12), clockwise: false);
      canvas.drawPath(scythe, weaponPaint);
      // Blade
      final bladePaint = Paint()..color = const Color(0xFFCCCCCC);
      Path blade = Path()
        ..moveTo(w * 1.05, h * 0.12)
        ..lineTo(w * 0.82, h * 0.08)
        ..lineTo(w * 0.9, h * 0.22)
        ..close();
      canvas.drawPath(blade, bladePaint);
    }

    // Dead X eyes
    if (!isAlive) {
      final eyePaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(w * 0.38, h * 0.13), Offset(w * 0.46, h * 0.21), eyePaint);
      canvas.drawLine(
          Offset(w * 0.46, h * 0.13), Offset(w * 0.38, h * 0.21), eyePaint);
      canvas.drawLine(
          Offset(w * 0.54, h * 0.13), Offset(w * 0.62, h * 0.21), eyePaint);
      canvas.drawLine(
          Offset(w * 0.62, h * 0.13), Offset(w * 0.54, h * 0.21), eyePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) =>
      old.color != color || old.isAlive != isAlive;
}
