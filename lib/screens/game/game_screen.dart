import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../../ai/bot_service.dart';
import '../../models/room_model.dart';
import '../../models/player_model.dart';
import '../../models/task_model.dart';
import '../../models/powerup.dart';
import '../../models/hunter_type.dart';
import '../../widgets/joystick.dart';
import '../../widgets/forest_map.dart';
import '../gameover_screen.dart';

class GameScreen extends StatefulWidget {
  final RoomModel room;
  final String myUid;
  final bool isSolo;
  const GameScreen({super.key, required this.room,
      required this.myUid, required this.isSolo});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameService _gs = GameService();

  // Map
  static const double _mapW = kMapW;
  static const double _mapH = kMapH;

  // Player state
  RoomModel? _room;
  double _myX = 500, _myY = 500;
  double _jDx = 0, _jDy = 0;
  String _myRole = 'survivor';
  String _myHunterType = 'stalker';
  int _myHealth = 100;

  // Camera
  double _camX = 0, _camY = 0;

  // Bots
  List<PlayerModel> _bots = [];
  List<BotService> _botServices = [];

  // Tasks & pickups
  List<TaskModel> _tasks = TaskModel.getForestTasks();
  List<Powerup> _powerups = Powerup.generateForMap();
  List<Trap> _traps = [];

  // Task flow
  TaskModel? _activeTask;
  bool _taskInProgress = false;
  int _tapCount = 0;
  bool _holdActive = false;
  double _holdProgress = 0;
  StreamSubscription? _accelSub;
  Timer? _holdTimer;

  // Active effects
  List<ActiveEffect> _effects = [];
  bool get _hasSpeedBoost => _effects.any(
      (e) => e.type == PowerupType.speedBoost && e.isActive);
  bool get _hasInvisibility => _effects.any(
      (e) => e.type == PowerupType.invisibility && e.isActive);
  bool _killerBlinded = false;

  // Hunter ability
  bool _abilityReady = true;
  bool _abilityActive = false;
  double _abilityCooldownProgress = 1.0;
  Timer? _abilityTimer;
  Timer? _cooldownTimer;

  // Attack
  bool _canAttack = true;
  double get _attackRange => _myHunterType == 'berserk' ? 65 : 70;

  // Timers
  Timer? _gameLoop;
  StreamSubscription? _roomStream;
  Timer? _effectsTimer;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    final me = _room!.players[widget.myUid];
    _myRole = me?.role ?? 'survivor';
    _myHunterType = me?.hunterType ?? 'stalker';
    _myX = me?.x ?? 500;
    _myY = me?.y ?? 500;

