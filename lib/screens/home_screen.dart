import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/horror_crewmate.dart';
import 'lobby_screen.dart';
import 'leaderboard_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Positioned(bottom: -80, right: -80, child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.06)),
          )),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('SHADOW HUNT', style: TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
                        FutureBuilder<String>(
                          future: auth.getUsername(),
                          builder: (ctx, snap) => Text('Hello, ${snap.data ?? '...'}',
                              style: const TextStyle(color: Colors.white54, fontSize: 14)),
                        ),
                      ]),
                      IconButton(
                        onPressed: () async {
                          await auth.logout();
                          if (context.mounted) Navigator.pushReplacement(
                              context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        icon: const Icon(Icons.logout, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Animated crewmate in center
                  Center(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)],
                          ),
                          child: const HorrorCrewmate(bodyColor: Color(0xFF8B0000), isHunter: true, size: 110),
                        ),
                        const SizedBox(height: 8),
                        const Text('"No one escapes the darkness"',
                            style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic, fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildMenuButton(context, icon: Icons.add_circle_outline, label: 'CREATE ROOM',
                    subtitle: 'Host a new game',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LobbyScreen(isHost: true))),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(context, icon: Icons.login, label: 'JOIN ROOM',
                    subtitle: 'Enter with a room code',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LobbyScreen(isHost: false))),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(context, icon: Icons.leaderboard, label: 'LEADERBOARD',
                    subtitle: 'Top hunters worldwide',
                    color: const Color(0xFF1A1A2E),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                  ),

                  const Spacer(),
                  // Walking crewmates at bottom
                  const WalkingCrewmates(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {
    required IconData icon, required String label,
    required String subtitle, required VoidCallback onTap,
    Color color = const Color(0xFF1A0000),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.25), width: 1),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.red, size: 28),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 15)),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ]),
      ),
    );
  }
}
