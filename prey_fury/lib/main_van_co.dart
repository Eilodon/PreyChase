/// Vạn Cổ Chi Vương - Main Entry Point
///
/// Run this file to play the new Battle Royale version:
/// flutter run -t lib/main_van_co.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'van_co_game/van_co_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (landscape for better gameplay)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Set fullscreen mode
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(const VanCoChiVuongApp());
}

class VanCoChiVuongApp extends StatelessWidget {
  const VanCoChiVuongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const VanCoGameWidget();
  }
}
