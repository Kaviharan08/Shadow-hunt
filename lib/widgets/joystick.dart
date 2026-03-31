import 'package:flutter/material.dart';
import 'dart:math';

class Joystick extends StatefulWidget {
  final Function(double dx, double dy) onMove;
  final VoidCallback? onRelease;
  final double size;

  const Joystick({
    super.key,
    required this.onMove,
    this.onRelease,
    this.size = 120,
  });

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _stickPos = Offset.zero;
  bool _active = false;

  double get _maxDist => widget.size / 2 - 20;

  void _onPanStart(DragStartDetails d) {
    setState(() => _active = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final center = Offset(widget.size / 2, widget.size / 2);
    Offset raw = d.localPosition - center;
    double dist = raw.distance;
    Offset clamped = dist > _maxDist ? raw * (_maxDist / dist) : raw;
    setState(() => _stickPos = clamped);
    widget.onMove(clamped.dx / _maxDist, clamped.dy / _maxDist);
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() { _stickPos = Offset.zero; _active = false; });
    widget.onRelease?.call();
    widget.onMove(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(4, (i) {
              double angle = i * pi / 2;
              return Transform.translate(
                offset: Offset(
                  cos(angle) * (_maxDist * 0.6),
                  sin(angle) * (_maxDist * 0.6),
                ),
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              );
            }),
            Transform.translate(
              offset: _stickPos,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _active
                      ? Colors.red.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.35),
                  boxShadow: _active
                      ? [BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 12, spreadRadius: 2)]
                      : [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}