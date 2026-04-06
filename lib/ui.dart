import 'package:flutter/material.dart';

class GameUI extends StatelessWidget {
  const GameUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0607),
      body: Stack(
        children: [
          // === GAME BACKGROUND ===
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF1A2B14),
                  Color(0xFF0D1A0A),
                  Color(0xFF060D05),
                ],
              ),
            ),
          ),

          // === TOP HUD ===
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Health Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "HEALTH",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: const LinearProgressIndicator(
                          value: 0.72,
                          minHeight: 10,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(
                            Color(0xFFCC1A1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Role Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: const Text(
                    "SURVIVOR",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === PLAYER INFO (RIGHT) ===
          const Positioned(
            top: 40,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "TASKS",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                Text(
                  "2/3",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "SURVIVORS",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                Text(
                  "3/3",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // === ABILITY BUTTON ===
          Positioned(
            bottom: 120,
            right: 20,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.5),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.cyan),
                ),
                const SizedBox(height: 6),
                const Text(
                  "READY",
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),

          // === TASK PANEL ===
          Positioned(
            bottom: 60,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Text(
                    "OBJECTIVES:",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _taskChip("DECODE SIGNAL", false),
                  const SizedBox(width: 6),
                  _taskChip("HACK TERMINAL", true),
                  const SizedBox(width: 6),
                  _taskChip("RESTORE POWER", false),
                ],
              ),
            ),
          ),

          // === MOVEMENT CONTROLS ===
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlBtn(Icons.arrow_back),
                _controlBtn(Icons.arrow_upward),
                _controlBtn(Icons.arrow_forward),
                _controlBtn(Icons.sports_esports),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === TASK CHIP ===
  Widget _taskChip(String text, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: done
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? Colors.green : Colors.orange,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: done ? Colors.greenAccent : Colors.orangeAccent,
          fontSize: 11,
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }

  // === CONTROL BUTTON ===
  Widget _controlBtn(IconData icon) {
    return FloatingActionButton(
      backgroundColor: Colors.black,
      onPressed: () {},
      child: Icon(icon, color: Colors.redAccent),
    );
  }
}
