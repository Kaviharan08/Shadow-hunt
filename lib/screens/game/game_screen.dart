import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ai/bot_service.dart';
import '../../models/hunter_type.dart';
import '../../models/player_model.dart';
import '../../models/powerup.dart';
import '../../models/room_model.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../../widgets/forest_map.dart';
import '../../widgets/joystick.dart';
import '../gameover_screen.dart';

class GameScreen extends StatefulWidget {
  final RoomModel room;
  final String myUid;
  final bool isSolo;
  const GameScreen({super.key, required this.room, required this.myUid, required this.isSolo});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameService _gs = GameService();

  static const double _mapW = kMapW;
  static const double _mapH = kMapH;

  RoomModel? _room;
  String _myRole = 'survivor';
  String _myHunterType = 'stalker';
  int _myHealth = 100;
  double _myX = 500;
  double _myY = 500;
  double _jDx = 0;
  double _jDy = 0;
  double _camX = 0;
  double _camY = 0;

  int _round = 1;
  String _phase = 'round1';
  DateTime? _portalDeadline;
  final Offset _portalPosition = const Offset(700, 600);
  bool _enteredPortalLocal = false;

  final List<PlayerModel> _bots = [];
  final List<BotService> _botServices = [];
  final List<Trap> _traps = [];
  List<TaskModel> _tasks = TaskModel.getTasksForRound(1, 3);
  List<Powerup> _powerups = Powerup.generateForMap();

  TaskModel? _activeTask;
  bool _taskInProgress = false;
  int? _selectedAnswer;
  bool _answerChecked = false;
  bool _answerCorrect = false;
  TaskModel? _nearbyTask;

  final List<ActiveEffect> _effects = [];
  bool get _hasSpeedBoost => _effects.any((e) => e.type == PowerupType.speedBoost && e.isActive);
  bool get _hasInvisibility => _effects.any((e) => e.type == PowerupType.invisibility && e.isActive);
  bool _killerBlinded = false;

  bool _abilityReady = true;
  bool _abilityActive = false;
  double _abilityCooldown = 1.0;
  Timer? _cooldownTimer;

  bool _canAttack = true;
  final double _attackRange = 75;
  bool _hitFlash = false;
  final List<Offset> _splatters = [];

  Timer? _moveLoop;
  Timer? _proximityLoop;
  Timer? _effectsLoop;
  Timer? _portalLoop;
  StreamSubscription? _roomStream;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    final me = widget.room.players[widget.myUid];
    _myRole = me?.role ?? 'survivor';
    _myHunterType = me?.hunterType ?? 'stalker';
    _myX = me?.x ?? 500;
    _myY = me?.y ?? 500;
    _myHealth = me?.health ?? 100;
    _round = widget.room.round;
    _phase = widget.room.phase;
    _applyRoundSetup(initial: true);

    if (widget.isSolo) {
      _setupBots();
    } else {
      _roomStream = _gs.streamRoom(widget.room.roomId).listen(_onRoom);
    }

