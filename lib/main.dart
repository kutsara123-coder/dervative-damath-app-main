import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'utils/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundService().initialize();
  runApp(const DerivativeDamathApp());
}

class DerivativeDamathApp extends StatelessWidget {
  const DerivativeDamathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Derivative Damath',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
