import 'package:flutter/material.dart';
import 'dart:math';

class Joystick extends StatefulWidget {
  final Function(double dx, double dy) onMove;
  final VoidCallback? onRelease;
  final double size;
  const Joystick({super.key, required this.onMove, this.onRelease, this.size = 120});
  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _pos = Offset.zero;
  bool _active = false;
  double get _max => widget.size / 2 - 20;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => setState(() => _active = true),
      onPanUpdate: (d) {
        final c = Offset(widget.size / 2, widget.size / 2);
        Offset raw = d.localPosition - c;
        double dist = raw.distance;
        Offset clamped = dist > _max ? raw * (_max / dist) : raw;
        setState(() => _pos = clamped);
        widget.onMove(clamped.dx / _max, clamped.dy / _max);
      },
      onPanEnd: (_) {
        setState(() { _pos = Offset.zero; _active = false; });
        widget.onRelease?.call();
        widget.onMove(0, 0);
      },
      child: Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 2),
        ),
        child: Stack(alignment: Alignment.center, children: [
          ...List.generate(4, (i) {
            double a = i * pi / 2;
            return Transform.translate(
              offset: Offset(cos(a) * (_max * 0.6), sin(a) * (_max * 0.6)),
              child: Container(width: 5, height: 5,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18))),
            );
          }),
          Transform.translate(
            offset: _pos,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _active
                    ? Colors.red.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.3),
                boxShadow: _active
                    ? [BoxShadow(color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 14, spreadRadius: 2)]
                    : [],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
