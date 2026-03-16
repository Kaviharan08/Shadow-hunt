import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Already initialized — ignore
  }
  
  runApp(const ShadowHuntApp());
}

class ShadowHuntApp extends StatelessWidget {
  const ShadowHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Shadow Hunt',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFFFF3333),
            secondary: const Color(0xFF8B0000),
            background: const Color(0xFF0A0A0A),
            surface: const Color(0xFF1A1A1A),
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}