    _moveLoop = Timer.periodic(const Duration(milliseconds: 16), _move);
    _proximityLoop = Timer.periodic(const Duration(milliseconds: 100), _checkProximity);
    _effectsLoop = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final invisActive = _hasInvisibility || (_myRole == 'killer' && _myHunterType == 'stalker' && _abilityActive);
      if (!widget.isSolo) {
        _gs.updateInvisibility(widget.room.roomId, widget.myUid, invisActive);
      }
      if (mounted) setState(() => _effects.removeWhere((e) => !e.isActive));
    });
    _portalLoop = Timer.periodic(const Duration(seconds: 1), (_) => _tickPortal());
  }

  void _applyRoundSetup({bool initial = false}) {
    final survivorCount = widget.isSolo
        ? max(1, _bots.where((b) => b.role == 'survivor' && b.isAlive).length + (_myRole == 'survivor' ? 1 : 0))
        : max(1, (_room?.players.values.where((p) => p.role == 'survivor' && p.isAlive).length ?? 1));
    _tasks = TaskModel.getTasksForRound(_round, survivorCount);
    _powerups = Powerup.generateForMap();
    if (_round == 2) {
      _powerups = [
        ..._powerups,
        Powerup(id: 'r2_extra_1', type: PowerupType.flashbang, position: const Offset(220, 250)),
        Powerup(id: 'r2_extra_2', type: PowerupType.healthPack, position: const Offset(1080, 940)),
      ];
    }
    if (!initial) {
      _activeTask = null;
      _taskInProgress = false;
      _nearbyTask = null;
      _enteredPortalLocal = false;
      _showMsg(_round == 2 ? '🔥 Round 2 started — harder map, more tasks!' : '🧪 Round 1 started', _round == 2 ? ToxicTheme.purple : ToxicTheme.green);
    }
  }

  void _setupBots() {
    final rng = Random();
    final botRoles = _myRole == 'killer' ? ['survivor', 'survivor', 'survivor'] : ['killer', 'survivor', 'survivor'];
    for (int i = 0; i < 3; i++) {
      _bots.add(PlayerModel(
        uid: 'bot_$i',
        username: ['Ghost', 'Shadow', 'Wraith'][i],
        role: botRoles[i],
        hunterType: HunterType.values[i % 4].name,
        x: 150 + rng.nextDouble() * 1000,
        y: 150 + rng.nextDouble() * 800,
        isBot: true,
        health: 100,
        totalTasks: i == 0 && botRoles[i] == 'killer' ? 0 : 3,
      ));
    }

    for (int i = 0; i < _bots.length; i++) {
      final bs = BotService();
      bs.start(
        role: _bots[i].role,
        speed: _bots[i].role == 'killer' ? 2.8 : 2.4,
        onMove: (x, y) {
          if (!mounted) return;
          setState(() => _bots[i] = _bots[i].copyWith(x: x, y: y));
        },
        onAttack: (_) {},
        onTask: () {
          if (!mounted) return;
          if (_bots[i].role == 'survivor' && _bots[i].tasksCompleted < _bots[i].totalTasks && _phase.startsWith('round')) {
            setState(() => _bots[i] = _bots[i].copyWith(tasksCompleted: _bots[i].tasksCompleted + 1));
            _checkSoloWin();
          }
        },
        target: PlayerModel(uid: widget.myUid, username: 'YOU', x: _myX, y: _myY),
      );
      _botServices.add(bs);
    }
  }

  void _move(Timer _) {
    if (!mounted || (_jDx == 0 && _jDy == 0)) return;
    double speed = 4.5;
    if (_myRole == 'killer') {
      final td = HunterTypeData.all[HunterType.values.firstWhere((e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];
      speed = td?.baseSpeed ?? 4.5;
      if (_myHunterType == 'rusher' && _abilityActive) speed *= 2.8;
      if (_round == 2) speed *= 1.08;
    } else if (_hasSpeedBoost) {
      speed = 7.0;
    }

    final double nx = (_myX + _jDx * speed).clamp(20.0, _mapW - 20.0).toDouble();
    final double ny = (_myY + _jDy * speed).clamp(20.0, _mapH - 20.0).toDouble();
    setState(() {
      _myX = nx;
      _myY = ny;
      final size = MediaQuery.of(context).size;
      _camX = (_myX - size.width / 2).clamp(0.0, max(0.0, _mapW - size.width)).toDouble();
      _camY = (_myY - size.height / 2).clamp(0.0, max(0.0, _mapH - size.height)).toDouble();
    });
    if (!widget.isSolo) _gs.updatePosition(widget.room.roomId, widget.myUid, _myX, _myY);
    for (final bs in _botServices) {
      bs.updateTarget(_myX, _myY);
    }
  }

  void _checkProximity(Timer _) {
    if (!mounted) return;

    if (_phase == 'portal') {
      final dPortal = _distance(_myX, _myY, _portalPosition.dx, _portalPosition.dy);
      if (_myRole == 'survivor' && dPortal < 68 && !_enteredPortalLocal) {
        _enterPortal();
      }
    }

    if (_myRole == 'survivor' && _phase.startsWith('round')) {
      for (final pu in _powerups) {
        if (pu.isCollected) continue;
        if (_distance(_myX, _myY, pu.position.dx, pu.position.dy) < 42) {
          _collectPowerup(pu);
          break;
        }
      }
    }

    if (_myRole == 'survivor') {
      for (final trap in _traps) {
        if (trap.isTriggered) continue;
        if (_distance(_myX, _myY, trap.position.dx, trap.position.dy) < 36) {
          setState(() => trap.isTriggered = true);
          _takeDamage(20);
          _showMsg('🪤 Trap! -20HP', ToxicTheme.red);
        }
      }
    }

    if (_myRole == 'survivor' && _phase.startsWith('round')) {
      TaskModel? closeTask;
      for (final task in _tasks.where((t) => !t.isCompleted)) {
        if (_distance(_myX, _myY, task.position.dx, task.position.dy) < 72) {
          closeTask = task;
          break;
        }
      }
      if (closeTask?.taskId != _nearbyTask?.taskId) {
        setState(() => _nearbyTask = closeTask);
      }
    } else if (_nearbyTask != null) {
      setState(() => _nearbyTask = null);
    }

    if (widget.isSolo && _myRole == 'survivor' && _phase.startsWith('round')) {
      for (final bot in _bots) {
        if (!bot.isAlive || bot.role != 'killer') continue;
        if (_distance(_myX, _myY, bot.x, bot.y) < 55) _takeDamage(_round == 2 ? 7 : 6);
      }
    }
  }

  Future<void> _tickPortal() async {
    if (!mounted || _phase != 'portal') return;
    if (!widget.isSolo) {
      await _gs.checkPortalProgress(widget.room.roomId);
      return;
    }
    if (_portalDeadline == null) return;
    if (DateTime.now().isAfter(_portalDeadline!)) {
      for (int i = 0; i < _bots.length; i++) {
        if (_bots[i].role == 'survivor' && !_bots[i].portalEntered) {
          _bots[i] = _bots[i].copyWith(health: 0, isAlive: false);
        }
      }
      if (_myRole == 'survivor' && !_enteredPortalLocal) {
        _takeDamage(999);
      }
      final anySurvivor = _enteredPortalLocal || _bots.any((b) => b.role == 'survivor' && b.portalEntered && b.isAlive);
      if (!anySurvivor) {
        _goOver('killer');
      } else {
        _startRoundTwoSolo();
      }
    }
  }

  void _onRoom(RoomModel? room) {
    if (room == null || !mounted) return;
    final me = room.players[widget.myUid];
    if (me != null && me.health < _myHealth) _showHitFlash();

    final roundChanged = room.round != _round;
    final phaseChanged = room.phase != _phase;
    setState(() {
      _room = room;
      _round = room.round;
      _phase = room.phase;
      if (me != null) {
        _myHealth = me.health;
        _myRole = me.role;
        _myHunterType = me.hunterType;
        _enteredPortalLocal = me.portalEntered;
      }
      _portalDeadline = room.portalDeadlineMs != null ? DateTime.fromMillisecondsSinceEpoch(room.portalDeadlineMs!) : null;
    });
    if (roundChanged) _applyRoundSetup();
    if (phaseChanged && _phase == 'portal') _showMsg('🌀 Portal opened! Enter within 2 minutes or die.', ToxicTheme.cyan);
    if (room.status == 'finished') _goOver(room.winnerRole ?? 'survivors');
    if (me != null && !me.isAlive && room.status != 'finished') _goOver('killer');
  }

  Future<void> _enterPortal() async {
    if (_enteredPortalLocal || _myRole != 'survivor') return;
    setState(() => _enteredPortalLocal = true);
    _showMsg('🌀 Portal entered. Waiting for round 2...', ToxicTheme.cyan);
    if (widget.isSolo) return;
    await _gs.enterPortal(widget.room.roomId, widget.myUid);
  }

  void _startRoundTwoSolo() {
    setState(() {
      _round = 2;
      _phase = 'round2';
      _portalDeadline = null;
      _myHealth = min(100, _myHealth + 15);
      _myX = 240;
      _myY = 220;
      _enteredPortalLocal = false;
      final survivorsAlive = max(1, _bots.where((b) => b.role == 'survivor' && b.isAlive && b.portalEntered).length + (_myRole == 'survivor' && _myHealth > 0 ? 1 : 0));
      _tasks = TaskModel.getTasksForRound(2, survivorsAlive);
      for (int i = 0; i < _bots.length; i++) {
        if (_bots[i].role == 'survivor') {
          _bots[i] = _bots[i].copyWith(tasksCompleted: 0, totalTasks: _tasks.length, portalEntered: false);
        }
      }
      _powerups = Powerup.generateForMap();
    });
    _applyRoundSetup();
  }

  double _distance(double ax, double ay, double bx, double by) => sqrt(pow(ax - bx, 2) + pow(ay - by, 2)).toDouble();

  Future<void> _syncHealth() async {
    if (!widget.isSolo) await _gs.updateHealth(widget.room.roomId, widget.myUid, _myHealth);
  }

  void _takeDamage(int dmg) {
    if (_hasInvisibility) return;
    final int newHp = (_myHealth - dmg).clamp(0, 100).toInt();
    setState(() => _myHealth = newHp);
    _showHitFlash();
    _syncHealth();
    if (newHp <= 0) _goOver('killer');
  }

  void _showHitFlash() {
    setState(() => _hitFlash = true);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _hitFlash = false);
    });
  }

  Future<void> _attack() async {
    if (!_canAttack || _myRole != 'killer' || !_phase.startsWith('round')) return;
    setState(() => _canAttack = false);
    final td = HunterTypeData.all[HunterType.values.firstWhere((e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];
    int dmg = td?.baseDamage ?? 34;
    if (_myHunterType == 'berserk' && _abilityActive) {
      dmg = 100;
      setState(() => _abilityActive = false);
    }
    if (_round == 2) dmg = (dmg * 1.15).round();

    bool hit = false;
    if (widget.isSolo) {
      for (int i = 0; i < _bots.length; i++) {
        final b = _bots[i];
        if (!b.isAlive || b.role != 'survivor' || b.isInvisible) continue;
        if (_distance(_myX, _myY, b.x, b.y) < _attackRange) {
          final int newHp = (b.health - dmg).clamp(0, 100).toInt();
          setState(() {
            _bots[i] = b.copyWith(health: newHp, isAlive: newHp > 0);
            _splatters.add(Offset(b.x - _camX, b.y - _camY));
          });
          hit = true;
          _checkSoloWin();
        }
      }
    } else if (_room != null) {
      for (final p in _room!.players.values) {
        if (p.uid == widget.myUid || !p.isAlive || p.role != 'survivor' || p.isInvisible) continue;
        if (_distance(_myX, _myY, p.x, p.y) < _attackRange) {
          await _gs.attackPlayer(widget.room.roomId, p.uid, dmg);
          hit = true;
        }
      }
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _splatters.clear());
    });
    _showMsg(hit ? '🩸 HIT! -$dmg' : '❌ Miss — get closer!', hit ? ToxicTheme.red : ToxicTheme.greenDim);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _canAttack = true);
    });
  }

  void _useAbility() {
    if (!_abilityReady) return;
    final td = HunterTypeData.all[HunterType.values.firstWhere((e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];
    if (td == null) return;
    setState(() {
      _abilityReady = false;
      _abilityActive = true;
    });

    switch (_myHunterType) {
      case 'stalker':
        _showMsg('👻 VANISH — 4s', td.color);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _abilityActive = false);
        });
        break;
      case 'rusher':
        _showMsg('⚡ SURGE — 3s', td.color);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _abilityActive = false);
        });
        break;
      case 'trapper':
        setState(() {
          _traps.add(Trap(id: 'trap_${DateTime.now().millisecondsSinceEpoch}', position: Offset(_myX, _myY)));
          _abilityActive = false;
        });
        _showMsg('🪤 Trap placed!', td.color);
        break;
      case 'berserk':
        _showMsg('💢 RAGE — one-shot!', td.color);
        break;
    }

    double step = 1.0 / (td.abilityCooldownSec * 20.0);
    setState(() => _abilityCooldown = 0);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _abilityCooldown = (_abilityCooldown + step).clamp(0.0, 1.0).toDouble());
      if (_abilityCooldown >= 1.0) {
        t.cancel();
        if (mounted) setState(() => _abilityReady = true);
      }
    });
  }

  void _collectPowerup(Powerup pu) {
    setState(() => pu.isCollected = true);
    switch (pu.type) {
      case PowerupType.speedBoost:
        _addEffect(PowerupType.speedBoost, 5);
        _showMsg('⚡ Speed Boost 5s!', ToxicTheme.green);
        break;
      case PowerupType.invisibility:
        _addEffect(PowerupType.invisibility, 5);
        _showMsg('👻 Invisible 5s!', Colors.purple);
        break;
      case PowerupType.healthPack:
        setState(() => _myHealth = (_myHealth + 40).clamp(0, 100).toInt());
        _syncHealth();
        _showMsg('💉 +40 HP!', ToxicTheme.red);
        break;
      case PowerupType.flashbang:
        setState(() => _killerBlinded = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _killerBlinded = false);
        });
        _showMsg('💥 Flashbang! Killer blinded 3s!', Colors.orange);
        break;
    }
    Future.delayed(const Duration(seconds: 18), () {
      if (mounted) setState(() => pu.isCollected = false);
    });
  }

  void _addEffect(PowerupType type, int secs) {
    _effects.removeWhere((e) => e.type == type);
    _effects.add(ActiveEffect(type: type, expiresAt: DateTime.now().add(Duration(seconds: secs))));
  }

  void _startTask(TaskModel task) {
    if (_myRole != 'survivor' || _phase == 'portal') return;
    setState(() {
      _activeTask = task;
      _taskInProgress = true;
      _selectedAnswer = null;
      _answerChecked = false;
      _answerCorrect = false;
    });
  }

  void _selectAnswer(int idx) {
    if (_answerChecked || _activeTask == null) return;
    setState(() {
      _selectedAnswer = idx;
      _answerChecked = true;
      _answerCorrect = idx == _activeTask!.quiz!.correctIndex;
    });
    if (_answerCorrect) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _activeTask != null) _finishTask(_activeTask!);
      });
    } else {
      _takeDamage(_round == 2 ? 15 : 10);
      _showMsg('❌ Wrong! -${_round == 2 ? 15 : 10} HP', ToxicTheme.red);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _selectedAnswer = null;
            _answerChecked = false;
          });
        }
      });
    }
  }

  Future<void> _finishTask(TaskModel task) async {
    final idx = _tasks.indexWhere((t) => t.taskId == task.taskId);
    if (idx >= 0) setState(() => _tasks[idx].isCompleted = true);
    setState(() {
      _taskInProgress = false;
      _activeTask = null;
      _nearbyTask = null;
    });
    if (!widget.isSolo) {
      await _gs.completeTask(widget.room.roomId, widget.myUid);
    } else {
      if (_tasks.every((t) => t.isCompleted)) {
        if (_round == 1) {
          setState(() {
            _phase = 'portal';
            _portalDeadline = DateTime.now().add(const Duration(minutes: 2));
          });
          _showMsg('🌀 Portal opened! Enter within 2 minutes.', ToxicTheme.cyan);
        } else {
          _goOver('survivors');
        }
      }
    }
    _showMsg('✅ Task complete!', ToxicTheme.green);
  }

  void _checkSoloWin() {
    final survivors = _bots.where((b) => b.role == 'survivor').toList();
    if (_myRole == 'killer' && survivors.every((b) => !b.isAlive)) {
      _goOver('killer');
      return;
    }
    if (_myRole == 'survivor' && _myHealth <= 0) {
      _goOver('killer');
    }
  }

  void _goOver(String winner) {
    if (!mounted) return;
    _moveLoop?.cancel();
    _proximityLoop?.cancel();
    _effectsLoop?.cancel();
    _cooldownTimer?.cancel();
    _portalLoop?.cancel();
    _roomStream?.cancel();
    for (final bs in _botServices) {
      bs.stop();
      bs.dispose();
    }

    final killerName = widget.isSolo
        ? (_bots.firstWhere((b) => b.role == 'killer', orElse: () => PlayerModel(uid: '', username: 'Shadow')).username)
        : (_room?.players.values.firstWhere((p) => p.role == 'killer', orElse: () => PlayerModel(uid: '', username: 'Unknown')).username ?? 'Unknown');

    context.read<AuthService>().updateStats(won: (winner == 'killer' && _myRole == 'killer') || (winner == 'survivors' && _myRole == 'survivor'));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameOverScreen(winnerRole: winner, myRole: _myRole, killerName: killerName)),
    );
  }

  void _showMsg(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        backgroundColor: color.withOpacity(0.92),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _moveLoop?.cancel();
    _proximityLoop?.cancel();
    _effectsLoop?.cancel();
    _portalLoop?.cancel();
    _cooldownTimer?.cancel();
    _roomStream?.cancel();
    for (final bs in _botServices) {
      bs.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_taskInProgress && _activeTask != null) return _buildQuiz(_activeTask!);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildWorld(),
          if (_hitFlash) Container(color: ToxicTheme.red.withOpacity(0.25)),
          if (_killerBlinded && _myRole == 'killer') Container(color: Colors.white.withOpacity(0.9), child: const Center(child: Text('⚡ BLINDED!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace')))),
          _buildHUD(),
          _buildEffectsBar(),
          _buildControls(),
          ..._splatters.map((pos) => Positioned(left: pos.dx - 40, top: pos.dy - 40, child: const BloodSplatter())),
        ],
      ),
    );
  }

  Widget _buildWorld() {
    final isInvisibleSelf = _hasInvisibility || (_myRole == 'killer' && _myHunterType == 'stalker' && _abilityActive);
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Transform.translate(
              offset: Offset(-_camX, -_camY),
              child: SizedBox(
                width: _mapW,
                height: _mapH,
                child: Stack(
                  children: [
                    CustomPaint(size: const Size(_mapW, _mapH), painter: _round == 1 ? ForestMapPainter() : NightmareMapPainter()),
                    if (_phase == 'portal') Positioned(left: _portalPosition.dx - 48, top: _portalPosition.dy - 48, child: PortalWidget(active: true)),
                    ..._traps.map((t) => Positioned(left: t.position.dx - 14, top: t.position.dy - 14, child: TrapWidget(isTriggered: t.isTriggered))),
                    ..._powerups.where((p) => !p.isCollected).map((p) => Positioned(left: p.position.dx - 18, top: p.position.dy - 18, child: PowerupWidget(type: p.type))),
                    ..._tasks.map((t) => Positioned(left: t.position.dx - 16, top: t.position.dy - 16, child: TaskMarker(isCompleted: t.isCompleted, onTap: (_myRole == 'survivor' && !t.isCompleted && _phase.startsWith('round')) ? () => _startTask(t) : null))),
                    ..._bots.where((b) => !(b.isInvisible && !widget.isSolo)).map((b) => Positioned(
                          left: b.x - 20,
                          top: b.y - 52,
                          child: SilhouettePlayer(
                            isKiller: b.role == 'killer',
                            isMe: false,
                            isAlive: b.isAlive,
                            isInvisible: b.isInvisible,
                            username: b.username,
                            hunterType: b.hunterType,
                            health: b.health,
                            size: 38,
                          ),
                        )),
                    if (!widget.isSolo && _room != null)
                      ..._room!.players.values.where((p) => p.uid != widget.myUid && !p.isInvisible).map((p) => Positioned(
                            left: p.x - 20,
                            top: p.y - 52,
                            child: SilhouettePlayer(
                              isKiller: p.role == 'killer',
                              isMe: false,
                              isAlive: p.isAlive,
                              isInvisible: p.isInvisible,
                              username: p.username,
                              hunterType: p.hunterType,
                              health: p.health,
                              size: 38,
                            ),
                          )),
                    Positioned(
                      left: _myX - 22,
                      top: _myY - 54,
                      child: SilhouettePlayer(
                        isKiller: _myRole == 'killer',
                        isMe: true,
                        isAlive: _myHealth > 0,
                        isInvisible: isInvisibleSelf,
                        username: 'YOU',
                        hunterType: _myHunterType,
                        health: _myHealth,
                        size: 42,
                      ),
                    ),
                    if (_myRole == 'killer' && _canAttack) Positioned(left: _myX - _attackRange, top: _myY - _attackRange, child: Container(width: _attackRange * 2, height: _attackRange * 2, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ToxicTheme.red.withOpacity(0.12), width: 1)))),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHUD() {
    final td = HunterTypeData.all[HunterType.values.firstWhere((e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];
    final done = _tasks.where((t) => t.isCompleted).length;
    final alive = widget.isSolo
        ? _bots.where((b) => b.role == 'survivor' && b.isAlive).length + (_myRole == 'survivor' && _myHealth > 0 ? 1 : 0)
        : (_room?.players.values.where((p) => p.role == 'survivor' && p.isAlive).length ?? 0);
    final portalSecs = _portalDeadline == null ? 0 : max(0, _portalDeadline!.difference(DateTime.now()).inSeconds);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4), border: Border.all(color: _myRole == 'killer' ? (td?.color ?? ToxicTheme.red) : ToxicTheme.green, width: 1.5)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_myRole == 'killer' ? (td?.icon ?? Icons.close) : Icons.directions_run, color: _myRole == 'killer' ? (td?.color ?? ToxicTheme.red) : ToxicTheme.green, size: 12),
                      const SizedBox(width: 5),
                      Text(_myRole == 'killer' ? (td?.name.replaceAll('THE ', '') ?? 'KILLER') : 'SURVIVOR', style: TextStyle(color: _myRole == 'killer' ? (td?.color ?? ToxicTheme.red) : ToxicTheme.green, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4), border: Border.all(color: _round == 1 ? ToxicTheme.greenDark : ToxicTheme.purple)),
                  child: Text('ROUND $_round', style: TextStyle(color: _round == 1 ? ToxicTheme.green : ToxicTheme.cyan, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4), border: Border.all(color: ToxicTheme.greenDark)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👥', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text('$alive', style: const TextStyle(color: ToxicTheme.green, fontSize: 10, fontFamily: 'monospace')),
                      const SizedBox(width: 8),
                      const Text('📋', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text('$done/${_tasks.length}', style: const TextStyle(color: ToxicTheme.green, fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('HP', style: TextStyle(color: ToxicTheme.greenDim, fontSize: 9, fontFamily: 'monospace')),
                const SizedBox(width: 6),
                SizedBox(
                  width: 110,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _myHealth / 100,
                      backgroundColor: const Color(0xFF001A00),
                      valueColor: AlwaysStoppedAnimation(_myHealth > 60 ? ToxicTheme.green : _myHealth > 30 ? Colors.orange : ToxicTheme.red),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('$_myHealth', style: TextStyle(color: _myHealth > 60 ? ToxicTheme.green : _myHealth > 30 ? Colors.orange : ToxicTheme.red, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              ],
            ),
            if (_phase == 'portal')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('🌀 ENTER PORTAL: ${portalSecs ~/ 60}:${(portalSecs % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: ToxicTheme.cyan, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              ),
            if (_hasInvisibility) const Padding(padding: EdgeInsets.only(top: 4), child: Text('👻 INVISIBLE', style: TextStyle(color: Colors.purple, fontSize: 9, fontFamily: 'monospace'))),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectsBar() {
    final active = _effects.where((e) => e.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 90,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: active.map((e) {
          final secs = e.expiresAt.difference(DateTime.now()).inSeconds;
          final c = e.type == PowerupType.speedBoost ? ToxicTheme.green : Colors.purple;
          final icon = e.type == PowerupType.speedBoost ? '⚡' : '👻';
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4), border: Border.all(color: c.withOpacity(0.5))),
            child: Text('$icon ${secs}s', style: TextStyle(color: c, fontSize: 10, fontFamily: 'monospace')),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControls() {
    final td = HunterTypeData.all[HunterType.values.firstWhere((e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];
    final taskButtonEnabled = _myRole == 'survivor' && _nearbyTask != null && _phase.startsWith('round');

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Joystick(size: 120, onMove: (dx, dy) => setState(() { _jDx = dx; _jDy = dy; }), onRelease: () => setState(() { _jDx = 0; _jDy = 0; })),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_myRole == 'killer' && td != null) ...[
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(width: 58, height: 58, child: CircularProgressIndicator(value: _abilityCooldown, color: td.color, backgroundColor: td.color.withOpacity(0.1), strokeWidth: 2.5)),
                      GestureDetector(
                        onTap: _abilityReady ? _useAbility : null,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _abilityReady ? td.color.withOpacity(0.2) : Colors.black, border: Border.all(color: _abilityReady ? td.color : ToxicTheme.greenDark, width: 1.5), boxShadow: _abilityActive ? [BoxShadow(color: td.color.withOpacity(0.5), blurRadius: 14, spreadRadius: 3)] : []),
                          child: Icon(td.icon, color: _abilityReady ? td.color : ToxicTheme.greenDark, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(_abilityReady ? td.abilityName : 'CD', style: TextStyle(color: _abilityReady ? td.color : ToxicTheme.greenDark, fontSize: 8, fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                ],
                GestureDetector(
                  onTap: _myRole == 'killer' ? (_canAttack ? _attack : null) : (taskButtonEnabled ? () => _startTask(_nearbyTask!) : null),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _myRole == 'killer' ? (_canAttack ? ToxicTheme.redDim : Colors.black) : (taskButtonEnabled ? ToxicTheme.greenDark : Colors.black),
                      border: Border.all(color: _myRole == 'killer' ? (_canAttack ? ToxicTheme.red : ToxicTheme.greenDark) : (taskButtonEnabled ? ToxicTheme.green : ToxicTheme.greenDark), width: 2),
                      boxShadow: (_myRole == 'killer' && _canAttack) || taskButtonEnabled ? [BoxShadow(color: (_myRole == 'killer' ? ToxicTheme.red : ToxicTheme.green).withOpacity(0.35), blurRadius: 16, spreadRadius: 2)] : [],
                    ),
                    child: _myRole == 'killer'
                        ? const Icon(Icons.sports_martial_arts, color: ToxicTheme.red, size: 28)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(taskButtonEnabled ? Icons.play_arrow_rounded : Icons.assignment, color: taskButtonEnabled ? ToxicTheme.green : ToxicTheme.greenDark, size: 26),
                              Text(taskButtonEnabled ? 'USE TASK' : '${_tasks.where((t) => t.isCompleted).length}/${_tasks.length}', style: TextStyle(color: taskButtonEnabled ? ToxicTheme.green : ToxicTheme.greenDark, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz(TaskModel task) {
    final quiz = task.quiz!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _round == 1 ? const [Color(0xFF000000), Color(0xFF000A00)] : const [Color(0xFF07000D), Color(0xFF020308), Color(0xFF000000)]),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(border: Border.all(color: _round == 1 ? ToxicTheme.greenDark : ToxicTheme.purple), borderRadius: BorderRadius.circular(4)),
                      child: Text('${quiz.subject}  •  ROUND $_round', style: TextStyle(color: _round == 1 ? ToxicTheme.greenDim : ToxicTheme.cyan, fontSize: 11, fontFamily: 'monospace')),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        _taskInProgress = false;
                        _activeTask = null;
                      }),
                      child: const Text('[BACK]', style: TextStyle(color: ToxicTheme.greenDark, fontFamily: 'monospace', fontSize: 11)),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _round == 1 ? const Color(0xFF000A00) : const Color(0xFF090013), borderRadius: BorderRadius.circular(8), border: Border.all(color: _round == 1 ? ToxicTheme.greenDark : ToxicTheme.purple)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('> ${task.title.toUpperCase()}', style: TextStyle(color: _round == 1 ? ToxicTheme.greenDim : ToxicTheme.cyan, fontSize: 10, fontFamily: 'monospace')),
                      const SizedBox(height: 12),
                      Text(quiz.question, style: const TextStyle(color: ToxicTheme.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace', height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...quiz.options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final opt = entry.value;
                  final isSelected = _selectedAnswer == idx;
                  final isCorrect = idx == quiz.correctIndex;
                  Color borderColor = _round == 1 ? ToxicTheme.greenDark : ToxicTheme.purple;
                  Color textColor = _round == 1 ? ToxicTheme.greenDim : ToxicTheme.cyan;
                  Color bgColor = _round == 1 ? const Color(0xFF000A00) : const Color(0xFF090013);
                  String prefix = '[ ${String.fromCharCode(65 + idx)} ]';
                  if (_answerChecked) {
                    if (isCorrect) {
                      borderColor = ToxicTheme.green;
                      textColor = ToxicTheme.green;
                      bgColor = ToxicTheme.greenDark.withOpacity(0.3);
                    } else if (isSelected) {
                      borderColor = ToxicTheme.red;
                      textColor = ToxicTheme.red;
                      bgColor = ToxicTheme.red.withOpacity(0.1);
                      prefix = '[ ✗ ]';
                    }
                  } else if (isSelected) {
                    borderColor = ToxicTheme.green;
                    textColor = ToxicTheme.white;
                  }
                  return GestureDetector(
                    onTap: _answerChecked ? null : () => _selectAnswer(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: borderColor, width: 1.5)),
                      child: Row(
                        children: [
                          Text(prefix, style: TextStyle(color: borderColor, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(opt, style: TextStyle(color: textColor, fontFamily: 'monospace', fontSize: 14))),
                          if (_answerChecked && isCorrect) const Text(' ✓', style: TextStyle(color: ToxicTheme.green, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }),
                const Spacer(),
                if (_answerChecked && !_answerCorrect)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: ToxicTheme.red.withOpacity(0.1), border: Border.all(color: ToxicTheme.red.withOpacity(0.4)), borderRadius: BorderRadius.circular(6)),
                    child: Text('> WRONG ANSWER — -${_round == 2 ? 15 : 10} HP. Try again...', style: const TextStyle(color: ToxicTheme.red, fontFamily: 'monospace', fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
