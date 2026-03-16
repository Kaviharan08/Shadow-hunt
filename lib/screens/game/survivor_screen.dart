import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../../models/room_model.dart';
import '../../models/task_model.dart';
import '../../services/game_service.dart';
import '../../widgets/horror_crewmate.dart';
import '../gameover_screen.dart';

class SurvivorScreen extends StatefulWidget {
  final RoomModel room;
  final String myUid;
  const SurvivorScreen({super.key, required this.room, required this.myUid});
  @override
  State<SurvivorScreen> createState() => _SurvivorScreenState();
}

class _SurvivorScreenState extends State<SurvivorScreen> {
  final GameService _gameService = GameService();
  RoomModel? _currentRoom;
  List<TaskModel> _tasks = [];
  int _tapCount = 0;
  bool _taskInProgress = false;
  TaskModel? _activeTask;
  StreamSubscription? _accelSub;

  @override
  void initState() {
    super.initState();
    _gameService.streamRoom(widget.room.roomId).listen((room) {
      if (room == null) return;
      setState(() {
        _currentRoom = room;
        bool isCaught = room.players[widget.myUid]?.isAlive == false;
        if (isCaught || room.status == 'finished') {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => GameOverScreen(
              winnerRole: room.winnerRole ?? 'hunter', myRole: 'survivor', room: room),
          ));
          return;
        }
        if (room.status == 'playing' && _tasks.isEmpty) {
          _tasks = TaskModel.getDefaultTasks();
        }
      });
    });
  }

  void _startTask(TaskModel task) {
    setState(() { _activeTask = task; _taskInProgress = true; _tapCount = 0; });
    if (task.type == 'shake') _listenForShake(task);
  }

  void _listenForShake(TaskModel task) {
    int shakeCount = 0;
    _accelSub = accelerometerEventStream().listen((event) {
      double magnitude = (event.x.abs() + event.y.abs() + event.z.abs()) - 9.8;
      if (magnitude > 15.0) {
        shakeCount++;
        if (shakeCount >= 5) { _accelSub?.cancel(); _completeTask(task); }
      }
    });
  }

  Future<void> _completeTask(TaskModel task) async {
    _accelSub?.cancel();
    await _gameService.completeTask(widget.room.roomId, task.taskId, widget.myUid);
    setState(() {
      _taskInProgress = false; _activeTask = null; _tapCount = 0;
      int idx = _tasks.indexWhere((t) => t.taskId == task.taskId);
      if (idx >= 0) _tasks[idx].isCompleted = true;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Task completed!'), backgroundColor: Colors.green));
    if (_currentRoom != null) await _gameService.checkWinCondition(widget.room.roomId, _currentRoom!);
  }

  void _onTapTask(TaskModel task) {
    setState(() => _tapCount++);
    if (_tapCount >= 10) _completeTask(task);
  }

  @override
  void dispose() { _accelSub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    int completed = _tasks.where((t) => t.isCompleted).length;
    return Scaffold(
      backgroundColor: const Color(0xFF000A1A),
      body: SafeArea(
        child: _taskInProgress && _activeTask != null
            ? _buildTaskView(_activeTask!)
            : _buildTaskList(completed),
      ),
    );
  }

  Widget _buildTaskList(int completed) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Survivor header with crewmate
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF001A33), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(children: [
              const HorrorCrewmate(bodyColor: Color(0xFF003399), size: 60),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('YOU ARE A SURVIVOR', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                Text('Complete tasks to escape!', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TASKS: $completed / ${_tasks.length}',
                style: const TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 12)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _tasks.isEmpty ? 0 : completed / _tasks.length,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 8,
              ),
            ),
          ]),

          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (ctx, i) {
                final task = _tasks[i];
                return GestureDetector(
                  onTap: task.isCompleted ? null : () => _startTask(task),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: task.isCompleted ? const Color(0xFF0A1A0A) : const Color(0xFF001A33),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: task.isCompleted ? Colors.green.withOpacity(0.4) : Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(task.isCompleted ? Icons.check_circle
                          : (task.type == 'shake' ? Icons.vibration : Icons.touch_app),
                          color: task.isCompleted ? Colors.green : Colors.blue, size: 32),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(task.title, style: TextStyle(
                          color: task.isCompleted ? Colors.white38 : Colors.white,
                          fontWeight: FontWeight.bold)),
                        Text(task.description,
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ])),
                      if (!task.isCompleted)
                        const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskView(TaskModel task) {
    return GestureDetector(
      onTap: task.type == 'tap' ? () => _onTapTask(task) : null,
      child: Container(
        width: double.infinity, height: double.infinity, color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Crewmate doing the task
            const HorrorCrewmate(bodyColor: Color(0xFF003399), size: 80),
            const SizedBox(height: 16),
            Text(task.title, style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(task.description, style: const TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),

            if (task.type == 'tap') ...[
              GestureDetector(
                onTap: () => _onTapTask(task),
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: const Color(0xFF001A33),
                    border: Border.all(color: Colors.blue, width: 3),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                  ),
                  child: Center(child: Text('$_tapCount/10',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
                ),
              ),
              const SizedBox(height: 24),
              const Text('TAP THE CIRCLE!', style: TextStyle(color: Colors.blue, letterSpacing: 4, fontSize: 14)),
            ],

            if (task.type == 'shake') ...[
              const Icon(Icons.vibration, color: Colors.blue, size: 80),
              const SizedBox(height: 24),
              const Text('SHAKE YOUR PHONE!', style: TextStyle(color: Colors.blue, letterSpacing: 4, fontSize: 14)),
            ],

            const SizedBox(height: 40),
            TextButton(
              onPressed: () { _accelSub?.cancel(); setState(() { _taskInProgress = false; _activeTask = null; }); },
              child: const Text('← BACK', style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }
}
