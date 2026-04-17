import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ProtectApp());
}

class ProtectApp extends StatelessWidget {
  const ProtectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROTECT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
        cardTheme: const CardTheme(elevation: 2),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const LoginScreen(),
    );
  }
}
