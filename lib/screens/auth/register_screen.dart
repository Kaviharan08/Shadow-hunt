import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/forest_map.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Hunter name required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthService>().register(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _nameCtrl.text.trim(),
        );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _loading = false;
      });
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040816),
      body: Stack(
        children: [
          const Positioned.fill(child: CosmicLoginBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: ToxicTheme.cyan.withOpacity(0.25)),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F152A).withOpacity(0.84),
                          const Color(0xFF08101F).withOpacity(0.92),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ToxicTheme.purple.withOpacity(0.16),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: ToxicTheme.greenGlow),
                            ),
                          ],
                        ),
                        const ArcaneAvatar(),
                        const SizedBox(height: 8),
                        const Text(
                          'REGISTER EXPLORER',
                          style: TextStyle(
                            color: ToxicTheme.greenGlow,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ENTER THE CURSED REALM',
                          style: TextStyle(
                            color: ToxicTheme.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ArcaneField(
                          controller: _nameCtrl,
                          hint: 'HUNTER NAME',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                        ArcaneField(
                          controller: _emailCtrl,
                          hint: 'EMAIL',
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 14),
                        ArcaneField(
                          controller: _passCtrl,
                          hint: 'PASSWORD',
                          icon: Icons.lock_outline_rounded,
                          obscure: true,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: ToxicTheme.red.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: ToxicTheme.red.withOpacity(0.35)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: ToxicTheme.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        GlowButton(
                          text: _loading ? 'OPENING GATE...' : 'BEGIN THE HUNT',
                          onTap: _loading ? null : _register,
                          loading: _loading,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          child: const Text(
                            '> ALREADY MARKED? LOGIN',
                            style: TextStyle(
                              color: ToxicTheme.greenGlow,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
