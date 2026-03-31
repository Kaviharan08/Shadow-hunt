import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../../ai/bot_service.dart';
import '../../models/room_model.dart';
import '../../models/player_model.dart';
import '../../models/task_model.dart';
import '../../widgets/joystick.dart';
import '../../widgets/forest_map.dart';
import '../gameover_screen.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  final RoomModel room;
  final String myUid;
  final bool isSolo;
  const GameScreen({super.key, required this.room, required this.myUid, required this.isSolo});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameService _gameService = GameService();
  late BotService _botService;

  // Map dimensions
  static const double mapW = 800;
  static const double mapH = 700;
  static const double playerSpeed = 4.5;

  RoomModel? _room;
  double _myX = 300, _myY = 300;
  double _joyDx = 0, _joyDy = 0;
  String _myRole = 'survivor';

  // Bot players (solo mode)
  List<PlayerModel> _botPlayers = [];
  List<BotService> _botServices = [];

  // Tasks
  List<TaskModel> _tasks = TaskModel.getForestTasks();
  TaskModel? _activeTask;
  bool _taskInProgress = false;
  int _tapCount = 0;
  bool _holdActive = false;
  double _holdProgress = 0;
  StreamSubscription? _accelSub;
  Timer? _holdTimer;

  // Game loop
  Timer? _gameLoop;
  StreamSubscription? _roomStream;

  // Camera (viewport offset)
  double _camX = 0, _camY = 0;
  final double _vpW = 360, _vpH = 600;

  // Attack cooldown
  bool _canAttack = true;
  double _attackRange = 70;

  @override
  void initState() {
    super.initState();
    _botService = BotService();
    _initGame();
  }

  void _initGame() {
    _room = widget.room;
    final myPlayer = _room!.players[widget.myUid];
    _myRole = myPlayer?.role ?? 'survivor';
    _myX = myPlayer?.x ?? 300;
    _myY = myPlayer?.y ?? 300;

    if (widget.isSolo) {
      _setupSoloBots();
    } else {
      _roomStream = _gameService.streamRoom(widget.room.roomId).listen(_onRoomUpdate);
    }

    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _update);
  }

  void _setupSoloBots() {
    final rng = Random();
    // Create 3 bot opponents
    List<String> botRoles = _myRole == 'killer'
        ? ['survivor', 'survivor', 'survivor']
        : ['killer', 'survivor', 'survivor'];

    _botPlayers = List.generate(3, (i) => PlayerModel(
      uid: 'bot_$i',
      username: ['Shadow', 'Wraith', 'Specter'][i],
      role: botRoles[i],
      x: 150 + rng.nextDouble() * 500,
      y: 150 + rng.nextDouble() * 400,
      isBot: true,
    ));

    // Start AI for each bot
    for (int i = 0; i < _botPlayers.length; i++) {
      BotService bs = BotService();
      final bot = _botPlayers[i];
      bs.startBot(
        botRole: bot.role,
        onMove: (x, y) {
          if (mounted) setState(() {
            _botPlayers[i] = _botPlayers[i].copyWith(x: x, y: y);
          });
        },
        onAttack: (targetUid) {
          if (targetUid == widget.myUid && _myRole == 'survivor') {
            _takeDamage(25);
          }
        },
        onPatrolTask: () {
          if (bot.role == 'survivor' && bot.tasksCompleted < bot.totalTasks) {
            setState(() {
              _botPlayers[i] = _botPlayers[i].copyWith(
                tasksCompleted: _botPlayers[i].tasksCompleted + 1);
            });
            _checkSoloWin();
          }
        },
        playerToChase: _myRole == 'killer'
            ? PlayerModel(uid: widget.myUid, username: 'Player', x: _myX, y: _myY)
            : (_botPlayers.isNotEmpty && botRoles[i] == 'killer'
                ? PlayerModel(uid: widget.myUid, username: 'Player', x: _myX, y: _myY)
                : null),
      );
      _botServices.add(bs);
    }
  }

  void _onRoomUpdate(RoomModel? room) {
    if (room == null || !mounted) return;
    setState(() => _room = room);
    if (room.status == 'finished') {
      _goToGameOver(room.winnerRole ?? 'survivors');
    }
  }

  void _update(Timer t) {
    if (_joyDx == 0 && _joyDy == 0) return;
    double newX = (_myX + _joyDx * playerSpeed).clamp(20, mapW - 20);
    double newY = (_myY + _joyDy * playerSpeed).clamp(20, mapH - 20);
    setState(() {
      _myX = newX;
      _myY = newY;
      // Camera follow
      _camX = (_myX - _vpW / 2).clamp(0, mapW - _vpW);
      _camY = (_myY - _vpH / 2).clamp(0, mapH - _vpH);
    });
    if (!widget.isSolo) {
      _gameService.updatePosition(widget.room.roomId, widget.myUid, _myX, _myY);
    }
    // Update bot chase target
    for (var bs in _botServices) {
      bs.setChaseTarget(_myX, _myY);
    }
  }

  void _takeDamage(int dmg) {
    // In solo mode handle locally
    if (mounted) {
      // Show damage flash
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💀 -$dmg HP!'),
            backgroundColor: Colors.red, duration: const Duration(milliseconds: 500)),
      );
    }
  }

  Future<void> _tryAttack() async {
    if (!_canAttack || _myRole != 'killer') return;
    _canAttack = false;

    if (widget.isSolo) {
      for (int i = 0; i < _botPlayers.length; i++) {
        final bot = _botPlayers[i];
        if (!bot.isAlive || bot.role != 'survivor') continue;
        double dist = sqrt(pow(_myX - bot.x, 2) + pow(_myY - bot.y, 2));
        if (dist < _attackRange) {
          int newHp = (bot.health - 34).clamp(0, 100);
          setState(() {
            _botPlayers[i] = _botPlayers[i].copyWith(health: newHp, isAlive: newHp > 0);
          });
          _checkSoloWin();
        }
      }
    } else {
      if (_room == null) return;
      for (var player in _room!.players.values) {
        if (player.uid == widget.myUid || !player.isAlive || player.role != 'survivor') continue;
        double dist = sqrt(pow(_myX - player.x, 2) + pow(_myY - player.y, 2));
        if (dist < _attackRange) {
          await _gameService.attackPlayer(widget.room.roomId, player.uid, 34);
        }
      }
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _canAttack = true;
    });
  }

  void _checkSoloWin() {
    List<PlayerModel> survivors = _botPlayers.where((b) => b.role == 'survivor').toList();
    bool allDead = survivors.every((b) => !b.isAlive);
    bool allTasksDone = survivors.every((b) => b.tasksCompleted >= b.totalTasks)
        && _tasks.every((t) => t.isCompleted);

    if (allDead && _myRole == 'killer') _goToGameOver('killer');
    if (allTasksDone && _myRole == 'survivor') _goToGameOver('survivors');

    // Check if killer bot caught player
    if (_myRole == 'survivor') {
      final killerBot = _botPlayers.firstWhere((b) => b.role == 'killer',
          orElse: () => PlayerModel(uid: '', username: '', isAlive: false));
      if (killerBot.isAlive) {
        double dist = sqrt(pow(_myX - killerBot.x, 2) + pow(_myY - killerBot.y, 2));
        if (dist < 40) _goToGameOver('killer');
      }
    }
  }

  void _startTask(TaskModel task) {
    setState(() { _activeTask = task; _taskInProgress = true; _tapCount = 0; _holdProgress = 0; });
    if (task.type == 'shake') _listenShake(task);
  }

  void _listenShake(TaskModel task) {
    int count = 0;
    _accelSub = accelerometerEventStream().listen((e) {
      double m = (e.x.abs() + e.y.abs() + e.z.abs()) - 9.8;
      if (m > 14) {
        count++;
        if (count >= 5) { _accelSub?.cancel(); _finishTask(task); }
      }
    });
  }

  void _onTapTask(TaskModel task) {
    setState(() => _tapCount++);
    if (_tapCount >= 10) _finishTask(task);
  }

  void _startHold(TaskModel task) {
    _holdActive = true;
    const step = 0.033;
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!_holdActive) { t.cancel(); return; }
      setState(() => _holdProgress += step);
      if (_holdProgress >= 1.0) { t.cancel(); _finishTask(task); }
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
    if (idx >= 0) setState(() { _tasks[idx].isCompleted = true; });
    setState(() { _taskInProgress = false; _activeTask = null; _tapCount = 0; _holdProgress = 0; });

    if (!widget.isSolo) {
      await _gameService.completeTask(widget.room.roomId, widget.myUid);
    } else {
      // Check if all tasks done
      bool allDone = _tasks.every((t) => t.isCompleted);
      if (allDone && _myRole == 'survivor') _goToGameOver('survivors');
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Task complete!'), backgroundColor: Colors.green,
          duration: Duration(seconds: 1)),
    );
  }

  void _goToGameOver(String winnerRole) {
    _gameLoop?.cancel();
    for (var bs in _botServices) bs.stopBot();
    _roomStream?.cancel();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => GameOverScreen(
        winnerRole: winnerRole, myRole: _myRole,
        killerName: _getKillerName(),
      ),
    ));
  }

  String _getKillerName() {
    if (widget.isSolo) {
      return _botPlayers.firstWhere((b) => b.role == 'killer',
          orElse: () => PlayerModel(uid: '', username: 'Shadow')).username;
    }
    return _room?.players.values
        .firstWhere((p) => p.role == 'killer',
            orElse: () => PlayerModel(uid: '', username: 'Unknown'))
        .username ?? 'Unknown';
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _roomStream?.cancel();
    _accelSub?.cancel();
    _holdTimer?.cancel();
    for (var bs in _botServices) bs.dispose();
    _botService.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_taskInProgress && _activeTask != null) return _buildTaskView(_activeTask!);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Game viewport
        ClipRect(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Transform.translate(
              offset: Offset(-_camX, -_camY),
              child: SizedBox(
                width: mapW, height: mapH,
                child: Stack(children: [
                  // Forest map
                  CustomPaint(size: const Size(mapW, mapH), painter: ForestMapPainter()),
                  // Task markers
                  ..._tasks.asMap().entries.map((e) => Positioned(
                    left: e.value.position.dx - 15,
                    top: e.value.position.dy - 15,
                    child: TaskMarker(
                      title: e.value.title,
                      isCompleted: e.value.isCompleted,
                      onTap: _myRole == 'survivor' ? () => _startTask(e.value) : null,
                    ),
                  )),
                  // Online players
                  if (!widget.isSolo && _room != null)
                    ..._room!.players.values.map((p) => Positioned(
                      left: p.x - 20, top: p.y - 42,
                      child: SilhouettePlayer(
                        isKiller: p.role == 'killer',
                        isMe: p.uid == widget.myUid,
                        isAlive: p.isAlive,
                        username: p.uid == widget.myUid ? 'YOU' : p.username,
                        size: 40,
                      ),
                    )),
                  // Bot players (solo)
                  if (widget.isSolo)
                    ..._botPlayers.map((b) => Positioned(
                      left: b.x - 20, top: b.y - 42,
                      child: SilhouettePlayer(
                        isKiller: b.role == 'killer',
                        isMe: false,
                        isAlive: b.isAlive,
                        username: b.username,
                        size: 38,
                      ),
                    )),
                  // My player
                  Positioned(
                    left: _myX - 20, top: _myY - 42,
                    child: SilhouettePlayer(
                      isKiller: _myRole == 'killer',
                      isMe: true,
                      isAlive: true,
                      username: 'YOU',
                      size: 40,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
        // HUD overlay
        _buildHUD(),
        // Controls
        _buildControls(),
      ]),
    );
  }

  Widget _buildHUD() {
    int tasksLeft = _tasks.where((t) => !t.isCompleted).length;
    int aliveSurvivors = widget.isSolo
        ? _botPlayers.where((b) => b.role == 'survivor' && b.isAlive).length
        : (_room?.players.values.where((p) => p.role == 'survivor' && p.isAlive).length ?? 0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Top bar
            Row(children: [
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_myRole == 'killer' ? Colors.red : Colors.blue).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_myRole == 'killer' ? Colors.red : Colors.blue).withOpacity(0.5)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_myRole == 'killer' ? Icons.sports_martial_arts : Icons.directions_run,
                      color: _myRole == 'killer' ? Colors.red : Colors.blue, size: 14),
                  const SizedBox(width: 6),
                  Text(_myRole.toUpperCase(),
                      style: TextStyle(color: _myRole == 'killer' ? Colors.red : Colors.blue,
                          fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                ]),
              ),
              const Spacer(),
              // Stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text('$aliveSurvivors alive',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 10),
                  const Icon(Icons.task_alt, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text('$tasksLeft tasks left',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 24, left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Joystick
            Joystick(
              size: 120,
              onMove: (dx, dy) => setState(() { _joyDx = dx; _joyDy = dy; }),
              onRelease: () => setState(() { _joyDx = 0; _joyDy = 0; }),
            ),
            // Action button
            if (_myRole == 'killer')
              GestureDetector(
                onTap: _canAttack ? _tryAttack : null,
                child: Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _canAttack ? const Color(0xFF8B0000) : Colors.grey.withOpacity(0.3),
                    boxShadow: _canAttack
                        ? [const BoxShadow(color: Colors.red, blurRadius: 16, spreadRadius: 2)]
                        : [],
                  ),
                  child: const Icon(Icons.sports_martial_arts, color: Colors.white, size: 28),
                ),
              )
            else
              // Survivor: show task count
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.task_alt, color: Colors.amber, size: 22),
                  Text('${_tasks.where((t) => t.isCompleted).length}/${_tasks.length}',
                      style: const TextStyle(color: Colors.amber, fontSize: 10)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskView(TaskModel task) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: task.type == 'tap' ? () => _onTapTask(task) : null,
        child: Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF000000), Color(0xFF050F05)]),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(task.title, style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                  textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(task.description, style: const TextStyle(color: Color(0xFF446644), fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 48),

                if (task.type == 'tap') ...[
                  GestureDetector(
                    onTap: () => _onTapTask(task),
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0D1F0D),
                        border: Border.all(color: Colors.amber, width: 3),
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4),
                            blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 36),
                        const SizedBox(height: 4),
                        Text('$_tapCount / 10', style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ])),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('TAP RAPIDLY!', style: TextStyle(color: Colors.amber, letterSpacing: 4)),
                ],

                if (task.type == 'hold') ...[
                  GestureDetector(
                    onTapDown: (_) => _startHold(task),
                    onTapUp: (_) => _stopHold(),
                    onTapCancel: _stopHold,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0D1F0D),
                        border: Border.all(color: Colors.blue, width: 3),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4),
                            blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox(width: 130, height: 130,
                          child: CircularProgressIndicator(
                            value: _holdProgress,
                            color: Colors.blue,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            strokeWidth: 6,
                          ),
                        ),
                        const Icon(Icons.rocket_launch, color: Colors.blue, size: 36),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('HOLD THE BUTTON!', style: TextStyle(color: Colors.blue, letterSpacing: 4)),
                ],

                if (task.type == 'shake') ...[
                  Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D1F0D),
                      border: Border.all(color: Colors.green, width: 3),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4),
                          blurRadius: 30, spreadRadius: 5)],
                    ),
                    child: const Icon(Icons.vibration, color: Colors.green, size: 64),
                  ),
                  const SizedBox(height: 16),
                  const Text('SHAKE YOUR PHONE!', style: TextStyle(color: Colors.green, letterSpacing: 4)),
                ],

                const SizedBox(height: 40),
                TextButton(
                  onPressed: () {
                    _accelSub?.cancel();
                    _holdTimer?.cancel();
                    setState(() { _taskInProgress = false; _activeTask = null; _holdProgress = 0; });
                  },
                  child: const Text('← BACK TO MAP', style: TextStyle(color: Color(0xFF446644))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