    if (widget.isSolo) _setupBots();
    else _roomStream = _gs.streamRoom(widget.room.roomId).listen(_onRoom);

    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _update);
    _effectsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => _effects.removeWhere((e) => !e.isActive));
    });
  }

  // ── Bot setup ────────────────────────────────────────────────────────────
  void _setupBots() {
    final rng = Random();
    final botNames = ['Shadow', 'Wraith', 'Specter'];
    List<String> roles = _myRole == 'killer'
        ? ['survivor', 'survivor', 'survivor']
        : ['killer', 'survivor', 'survivor'];

    _bots = List.generate(3, (i) => PlayerModel(
      uid: 'bot_$i', username: botNames[i],
      role: roles[i], hunterType: HunterType.values[i % 4].name,
      x: 150 + rng.nextDouble() * 1000,
      y: 150 + rng.nextDouble() * 800,
      isBot: true,
    ));

    final typeData = HunterTypeData.all[HunterType.values
        .firstWhere((e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];
    double botSpeed = typeData?.baseSpeed ?? 3.5;

    for (int i = 0; i < _bots.length; i++) {
      BotService bs = BotService();
      final bot = _bots[i];
      bs.start(
        role: bot.role,
        speed: bot.role == 'killer' ? botSpeed : 3.0,
        onMove: (x, y) {
          if (!mounted) return;
          setState(() => _bots[i] = _bots[i].copyWith(x: x, y: y));
          // Killer bot check proximity
          if (bot.role == 'killer' && _myRole == 'survivor') {
            double dist = sqrt(pow(_myX - x, 2) + pow(_myY - y, 2));
            if (dist < 50) _takeDamage(20);
          }
        },
        onAttack: (_) {},
        onTask: () {
          if (bot.role == 'survivor' && _bots[i].tasksCompleted < _bots[i].totalTasks) {
            setState(() => _bots[i] =
                _bots[i].copyWith(tasksCompleted: _bots[i].tasksCompleted + 1));
            _checkSoloWin();
          }
        },
        target: PlayerModel(uid: widget.myUid, username: 'YOU', x: _myX, y: _myY),
      );
      _botServices.add(bs);
    }
  }

  // ── Game loop ────────────────────────────────────────────────────────────
  void _update(Timer _) {
    if (_jDx == 0 && _jDy == 0) return;

    final typeData = HunterTypeData.all[HunterType.values
        .firstWhere((e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];
    double speed = _myRole == 'killer'
        ? (typeData?.baseSpeed ?? 4.5)
        : 4.5;
    if (_hasSpeedBoost) speed *= 1.8;
    if (_myHunterType == 'rusher' && _abilityActive) speed = typeData!.baseSpeed * 3;

    double nx = (_myX + _jDx * speed).clamp(20, _mapW - 20);
    double ny = (_myY + _jDy * speed).clamp(20, _mapH - 20);

    // Check traps
    for (var trap in _traps) {
      if (!trap.isTriggered) {
        double dist = sqrt(pow(nx - trap.position.dx, 2) + pow(ny - trap.position.dy, 2));
        if (dist < 30 && _myRole == 'survivor') {
          trap.isTriggered = true;
          _takeDamage(15);
          _addEffect(PowerupType.speedBoost, -1); // Slow (negative boost)
        }
      }
    }

    // Check powerup proximity
    for (var pu in _powerups) {
      if (!pu.isCollected && _myRole == 'survivor') {
        double dist = sqrt(pow(nx - pu.position.dx, 2) + pow(ny - pu.position.dy, 2));
        if (dist < 35) _collectPowerup(pu);
      }
    }

    setState(() {
      _myX = nx; _myY = ny;
      final size = MediaQuery.of(context).size;
      _camX = (_myX - size.width / 2).clamp(0, _mapW - size.width);
      _camY = (_myY - size.height / 2).clamp(0, _mapH - size.height);
    });

    if (!widget.isSolo) {
      _gs.updatePosition(widget.room.roomId, widget.myUid, _myX, _myY);
    }
    for (var bs in _botServices) bs.updateTarget(_myX, _myY);
  }

  void _onRoom(RoomModel? room) {
    if (room == null || !mounted) return;
    setState(() => _room = room);
    if (room.status == 'finished') _goOver(room.winnerRole ?? 'survivors');
  }

  // ── Combat ───────────────────────────────────────────────────────────────
  void _takeDamage(int dmg) {
    if (_hasInvisibility) return; // invisible = immune
    setState(() => _myHealth = (_myHealth - dmg).clamp(0, 100));
    if (_myHealth <= 0) _goOver('killer');
  }

  Future<void> _attack() async {
    if (!_canAttack || _myRole != 'killer') return;
    _canAttack = false;
    final typeData = HunterTypeData.all[HunterType.values
        .firstWhere((e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];
    int dmg = typeData?.baseDamage ?? 34;
    // Berserk rage doubles damage
    if (_myHunterType == 'berserk' && _abilityActive) dmg = 100;

    if (widget.isSolo) {
      for (int i = 0; i < _bots.length; i++) {
        if (!_bots[i].isAlive || _bots[i].role != 'survivor') continue;
        double dist = sqrt(pow(_myX - _bots[i].x, 2) + pow(_myY - _bots[i].y, 2));
        if (dist < _attackRange) {
          int newHp = (_bots[i].health - dmg).clamp(0, 100);
          setState(() => _bots[i] = _bots[i].copyWith(health: newHp, isAlive: newHp > 0));
          _checkSoloWin();
        }
      }
    } else {
      if (_room == null) return;
      for (var p in _room!.players.values) {
        if (p.uid == widget.myUid || !p.isAlive || p.role != 'survivor') continue;
        double dist = sqrt(pow(_myX - p.x, 2) + pow(_myY - p.y, 2));
        if (dist < _attackRange) await _gs.attackPlayer(widget.room.roomId, p.uid, dmg);
      }
    }

    if (_myHunterType == 'berserk' && _abilityActive) {
      setState(() => _abilityActive = false);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _canAttack = true);
    });
  }

  // ── Hunter ability ───────────────────────────────────────────────────────
  void _useAbility() {
    if (!_abilityReady) return;
    final typeData = HunterTypeData.all[HunterType.values
        .firstWhere((e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];
    if (typeData == null) return;

    setState(() { _abilityReady = false; _abilityActive = true; });

    switch (_myHunterType) {
      case 'stalker':
        // Invisible for 4s
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _abilityActive = false);
        });
        break;
      case 'rusher':
        // Speed boost 3s
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _abilityActive = false);
        });
        break;
      case 'trapper':
        // Place trap at current position
        _traps.add(Trap(id: 'trap_${DateTime.now().millisecondsSinceEpoch}',
            position: Offset(_myX, _myY)));
        setState(() => _abilityActive = false);
        break;
      case 'berserk':
        // Rage: next attack is 100 dmg — stays active until attack used
        break;
    }

    // Cooldown
    int cooldown = typeData.abilityCooldownSec;
    double step = 1.0 / (cooldown * 20);
    setState(() => _abilityCooldownProgress = 0);
    _cooldownTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() => _abilityCooldownProgress =
          (_abilityCooldownProgress + step).clamp(0, 1));
      if (_abilityCooldownProgress >= 1.0) {
        t.cancel();
        setState(() => _abilityReady = true);
      }
    });
  }

  // ── Powerups ─────────────────────────────────────────────────────────────
  void _collectPowerup(Powerup pu) {
    setState(() => pu.isCollected = true);
    switch (pu.type) {
      case PowerupType.healthPack:
        setState(() => _myHealth = (_myHealth + 40).clamp(0, 100));
        break;
      case PowerupType.flashbang:
        setState(() => _killerBlinded = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _killerBlinded = false);
        });
        break;
      default:
        _addEffect(pu.type, 5);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${pu.emoji} ${pu.name} collected!'),
        backgroundColor: Colors.green.shade800,
        duration: const Duration(milliseconds: 800),
      ));
    }
  }

  void _addEffect(PowerupType type, int seconds) {
    _effects.removeWhere((e) => e.type == type);
    _effects.add(ActiveEffect(type: type,
        expiresAt: DateTime.now().add(Duration(seconds: seconds))));
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────
  void _startTask(TaskModel task) {
    setState(() {
      _activeTask = task; _taskInProgress = true;
      _tapCount = 0; _holdProgress = 0;
    });
    if (task.type == 'shake') _listenShake(task);
  }

  void _listenShake(TaskModel task) {
    int count = 0;
    _accelSub = accelerometerEventStream().listen((e) {
      if ((e.x.abs() + e.y.abs() + e.z.abs()) - 9.8 > 14) {
        count++;
        if (count >= 5) { _accelSub?.cancel(); _finishTask(task); }
      }
    });
  }

  void _onTap(TaskModel task) {
    setState(() => _tapCount++);
    if (_tapCount >= 10) _finishTask(task);
  }

  void _startHold(TaskModel task) {
    _holdActive = true;
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!_holdActive) { t.cancel(); return; }
      setState(() => _holdProgress += 0.033);
      if (_holdProgress >= 1) { t.cancel(); _finishTask(task); }
    });
  }

  void _stopHold() {
    _holdActive = false;
    _holdTimer?.cancel();
    setState(() => _holdProgress = 0);
  }

  Future<void> _finishTask(TaskModel task) async {
    _accelSub?.cancel();
    int idx = _tasks.indexWhere((t) => t.taskId == task.taskId);
    if (idx >= 0) setState(() => _tasks[idx].isCompleted = true);
    setState(() { _taskInProgress = false; _activeTask = null; _tapCount = 0; });
    if (!widget.isSolo) await _gs.completeTask(widget.room.roomId, widget.myUid);
    else if (_tasks.every((t) => t.isCompleted)) _goOver('survivors');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Task complete!'),
          backgroundColor: Colors.green, duration: Duration(seconds: 1)));
  }

  // ── Win/Lose ──────────────────────────────────────────────────────────────
  void _checkSoloWin() {
    List<PlayerModel> survivors = _bots.where((b) => b.role == 'survivor').toList();
    if (survivors.every((b) => !b.isAlive) && _myRole == 'killer') _goOver('killer');
    if (_myRole == 'survivor') {
      final killer = _bots.firstWhere((b) => b.role == 'killer',
          orElse: () => PlayerModel(uid: '', username: '', isAlive: false));
      if (killer.isAlive) {
        double dist = sqrt(pow(_myX - killer.x, 2) + pow(_myY - killer.y, 2));
        if (dist < 40) _goOver('killer');
      }
    }
  }

  void _goOver(String winner) {
    _gameLoop?.cancel();
    _effectsTimer?.cancel();
    for (var bs in _botServices) bs.stop();
    _roomStream?.cancel();
    if (!mounted) return;
    String killerName = widget.isSolo
        ? (_bots.firstWhere((b) => b.role == 'killer',
            orElse: () => PlayerModel(uid: '', username: 'Shadow')).username)
        : (_room?.players.values.firstWhere((p) => p.role == 'killer',
            orElse: () => PlayerModel(uid: '', username: 'Unknown')).username ?? 'Unknown');
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => GameOverScreen(
          winnerRole: winner, myRole: _myRole, killerName: killerName),
    ));
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _effectsTimer?.cancel();
    _roomStream?.cancel();
    _accelSub?.cancel();
    _holdTimer?.cancel();
    _abilityTimer?.cancel();
    _cooldownTimer?.cancel();
    for (var bs in _botServices) bs.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_taskInProgress && _activeTask != null) return _buildTaskView(_activeTask!);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Game world
        _buildWorld(),
        // Flashbang overlay
        if (_killerBlinded && _myRole == 'killer')
          Container(color: Colors.white.withValues(alpha: 0.85)),
        // HUD
        _buildHUD(),
        // Controls
        _buildControls(),
        // Effects indicators
        _buildEffects(),
      ]),
    );
  }

  Widget _buildWorld() {
    final size = MediaQuery.of(context).size;
    return ClipRect(
      child: SizedBox.expand(
        child: Transform.translate(
          offset: Offset(-_camX, -_camY),
          child: SizedBox(
            width: _mapW, height: _mapH,
            child: Stack(children: [
              // Map
              CustomPaint(size: const Size(_mapW, _mapH), painter: ForestMapPainter()),
              // Traps
              ..._traps.map((t) => Positioned(
                left: t.position.dx - 14, top: t.position.dy - 14,
                child: TrapWidget(isTriggered: t.isTriggered),
              )),
              // Powerups
              ..._powerups.where((p) => !p.isCollected).map((p) => Positioned(
                left: p.position.dx - 17, top: p.position.dy - 17,
                child: PowerupWidget(type: p.type, onCollect: () => _collectPowerup(p)),
              )),
              // Task markers
              ..._tasks.asMap().entries.map((e) => Positioned(
                left: e.value.position.dx - 16, top: e.value.position.dy - 16,
                child: TaskMarker(
                  isCompleted: e.value.isCompleted,
                  onTap: _myRole == 'survivor' && !e.value.isCompleted
                      ? () => _startTask(e.value) : null,
                ),
              )),
              // Bot players
              ..._bots.map((b) => Positioned(
                left: b.x - 20, top: b.y - 48,
                child: SilhouettePlayer(
                  isKiller: b.role == 'killer', isMe: false,
                  isAlive: b.isAlive, username: b.username,
                  hunterType: b.hunterType, health: b.health, size: 38,
                ),
              )),
              // Online players
              if (!widget.isSolo && _room != null)
                ..._room!.players.values.where((p) => p.uid != widget.myUid).map((p) =>
                  Positioned(
                    left: p.x - 20, top: p.y - 48,
                    child: SilhouettePlayer(
                      isKiller: p.role == 'killer', isMe: false,
                      isAlive: p.isAlive, username: p.username,
                      hunterType: p.hunterType, health: p.health, size: 38,
                    ),
                  )),
              // ME
              Positioned(
                left: _myX - 22, top: _myY - 50,
                child: SilhouettePlayer(
                  isKiller: _myRole == 'killer', isMe: true,
                  isAlive: true, isInvisible: _hasInvisibility,
                  username: 'YOU', hunterType: _myHunterType,
                  health: _myHealth, size: 42,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    int done = _tasks.where((t) => t.isCompleted).length;
    int aliveSurvivors = widget.isSolo
        ? _bots.where((b) => b.role == 'survivor' && b.isAlive).length
        : (_room?.players.values.where((p) => p.role == 'survivor' && p.isAlive).length ?? 0);

    final typeData = HunterTypeData.all[HunterType.values.firstWhere(
        (e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (_myRole == 'killer'
                    ? (typeData?.color ?? Colors.red)
                    : Colors.blue).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_myRole == 'killer'
                      ? (typeData?.color ?? Colors.red)
                      : Colors.blue).withValues(alpha: 0.6)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_myRole == 'killer' && typeData != null)
                  Icon(typeData.icon, color: typeData.color, size: 14),
                if (_myRole == 'survivor')
                  const Icon(Icons.directions_run, color: Colors.blue, size: 14),
                const SizedBox(width: 5),
                Text(
                  _myRole == 'killer'
                      ? (typeData?.name.replaceAll('THE ', '') ?? 'KILLER')
                      : 'SURVIVOR',
                  style: TextStyle(
                    color: _myRole == 'killer' ? (typeData?.color ?? Colors.red) : Colors.blue,
                    fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                ),
              ]),
            ),
            const Spacer(),
            // Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.people, color: Colors.white38, size: 12),
                const SizedBox(width: 3),
                Text('$aliveSurvivors',
                    style: const TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(width: 8),
                const Icon(Icons.task_alt, color: Colors.amber, size: 12),
                const SizedBox(width: 3),
                Text('$done/${_tasks.length}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
            ),
          ]),
          if (_myRole == 'survivor') ...[
            const SizedBox(height: 6),
            // Health bar
            Row(children: [
              const Icon(Icons.favorite, color: Colors.red, size: 12),
              const SizedBox(width: 4),
              SizedBox(
                width: 100, height: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _myHealth / 100,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                        _myHealth > 60 ? Colors.green
                        : _myHealth > 30 ? Colors.orange : Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text('$_myHealth', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _buildEffects() {
    List<ActiveEffect> active = _effects.where((e) => e.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 100, right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: active.map((e) {
          Duration left = e.expiresAt.difference(DateTime.now());
          Color c;
          IconData ic;
          switch (e.type) {
            case PowerupType.speedBoost: c = Colors.yellow; ic = Icons.bolt; break;
            case PowerupType.invisibility: c = Colors.purple; ic = Icons.visibility_off; break;
            default: c = Colors.green; ic = Icons.favorite;
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withValues(alpha: 0.5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(ic, color: c, size: 12),
              const SizedBox(width: 4),
              Text('${left.inSeconds}s', style: TextStyle(color: c, fontSize: 10)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControls() {
    final typeData = HunterTypeData.all[HunterType.values.firstWhere(
        (e) => e.name == _myHunterType, orElse: () => HunterType.stalker)];

    return Positioned(
      bottom: 24, left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Joystick(size: 120,
              onMove: (dx, dy) => setState(() { _jDx = dx; _jDy = dy; }),
              onRelease: () => setState(() { _jDx = 0; _jDy = 0; }),
            ),
            const Spacer(),
            Column(mainAxisSize: MainAxisSize.min, children: [
              // Ability button (killer only)
              if (_myRole == 'killer' && typeData != null) ...[
                Stack(alignment: Alignment.center, children: [
                  SizedBox(width: 60, height: 60,
                    child: CircularProgressIndicator(
                      value: _abilityCooldownProgress,
                      color: typeData.color,
                      backgroundColor: typeData.color.withValues(alpha: 0.15),
                      strokeWidth: 3,
                    ),
                  ),
                  GestureDetector(
                    onTap: _abilityReady ? _useAbility : null,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _abilityReady
                            ? typeData.color.withValues(alpha: 0.25)
                            : Colors.grey.withValues(alpha: 0.15),
                        border: Border.all(
                            color: _abilityReady ? typeData.color : Colors.grey, width: 2),
                      ),
                      child: Icon(typeData.icon,
                          color: _abilityReady ? typeData.color : Colors.grey, size: 24),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(typeData.abilityName,
                    style: TextStyle(color: typeData.color.withValues(alpha: 0.7),
                        fontSize: 8, letterSpacing: 1)),
                const SizedBox(height: 10),
              ],
              // Attack / task button
              if (_myRole == 'killer')
                GestureDetector(
                  onTap: _canAttack ? _attack : null,
                  child: Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _canAttack
                          ? const Color(0xFF8B0000)
                          : Colors.grey.withValues(alpha: 0.25),
                      boxShadow: _canAttack ? [const BoxShadow(
                          color: Colors.red, blurRadius: 16, spreadRadius: 1)] : [],
                    ),
                    child: const Icon(Icons.sports_martial_arts, color: Colors.white, size: 30),
                  ),
                )
              else
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.task_alt, color: Colors.amber, size: 22),
                    Text('${_tasks.where((t) => t.isCompleted).length}/${_tasks.length}',
                        style: const TextStyle(color: Colors.amber, fontSize: 10)),
                  ]),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Task view ─────────────────────────────────────────────────────────────
  Widget _buildTaskView(TaskModel task) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF000000), Color(0xFF050F05)]),
        ),
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 20),
            Text(task.title, style: const TextStyle(color: Colors.white,
                fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(task.description, style: const TextStyle(
                color: Color(0xFF446644), fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 48),
            if (task.type == 'tap') ...[
              GestureDetector(
                onTap: () => _onTap(task),
                child: Container(
                  width: 170, height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: const Color(0xFF0D1F0D),
                    border: Border.all(color: Colors.amber, width: 3),
                    boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 30, spreadRadius: 5)],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
                    Text('$_tapCount / 10', style: const TextStyle(color: Colors.white,
                        fontSize: 24, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              const Text('TAP RAPIDLY!',
                  style: TextStyle(color: Colors.amber, letterSpacing: 4, fontSize: 14)),
            ],
            if (task.type == 'hold') ...[
              GestureDetector(
                onTapDown: (_) => _startHold(task),
                onTapUp: (_) => _stopHold(),
                onTapCancel: _stopHold,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(width: 170, height: 170,
                    child: CircularProgressIndicator(value: _holdProgress,
                        color: Colors.blue,
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        strokeWidth: 8)),
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: const Color(0xFF0D1F0D),
                        border: Border.all(color: Colors.blue, width: 2)),
                    child: const Icon(Icons.rocket_launch, color: Colors.blue, size: 50),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              const Text('HOLD THE BUTTON!',
                  style: TextStyle(color: Colors.blue, letterSpacing: 4, fontSize: 14)),
            ],
            if (task.type == 'shake') ...[
              Container(
                width: 170, height: 170,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF0D1F0D),
                    border: Border.all(color: Colors.green, width: 3),
                    boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4),
                        blurRadius: 30, spreadRadius: 5)]),
                child: const Icon(Icons.vibration, color: Colors.green, size: 70),
              ),
              const SizedBox(height: 16),
              const Text('SHAKE YOUR PHONE!',
                  style: TextStyle(color: Colors.green, letterSpacing: 4, fontSize: 14)),
            ],
            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                _accelSub?.cancel(); _holdTimer?.cancel();
                setState(() { _taskInProgress = false; _activeTask = null; _holdProgress = 0; });
              },
              child: const Text('← BACK TO MAP',
                  style: TextStyle(color: Color(0xFF446644), fontSize: 14)),
            ),
          ]),
        ),
      ),
    );
  }
}
