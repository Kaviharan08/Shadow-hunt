import 'package:flutter/material.dart';
import 'dart:math';
import '../models/powerup.dart';
import '../models/hunter_type.dart';

// ── Map constants ────────────────────────────────────────────────────────────
const double kMapW = 1400;
const double kMapH = 1200;

// ── Large Horror Forest Map ──────────────────────────────────────────────────
class ForestMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawBase(canvas, size);
    _drawZones(canvas, size);
    _drawPaths(canvas, size);
    _drawTrees(canvas, size);
    _drawRocks(canvas, size);
    _drawBushes(canvas, size);
    _drawLighting(canvas, size);
  }

  void _drawBase(Canvas canvas, Size size) {
    final rng = Random(13);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF080F08));
    final p = Paint();
    for (int i = 0; i < 200; i++) {
      p.color = Color.lerp(
          const Color(0xFF0A140A), const Color(0xFF142014), rng.nextDouble())!;
      canvas.drawCircle(
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          6 + rng.nextDouble() * 22, p);
    }
  }

  void _drawZones(Canvas canvas, Size size) {
    // Darker clearing zones for atmosphere
    final p = Paint()..color = const Color(0xFF060C06);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.5),
            width: 340, height: 260), p);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.2, size.height * 0.8),
            width: 220, height: 180), p);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.8, size.height * 0.3),
            width: 200, height: 160), p);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.15, size.height * 0.2),
            width: 180, height: 140), p);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.85, size.height * 0.75),
            width: 200, height: 160), p);
  }

  void _drawPaths(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF140E06)
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Main cross paths
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), p);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), p);
    // Diagonal paths
    p.strokeWidth = 22;
    canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.35, size.height * 0.35), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width * 0.65, size.height * 0.35), p);
    canvas.drawLine(Offset(0, size.height), Offset(size.width * 0.35, size.height * 0.65), p);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width * 0.65, size.height * 0.65), p);
    // Side paths
    p.strokeWidth = 18;
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), p);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), p);
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), p);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), p);
  }

  void _drawTrees(Canvas canvas, Size size) {
    final rng = Random(42);
    final trunk = Paint()..color = const Color(0xFF1E1006);
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.35);

    // Dense tree border + scattered interior
    List<List<double>> trees = [];
    // Borders
    for (int i = 0; i < 60; i++) {
      trees.add([rng.nextDouble() * size.width, rng.nextDouble() * 80]);
      trees.add([rng.nextDouble() * size.width, size.height - rng.nextDouble() * 80]);
      trees.add([rng.nextDouble() * 80, rng.nextDouble() * size.height]);
      trees.add([size.width - rng.nextDouble() * 80, rng.nextDouble() * size.height]);
    }
    // Interior scatter
    for (int i = 0; i < 80; i++) {
      trees.add([80 + rng.nextDouble() * (size.width - 160),
                 80 + rng.nextDouble() * (size.height - 160)]);
    }

    for (var t in trees) {
      double x = t[0], y = t[1];
      double s = 0.5 + rng.nextDouble() * 0.8;
      // Shadow
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x + 5 * s, y + 20 * s),
              width: 26 * s, height: 9 * s), shadow);
      // Trunk
      canvas.drawRect(Rect.fromCenter(
          center: Offset(x, y + 13 * s), width: 7 * s, height: 18 * s), trunk);
      // Foliage layers
      for (int layer = 0; layer < 3; layer++) {
        double ly = y - layer * 11 * s;
        double lr = (20 - layer * 3) * s;
        final leaf = Paint()
          ..color = Color.lerp(
              const Color(0xFF0A1E0A),
              const Color(0xFF163016),
              rng.nextDouble())!;
        canvas.drawCircle(Offset(x, ly), lr, leaf);
        canvas.drawCircle(Offset(x, ly), lr * 0.65,
            Paint()..color = const Color(0xFF080C08).withValues(alpha: 0.7));
      }
    }
  }

  void _drawRocks(Canvas canvas, Size size) {
    final rng = Random(99);
    const rocks = [
      [200.0, 380.0, 22.0], [560.0, 260.0, 16.0], [820.0, 540.0, 24.0],
      [340.0, 660.0, 14.0], [720.0, 420.0, 18.0], [480.0, 820.0, 20.0],
      [1050.0, 300.0, 15.0], [160.0, 920.0, 19.0], [1150.0, 750.0, 17.0],
      [900.0, 980.0, 21.0], [640.0, 1050.0, 13.0], [1250.0, 480.0, 16.0],
    ];
    for (var r in rocks) {
      canvas.drawOval(Rect.fromCenter(
          center: Offset(r[0], r[1]), width: r[2] * 2.3, height: r[2] * 1.4),
          Paint()..color = const Color(0xFF252525));
      canvas.drawOval(Rect.fromCenter(
          center: Offset(r[0] - 3, r[1] - 3), width: r[2] * 0.9, height: r[2] * 0.5),
          Paint()..color = const Color(0xFF353535));
    }
  }

  void _drawBushes(Canvas canvas, Size size) {
    final rng = Random(77);
    for (int i = 0; i < 60; i++) {
      double x = 60 + rng.nextDouble() * (size.width - 120);
      double y = 60 + rng.nextDouble() * (size.height - 120);
      double r = 8 + rng.nextDouble() * 14;
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = Color.lerp(
              const Color(0xFF0C1A0C), const Color(0xFF142814),
              rng.nextDouble())!);
    }
  }

  void _drawLighting(Canvas canvas, Size size) {
    // Vignette
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.transparent, const Color(0xFF020602).withValues(alpha: 0.75)],
            stops: const [0.45, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    // Fog wisps
    final fogPaint = Paint()
      ..color = const Color(0xFF0A1A0A).withValues(alpha: 0.2);
    final rng = Random(55);
    for (int i = 0; i < 8; i++) {
      canvas.drawOval(Rect.fromCenter(
          center: Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          width: 120 + rng.nextDouble() * 200,
          height: 40 + rng.nextDouble() * 60), fogPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Task Marker ──────────────────────────────────────────────────────────────
class TaskMarker extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback? onTap;
  const TaskMarker({super.key, this.isCompleted = false, this.onTap});
  @override
  State<TaskMarker> createState() => _TaskMarkerState();
}

class _TaskMarkerState extends State<TaskMarker> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return Container(width: 30, height: 30,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
          child: const Icon(Icons.check, color: Colors.white, size: 18));
    }
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Transform.scale(
          scale: _pulse.value,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.amber.shade700,
              boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.7),
                  blurRadius: 12, spreadRadius: 3)],
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Powerup Widget ───────────────────────────────────────────────────────────
class PowerupWidget extends StatefulWidget {
  final PowerupType type;
  final VoidCallback? onCollect;
  const PowerupWidget({super.key, required this.type, this.onCollect});
  @override
  State<PowerupWidget> createState() => _PowerupWidgetState();
}

