import 'dart:async';
import 'dart:math';
import '../models/player_model.dart';

class BotService {
  Timer? _botTimer;
  final Random _random = Random();

  // Bot state
  double _botX = 400;
  double _botY = 300;
  String _botState = 'patrol'; // patrol, chase, flee
  double _targetX = 400;
  double _targetY = 300;

  static const double mapWidth = 800;
  static const double mapHeight = 700;
  static const double botSpeed = 2.5;
  static const double chaseSpeed = 3.5;
  static const double detectionRange = 180;
  static const double attackRange = 50;

  double get botX => _botX;
  double get botY => _botY;

  void startBot({
    required Function(double x, double y) onMove,
    required Function(String targetUid) onAttack,
    required Function() onPatrolTask,
    required PlayerModel? playerToChase,
    required String botRole, // 'killer' or 'survivor'
  }) {
    _pickNewPatrolTarget();
    _botTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateBot(
        onMove: onMove,
        onAttack: onAttack,
        onPatrolTask: onPatrolTask,
        playerToChase: playerToChase,
        botRole: botRole,
      );
    });
  }

  void _updateBot({
    required Function(double x, double y) onMove,
    required Function(String targetUid) onAttack,
    required Function() onPatrolTask,
    required PlayerModel? playerToChase,
    required String botRole,
  }) {
    if (playerToChase == null) return;

    double dx = playerToChase.x - _botX;
    double dy = playerToChase.y - _botY;
    double dist = sqrt(dx * dx + dy * dy);

    if (botRole == 'killer') {
      // Killer bot: chase and attack survivors
      if (dist < detectionRange) {
        _botState = 'chase';
        if (dist < attackRange) {
          onAttack(playerToChase.uid);
          return;
        }
      } else {
        _botState = 'patrol';
      }
    } else {
      // Survivor bot: flee from killer, do tasks
      if (dist < detectionRange) {
        _botState = 'flee';
      } else {
        _botState = 'patrol';
        // Randomly complete a task
        if (_random.nextInt(200) == 0) {
          onPatrolTask();
        }
      }
    }

    _moveBot(onMove);
  }

  void _moveBot(Function(double x, double y) onMove) {
    double speed = _botState == 'chase' ? chaseSpeed : botSpeed;
    double dx, dy;

    if (_botState == 'flee') {
      // Move away from target
      dx = _botX - _targetX;
      dy = _botY - _targetY;
    } else {
      dx = _targetX - _botX;
      dy = _targetY - _botY;
    }

    double dist = sqrt(dx * dx + dy * dy);

    if (dist < 20) {
      _pickNewPatrolTarget();
      return;
    }

    double norm = dist > 0 ? dist : 1;
    _botX = (_botX + (dx / norm) * speed).clamp(40, mapWidth - 40);
    _botY = (_botY + (dy / norm) * speed).clamp(40, mapHeight - 40);

    // Add slight random wobble
    _botX += (_random.nextDouble() - 0.5) * 1.5;
    _botY += (_random.nextDouble() - 0.5) * 1.5;

    onMove(_botX, _botY);
  }

  void _pickNewPatrolTarget() {
    _targetX = 80 + _random.nextDouble() * (mapWidth - 160);
    _targetY = 80 + _random.nextDouble() * (mapHeight - 160);
  }

  void setChaseTarget(double x, double y) {
    _targetX = x;
    _targetY = y;
  }

  void stopBot() {
    _botTimer?.cancel();
    _botTimer = null;
  }

  void dispose() => stopBot();
}
