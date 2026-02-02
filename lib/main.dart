import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: firebaseWebOptions);
  } else {
    await Firebase.initializeApp();
  }
  await FirebaseService.instance.init();

  final initialUser = FirebaseService.instance.getCurrentUser();

  runApp(MyApp(initialRoute: initialUser == null
      ? LoginScreen.routeName
      : ChatScreen.routeName));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8D7BFF),
      surface: const Color(0xFFFDF7F0),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Public Chat',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: baseColorScheme,
        scaffoldBackgroundColor: baseColorScheme.surface,
        textTheme: GoogleFonts.poppinsTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8D7BFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        ChatScreen.routeName: (_) => const ChatScreen(),
      },
    );
  }
}