class _PowerupWidgetState extends State<PowerupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  Color get _color {
    switch (widget.type) {
      case PowerupType.speedBoost:   return Colors.yellow;
      case PowerupType.invisibility: return Colors.purple;
      case PowerupType.healthPack:   return Colors.green;
      case PowerupType.flashbang:    return Colors.orange;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case PowerupType.speedBoost:   return Icons.bolt;
      case PowerupType.invisibility: return Icons.visibility_off;
      case PowerupType.healthPack:   return Icons.favorite;
      case PowerupType.flashbang:    return Icons.flash_on;
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -4, end: 4).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCollect,
      child: AnimatedBuilder(
        animation: _float,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _float.value),
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.2),
              border: Border.all(color: _color.withValues(alpha: 0.8), width: 2),
              boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.5),
                  blurRadius: 10, spreadRadius: 2)],
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
        ),
      ),
    );
  }
}

// ── Trap Widget ──────────────────────────────────────────────────────────────
class TrapWidget extends StatelessWidget {
  final bool isTriggered;
  const TrapWidget({super.key, this.isTriggered = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isTriggered
            ? Colors.grey.withValues(alpha: 0.3)
            : const Color(0xFF8B4513).withValues(alpha: 0.8),
        border: Border.all(
            color: isTriggered ? Colors.grey : Colors.brown, width: 2),
      ),
      child: Icon(Icons.dangerous,
          color: isTriggered ? Colors.grey : Colors.orange, size: 16),
    );
  }
}

