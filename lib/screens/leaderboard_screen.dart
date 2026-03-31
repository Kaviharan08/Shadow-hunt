import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _players = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context.read<AuthService>().getLeaderboard();
    setState(() { _players = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF000000), Color(0xFF050F05)]),
          )),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IconButton(onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF446644))),
                    const SizedBox(width: 8),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('LEADERBOARD', style: TextStyle(color: Colors.white,
                          fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4)),
                      Text('TOP HUNTERS', style: TextStyle(color: Color(0xFF446644),
                          fontSize: 11, letterSpacing: 3)),
                    ]),
                  ]),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)))
                  else if (_players.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Text('No players yet', style: TextStyle(color: Color(0xFF446644))),
                    ))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _players.length,
                        itemBuilder: (ctx, i) {
                          final p = _players[i];
                          Color rankColor = i == 0 ? Colors.amber
                              : i == 1 ? Colors.grey[400]!
                              : i == 2 ? const Color(0xFFCD7F32)
                              : const Color(0xFF446644);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: i < 3 ? const Color(0xFF0D1F0D) : const Color(0xFF080D08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: i == 0 ? Colors.amber.withOpacity(0.3)
                                    : const Color(0xFF1A3A1A)),
                            ),
                            child: Row(children: [
                              SizedBox(width: 32,
                                child: Text('#${i + 1}', style: TextStyle(
                                  color: rankColor, fontWeight: FontWeight.bold, fontSize: 14))),
                              if (i < 3) Icon(Icons.emoji_events, color: rankColor, size: 18),
                              if (i >= 3) const Icon(Icons.person, color: Color(0xFF446644), size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(p['username'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.bold, fontSize: 14))),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('${p['wins'] ?? 0} wins',
                                    style: const TextStyle(color: Color(0xFFCC2222),
                                        fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${p['gamesPlayed'] ?? 0} games',
                                    style: const TextStyle(color: Color(0xFF446644), fontSize: 11)),
                              ]),
                            ]),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
