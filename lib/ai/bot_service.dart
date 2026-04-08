import 'dart:async';
import 'dart:math';
import '../models/player_model.dart';

class BotService {
  Timer? _timer;
  final Random _rng = Random();
  double _x = 400, _y = 400;
  double _tx = 400, _ty = 400;
  String _state = 'patrol';

  // Stored params for resume
  String? _role;
  Function(double x, double y)? _onMove;
  Function(String uid)? _onAttack;
  Function()? _onTask;
  PlayerModel? _target;
  double _speed = 3.0;

  static const double mapW = 1400;
  static const double mapH = 1200;

  double get x => _x;
  double get y => _y;

  void start({
    required String role,
    required Function(double x, double y) onMove,
    required Function(String uid) onAttack,
    required Function() onTask,
    required PlayerModel? target,
    double speed = 3.0,
  }) {
    _role = role;
    _onMove = onMove;
    _onAttack = onAttack;
    _onTask = onTask;
    _target = target;
    _speed = speed;
    _pickPatrol();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _tick(
          role: _role!,
          onMove: _onMove!,
          onAttack: _onAttack!,
          onTask: _onTask!,
          target: _target,
          speed: _speed);
    });
  }

  void _tick({
    required String role,
    required Function(double x, double y) onMove,
    required Function(String uid) onAttack,
    required Function() onTask,
    required PlayerModel? target,
    required double speed,
  }) {
    if (target == null) return;
    double dx = target.x - _x, dy = target.y - _y;
    double dist = sqrt(dx * dx + dy * dy);

    if (role == 'killer') {
      _state = dist < 200 ? 'chase' : 'patrol';
      if (dist < 55) {
        onAttack(target.uid);
        return;
      }
    } else {
      _state = dist < 180 ? 'flee' : 'patrol';
      if (_state == 'patrol' && _rng.nextInt(180) == 0) onTask();
    }

    _move(onMove, speed);
  }

  void _move(Function(double, double) onMove, double speed) {
    double spd = _state == 'chase' ? speed * 1.3 : speed;
    double dx = _state == 'flee' ? _x - _tx : _tx - _x;
    double dy = _state == 'flee' ? _y - _ty : _ty - _y;
    double d = sqrt(dx * dx + dy * dy);
    if (d < 15) {
      _pickPatrol();
      return;
    }
    _x = (_x + (dx / d) * spd + (_rng.nextDouble() - 0.5))
        .clamp(50.0, mapW - 50.0)
        .toDouble();
    _y = (_y + (dy / d) * spd + (_rng.nextDouble() - 0.5))
        .clamp(50.0, mapH - 50.0)
        .toDouble();
    onMove(_x, _y);
  }

  void _pickPatrol() {
    _tx = 80 + _rng.nextDouble() * (mapW - 160);
    _ty = 80 + _rng.nextDouble() * (mapH - 160);
  }

  void updateTarget(double x, double y) {
    _tx = x;
    _ty = y;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    if (_role != null) _startTimer();
  }

  void dispose() => stop();
}
