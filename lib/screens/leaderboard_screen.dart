import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/leaderboard_service.dart';
import '../services/auth_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboardService = LeaderboardService();
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('LEADERBOARD',
            style: TextStyle(
                color: Colors.white, letterSpacing: 3, fontSize: 16)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: leaderboardService.getLeaderboard(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No players yet!',
                  style: TextStyle(color: Colors.white54)),
            );
          }

          List<Map<String, dynamic>> players = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: players.length,
            itemBuilder: (ctx, i) {
              final player = players[i];
              bool isMe = player['uid'] == auth.currentUser?.uid;
              int rank = i + 1;

              Color rankColor = Colors.white54;
              if (rank == 1) rankColor = Colors.yellow;
              if (rank == 2) rankColor = Colors.grey;
              if (rank == 3) rankColor = const Color(0xFFCD7F32);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFF1A0A00)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMe
                        ? Colors.red.withOpacity(0.5)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 40,
                      child: Text(
                        rank <= 3 ? _rankEmoji(rank) : '#$rank',
                        style: TextStyle(
                            color: rankColor,
                            fontSize: rank <= 3 ? 22 : 16,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Username
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                player['username'] ?? 'Unknown',
                                style: TextStyle(
                                    color: isMe ? Colors.red : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('YOU',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 9,
                                          letterSpacing: 1)),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${player['totalGames'] ?? 0} games played',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    // Stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${player['wins'] ?? 0} wins',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                        Text('${player['losses'] ?? 0} losses',
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }
}
