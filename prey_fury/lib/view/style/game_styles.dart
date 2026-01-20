import 'dart:ui';
import 'package:flutter/material.dart';
import '../../kernel/models/prey.dart';

class GameStyles {
  // --- PAINTS ---
  
  // Snake
  static final Paint snakeBody = Paint()..color = const Color(0xFF00FF88);
  static final Paint snakeHead = Paint()..color = const Color(0xFFFFFFFF);
  static final Paint snakeGlow = Paint()
    ..color = const Color(0xFF00FF88).withOpacity(0.4)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
  // Fury
  static final Paint furyBody = Paint()..color = const Color(0xFFFF6600);
  static final Paint furyGlow = Paint()
    ..color = const Color(0xFFFF4400).withOpacity(0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
  // Background
  static final Paint background = Paint()..color = const Color(0xFF0A0A1A);
  static final Paint furyBackground = Paint()..color = const Color(0xFF1A0505);
  static final Paint gridLine = Paint()
    ..color = const Color(0xFF1A2A3A)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
  static final Paint furyGridLine = Paint()
    ..color = const Color(0xFF4A2020)
    ..strokeWidth = 1.0;
  static final Paint gridGlow = Paint()
    ..color = const Color(0xFF00FFFF).withOpacity(0.1)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  // Food
  static final Paint food = Paint()..color = const Color(0xFFFF2222);
  static final Paint foodGlow = Paint()
    ..color = const Color(0xFFFF0000).withOpacity(0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint foodShine = Paint()..color = Colors.white.withOpacity(0.6);

  // Prey Colors Map (Base Colors)
  static const Map<PreyType, Color> preyColors = {
    PreyType.angryApple: Color(0xFFCC2222),
    PreyType.zombieBurger: Color(0xFF8B5A2B),
    PreyType.ninjaSushi: Color(0xFF4488FF),
    PreyType.ghostPizza: Color(0xFFAA88FF),
    PreyType.goldenCake: Color(0xFFFFD700),
    PreyType.boss: Color(0xFFFF00FF),
  };

  // Reusable Mutable Paints (For when we MUST change color/opacity)
  // Usage Rule: Set properties immediately before use.
  static final Paint mutablePreyGlow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint mutablePreyBody = Paint();
  static final Paint mutableGeneric = Paint();
  
  // Prey Features
  static final Paint eyesWhite = Paint()..color = Colors.white;
  static final Paint eyesBlack = Paint()..color = Colors.black;
  static final Paint eyePupilYellow = Paint()..color = Colors.yellow;
  static final Paint sweatDrop = Paint()..color = Colors.lightBlueAccent;
  static final Paint eyebrow = Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke;
  static final Paint bossAura = Paint()..color = Colors.purpleAccent.withOpacity(0.5);
  static final Paint bossBody = Paint()..color = Colors.purple.shade900;
  static final Paint bossEyeRed = Paint()..color = Colors.redAccent;
  static final Paint bossCrown = Paint()..color = Colors.amber;
  static final Paint hpBarBg = Paint()..color = Colors.black;
  static final Paint hpBarFg = Paint()..color = Colors.red;
  static final Paint mouthWhiteStroke = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;

  // FX
  static final Paint lightning = Paint()
    ..color = Colors.cyanAccent
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
  static final Paint voidHolefill = Paint()..color = Colors.purple.withOpacity(0.3)..style = PaintingStyle.fill;
  static final Paint voidCore = Paint()..color = Colors.black;
  static final Paint voidLines = Paint()..color = Colors.purpleAccent.withOpacity(0.5)..strokeWidth = 1;
}