// ── Silhouette Player ────────────────────────────────────────────────────────
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
    super.key, this.isKiller = false, this.isMe = false,
    this.isAlive = true, this.isInvisible = false,
    required this.username, this.hunterType = 'stalker',
    this.health = 100, this.size = 38,
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
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    _bob = Tween<double>(begin: -2, end: 2).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _killerColor {
    final data = HunterTypeData.all[HunterType.values.firstWhere(
        (e) => e.name == widget.hunterType,
        orElse: () => HunterType.stalker)];
    return data?.color ?? Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    Color color = widget.isKiller ? _killerColor
        : (widget.isMe ? Colors.white : const Color(0xFF88BBFF));
    if (!widget.isAlive) color = color.withValues(alpha: 0.3);
    if (widget.isInvisible && !widget.isMe) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _bob,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _bob.value),
        child: Opacity(
          opacity: widget.isInvisible ? 0.25 : 1.0,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Health bar (for non-killers)
            if (!widget.isKiller && widget.isAlive)
              Container(
                width: widget.size * 1.1, height: 4,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  widthFactor: widget.health / 100,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.health > 60 ? Colors.green
                          : widget.health > 30 ? Colors.orange : Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            if (widget.isMe)
              Container(
                width: widget.size + 12, height: widget.size + 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                ),
              ),
            CustomPaint(
              size: Size(widget.size, widget.size * 1.6),
              painter: _SilhouettePainter(
                  color: color, isKiller: widget.isKiller,
                  isAlive: widget.isAlive, hunterType: widget.hunterType),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(widget.username,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final Color color;
  final bool isKiller, isAlive;
  final String hunterType;
  _SilhouettePainter({required this.color, required this.isKiller,
      required this.isAlive, required this.hunterType});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    double w = size.width, h = size.height;
    // Head
    canvas.drawCircle(Offset(w / 2, h * 0.17), w * 0.21, p);
    // Body
    Path body = Path()
      ..moveTo(w * 0.28, h * 0.36)..lineTo(w * 0.18, h * 0.70)
      ..lineTo(w * 0.33, h * 0.70)..lineTo(w * 0.38, h * 0.54)
      ..lineTo(w * 0.62, h * 0.54)..lineTo(w * 0.67, h * 0.70)
      ..lineTo(w * 0.82, h * 0.70)..lineTo(w * 0.72, h * 0.36)..close();
    canvas.drawPath(body, p);
    // Legs
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.68, w * 0.22, h * 0.32), Radius.circular(w * 0.1)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.56, h * 0.68, w * 0.22, h * 0.32), Radius.circular(w * 0.1)), p);

    if (isKiller) _drawWeapon(canvas, size);
    if (!isAlive) _drawDeadEyes(canvas, size);
    if (isKiller) _drawHunterEffect(canvas, size);
  }

  void _drawWeapon(Canvas canvas, Size size) {
    double w = size.width, h = size.height;
    switch (hunterType) {
      case 'rusher':
        // Lightning bolt
        final wp = Paint()..color = Colors.yellow..strokeWidth = 3
            ..style = PaintingStyle.stroke;
        Path bolt = Path()
          ..moveTo(w * 0.82, h * 0.28)..lineTo(w * 1.05, h * 0.15)
          ..lineTo(w * 0.95, h * 0.30)..lineTo(w * 1.18, h * 0.18);
        canvas.drawPath(bolt, wp);
        break;
      case 'trapper':
        // Bear trap
        final tp = Paint()..color = Colors.brown..strokeWidth = 2.5
            ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(w * 1.05, h * 0.22), w * 0.18, tp);
        canvas.drawLine(Offset(w * 0.88, h * 0.22), Offset(w * 1.22, h * 0.22), tp);
        break;
      case 'berserk':
        // Big axe
        final ap = Paint()..color = const Color(0xFFCC4400);
        Path axe = Path()
          ..moveTo(w * 0.78, h * 0.38)..lineTo(w * 1.08, h * 0.08)
          ..lineTo(w * 1.20, h * 0.18)..lineTo(w * 1.02, h * 0.32)..close();
        canvas.drawPath(axe, ap);
        canvas.drawLine(Offset(w * 0.78, h * 0.38), Offset(w * 1.08, h * 0.08),
            Paint()..color = const Color(0xFF661A00)..strokeWidth = 3
                ..style = PaintingStyle.stroke);
        break;
      default: // stalker — scythe
        final wp = Paint()..color = const Color(0xFFAAAAAA)..strokeWidth = 2.5
            ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * 0.78, h * 0.40), Offset(w * 1.08, h * 0.08), wp);
        final bp = Paint()..color = const Color(0xFFCCCCCC);
        Path blade = Path()
          ..moveTo(w * 1.04, h * 0.10)..lineTo(w * 0.84, h * 0.06)
          ..lineTo(w * 0.91, h * 0.20)..close();
        canvas.drawPath(blade, bp);
    }
  }

  void _drawHunterEffect(Canvas canvas, Size size) {
    double w = size.width, h = size.height;
    switch (hunterType) {
      case 'stalker':
        // Purple glow eyes
        canvas.drawCircle(Offset(w * 0.41, h * 0.155), 3,
            Paint()..color = Colors.purple.withValues(alpha: 0.9));
        canvas.drawCircle(Offset(w * 0.59, h * 0.155), 3,
            Paint()..color = Colors.purple.withValues(alpha: 0.9));
        break;
      case 'rusher':
        // Orange glow
        canvas.drawCircle(Offset(w * 0.41, h * 0.155), 3,
            Paint()..color = Colors.orange);
        canvas.drawCircle(Offset(w * 0.59, h * 0.155), 3,
            Paint()..color = Colors.orange);
        break;
      case 'berserk':
        // Red glowing eyes
        for (var pos in [Offset(w * 0.41, h * 0.155), Offset(w * 0.59, h * 0.155)]) {
          canvas.drawCircle(pos, 4,
              Paint()..color = Colors.red..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        }
        break;
      default:
        break;
    }
  }

  void _drawDeadEyes(Canvas canvas, Size size) {
    double w = size.width, h = size.height;
    final p = Paint()..color = Colors.red..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.37, h * 0.12), Offset(w * 0.46, h * 0.21), p);
    canvas.drawLine(Offset(w * 0.46, h * 0.12), Offset(w * 0.37, h * 0.21), p);
    canvas.drawLine(Offset(w * 0.54, h * 0.12), Offset(w * 0.63, h * 0.21), p);
    canvas.drawLine(Offset(w * 0.63, h * 0.12), Offset(w * 0.54, h * 0.21), p);
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) =>
      old.color != color || old.isAlive != isAlive;
}
