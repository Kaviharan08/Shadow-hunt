import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/horror_crewmate.dart';
import 'home_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnim = Tween<double>(begin: 60, end: 0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    Future.delayed(const Duration(seconds: 4), _navigate);
  }

  void _navigate() {
    User? user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => user != null ? const HomeScreen() : const LoginScreen(),
    ));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnim.value,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.05 * _fadeAnim.value),
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HorrorCrewmate(bodyColor: Color(0xFF8B0000), isHunter: true, size: 120),
                        const SizedBox(height: 32),
                        const Text('SHADOW HUNT', style: TextStyle(
                          color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold,
                          letterSpacing: 8, shadows: [Shadow(color: Colors.red, blurRadius: 20)],
                        )),
                        const SizedBox(height: 12),
                        const Text('Hunt or be hunted...', style: TextStyle(
                          color: Colors.red, fontSize: 16, fontStyle: FontStyle.italic, letterSpacing: 2,
                        )),
                        const SizedBox(height: 48),
                        const CircularProgressIndicator(color: Color(0xFF8B0000)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40, left: 0, right: 0,
                  child: Opacity(opacity: _fadeAnim.value, child: const WalkingCrewmates()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
