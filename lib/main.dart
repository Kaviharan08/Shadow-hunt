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
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  runApp(const ShadowHuntApp());
}

class ShadowHuntApp extends StatelessWidget {
  const ShadowHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'Shadow Hunt',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF3333),
            secondary: Color(0xFF8B0000),
            surface: Color(0xFF1A1A1A),
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
