import 'dart:ui';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../kernel/logic/game_ticker.dart';
import '../../kernel/state/game_state.dart';
import '../../kernel/actions/user_intent.dart';
import '../../kernel/models/prey.dart';
import '../../kernel/events/game_event.dart';
import '../effects/camera_shake.dart';
import '../effects/particle_manager.dart';

class PreyFuryGame extends FlameGame with KeyboardEvents {
  final Function(int score)? onGameOver;
  
  late GameTicker ticker;
  late GameState state;
  final CameraShake cameraShake = CameraShake();
  late ParticleManager particleManager;

  // Configuration
  static const int gridWidth = 30;
  static const int gridHeight = 20;
  static const double cellSize = 30.0;
  static const double tickRate = 0.12; // ~8.3 TPS (slightly faster for smoother feel)

  double _timeSinceTick = 0.0;
  final List<UserIntent> _intents = [];
  
  // UI Components
  late TextComponent scoreText;
  late TextComponent furyText;

  // === ENHANCED VISUAL PAINTS ===
  
  // Snake paints with neon glow
  final Paint snakeBodyPaint = Paint()..color = const Color(0xFF00FF88);
  final Paint snakeHeadPaint = Paint()..color = const Color(0xFFFFFFFF);
  final Paint snakeGlowPaint = Paint()
    ..color = const Color(0xFF00FF88).withOpacity(0.4)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  
  // Fury mode paints
  final Paint furyBodyPaint = Paint()..color = const Color(0xFFFF6600);
  final Paint furyGlowPaint = Paint()
    ..color = const Color(0xFFFF4400).withOpacity(0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  
  // Background
  final Paint backgroundPaint = Paint()..color = const Color(0xFF0A0A1A);
  final Paint furyBackgroundPaint = Paint()..color = const Color(0xFF1A0505);
  final Paint gridLinePaint = Paint()
    ..color = const Color(0xFF1A2A3A)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
  final Paint gridGlowPaint = Paint()
    ..color = const Color(0xFF00FFFF).withOpacity(0.1)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  
  // Food paints
  final Paint foodPaint = Paint()..color = const Color(0xFFFF2222);
  final Paint foodGlowPaint = Paint()
    ..color = const Color(0xFFFF0000).withOpacity(0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  
  // Prey paints by type
  final Map<PreyType, Color> preyColors = {
    PreyType.angryApple: const Color(0xFFCC2222),
    PreyType.zombieBurger: const Color(0xFF8B5A2B),
    PreyType.ninjaSushi: const Color(0xFF4488FF),
    PreyType.ghostPizza: const Color(0xFFAA88FF),
    PreyType.goldenCake: const Color(0xFFFFD700),
  };

  late GameState prevState;

  PreyFuryGame({this.onGameOver});

  @override
  Future<void> onLoad() async {
    ticker = GameTicker(gridWidth: gridWidth, gridHeight: gridHeight);
    state = GameState.initial(gridWidth: gridWidth, gridHeight: gridHeight);
    prevState = state;
    
    particleManager = ParticleManager();
    add(particleManager);
    
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(10, gridHeight * cellSize + 10),
      textRenderer: TextPaint(style: const TextStyle(
        color: Colors.white, 
        fontSize: 18,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.cyan, blurRadius: 8)],
      )),
    );
    add(scoreText);
    
    furyText = TextComponent(
      text: '',
      position: Vector2(gridWidth * cellSize - 120, gridHeight * cellSize + 10),
      textRenderer: TextPaint(style: const TextStyle(
        color: Colors.orange, 
        fontSize: 18, 
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.orange, blurRadius: 10)],
      )),
    );
    add(furyText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timeSinceTick += dt;
    if (state.status == GameStatus.playing) {
       cameraShake.update(dt);
    }

    if (_timeSinceTick >= tickRate) {
      _timeSinceTick -= tickRate;
      prevState = state;
      final result = ticker.tick(state, List.from(_intents));
      state = result.state;
      _handleEvents(result.events);
      _intents.clear();
      
      // Check for game over
      if (state.status == GameStatus.gameOver && prevState.status == GameStatus.playing) {
        onGameOver?.call(state.score);
      }
      
      // Sync UI
      scoreText.text = 'Score: ${state.score}';
      if (state.isFuryActive) {
         furyText.text = "🔥 FURY! ${state.furyTimer}";
         furyText.textRenderer = TextPaint(style: const TextStyle(
           color: Colors.orange, 
           fontSize: 20, 
           fontWeight: FontWeight.bold,
           shadows: [Shadow(color: Colors.red, blurRadius: 15)],
         ));
      } else {
         int pct = (state.furyMeter * 100).toInt();
         furyText.text = "⚡ Meter: $pct%";
         furyText.textRenderer = TextPaint(style: TextStyle(
           color: Colors.grey.shade400, 
           fontSize: 16,
         ));
      }
    }
  }
  
  void _handleEvents(List<GameEvent> events) {
     final headPos = Vector2(
        state.snakeBody.first.x * cellSize + cellSize/2, 
        state.snakeBody.first.y * cellSize + cellSize/2
     );
     
     for (final event in events) {
        if (event is GameEventSnakeHitWall || event is GameEventSnakeHitSelf) {
           cameraShake.shake(duration: 0.5, intensity: 10.0);
           particleManager.spawnExplosion(headPos, color: Colors.red);
        } else if (event is GameEventSnakeDamaged) {
           cameraShake.shake(duration: 0.3, intensity: 8.0);
           particleManager.spawnConfetti(headPos, color: Colors.white, count: 5);
        } else if (event is GameEventFuryActivated) {
           cameraShake.shake(duration: 0.5, intensity: 5.0);
           particleManager.spawnExplosion(headPos, color: Colors.orange, count: 50);
        } else if (event is GameEventSnakeAtePrey) {
           cameraShake.shake(duration: 0.1, intensity: 3.0);
           particleManager.spawnExplosion(headPos, color: Colors.yellow, count: 20);
        } else if (event is GameEventSnakeAteFood) {
           particleManager.spawnConfetti(headPos, color: Colors.green, count: 8);
        }
     }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // 1. CLEAR EVERYTHING (Safety against artifacts)
    canvas.drawRect(
        const Rect.fromLTWH(-1000, -1000, 3000, 3000), 
        Paint()..color = backgroundColor()
    );
    
    // Apply Camera Shake
    canvas.save();
    canvas.translate(cameraShake.offset.x, cameraShake.offset.y);

    final double alpha = (_timeSinceTick / tickRate).clamp(0.0, 1.0);
    final bool isFury = state.isFuryActive;

    // === DRAW BACKGROUND (Expanded to hide edges during shake) ===
    canvas.drawRect(
      Rect.fromLTWH(-50, -50, gridWidth * cellSize + 100, gridHeight * cellSize + 100),
      isFury ? furyBackgroundPaint : backgroundPaint
    );

    // === DRAW NEON GRID ===
    _drawNeonGrid(canvas, isFury);

    // === DRAW FOOD WITH GLOW ===
    for (final food in state.food) {
       final cx = food.x * cellSize + cellSize/2;
       final cy = food.y * cellSize + cellSize/2;
       // Glow
       canvas.drawCircle(Offset(cx, cy), cellSize/2 + 4, foodGlowPaint);
       // Core
       canvas.drawCircle(Offset(cx, cy), cellSize/2 - 4, foodPaint);
       // Shine
       canvas.drawCircle(Offset(cx - 4, cy - 4), 3, Paint()..color = Colors.white.withOpacity(0.6));
    }
    
    // === DRAW PREY WITH ANGRY FACES ===
    for (final prey in state.preys) {
       _drawPrey(canvas, prey, alpha);
    }

    // === DRAW SNAKE WITH GRADIENT & GLOW ===
    _drawSnake(canvas, alpha, isFury);

    // REMOVED: _drawGameOver(canvas) - It's handled by Flutter overlay now
    
    canvas.restore(); // Undo shake
  }

  void _drawNeonGrid(Canvas canvas, bool isFury) {
    final Paint linePaint = isFury 
      ? (Paint()..color = const Color(0xFF4A2020)..strokeWidth = 1)
      : gridLinePaint;
    
    // Vertical lines
    for (int x = 0; x <= gridWidth; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, gridHeight * cellSize),
        linePaint,
      );
    }
    // Horizontal lines
    for (int y = 0; y <= gridHeight; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(gridWidth * cellSize, y * cellSize),
        linePaint,
      );
    }
  }

  void _drawSnake(Canvas canvas, double alpha, bool isFury) {
    final glowPaint = isFury ? furyGlowPaint : snakeGlowPaint;
    
    bool canInterpolate = state.snakeBody.length == prevState.snakeBody.length;
    
    for (int i = state.snakeBody.length - 1; i >= 0; i--) {
        final segment = state.snakeBody[i];
        
        double drawX = segment.x * cellSize;
        double drawY = segment.y * cellSize;
        
        if (canInterpolate && i < prevState.snakeBody.length) {
            final prevSegment = prevState.snakeBody[i];
            drawX = lerpDouble(prevSegment.x * cellSize, segment.x * cellSize, alpha)!;
            drawY = lerpDouble(prevSegment.y * cellSize, segment.y * cellSize, alpha)!;
        }
        
        final rect = Rect.fromLTWH(drawX + 2, drawY + 2, cellSize - 4, cellSize - 4);
        final center = rect.center;
        final radius = (cellSize - 4) / 2;
        
        // Glow layer (larger)
        canvas.drawCircle(center, radius + 4, glowPaint);
        
        // Body gradient based on position
        double t = i / max(1, state.snakeBody.length - 1);
        Color segColor = isFury 
          ? Color.lerp(const Color(0xFFFF8800), const Color(0xFFFF2200), t)!
          : Color.lerp(const Color(0xFF00FF88), const Color(0xFF00AA55), t)!;
        
        // Draw body segment
        canvas.drawCircle(center, radius, Paint()..color = segColor);
        
        // Head special treatment
        if (i == 0) {
          canvas.drawCircle(center, radius, snakeHeadPaint);
          // Eyes
          canvas.drawCircle(Offset(center.dx - 5, center.dy - 3), 4, Paint()..color = Colors.black);
          canvas.drawCircle(Offset(center.dx + 5, center.dy - 3), 4, Paint()..color = Colors.black);
          canvas.drawCircle(Offset(center.dx - 5, center.dy - 3), 2, Paint()..color = Colors.white);
          canvas.drawCircle(Offset(center.dx + 5, center.dy - 3), 2, Paint()..color = Colors.white);
        }
    }
  }

  void _drawPrey(Canvas canvas, PreyEntity prey, double alpha) {
    final color = preyColors[prey.type] ?? Colors.red;
    
    // Try interpolate from previous position
    double rX = prey.position.x * cellSize;
    double rY = prey.position.y * cellSize;
    
    try {
       final prevPrey = prevState.preys.firstWhere((e) => e.id == prey.id);
       rX = lerpDouble(prevPrey.position.x * cellSize, prey.position.x * cellSize, alpha)!;
       rY = lerpDouble(prevPrey.position.y * cellSize, prey.position.y * cellSize, alpha)!;
    } catch (e) {
       // New prey
    }
    
    final rect = Rect.fromLTWH(rX + 3, rY + 3, cellSize - 6, cellSize - 6);
    final center = rect.center;
    
    // Glow
    canvas.drawCircle(center, cellSize/2, Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    
    // Body (rounded rect)
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, Paint()..color = color);
    
    // Angry face!
    // Eyes (white with black pupils)
    canvas.drawCircle(Offset(center.dx - 6, center.dy - 4), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx + 6, center.dy - 4), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx - 6, center.dy - 4), 3, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(center.dx + 6, center.dy - 4), 3, Paint()..color = Colors.black);
    
    // Angry eyebrows (angled lines)
    final eyebrowPaint = Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - 10, center.dy - 10), Offset(center.dx - 3, center.dy - 7), eyebrowPaint);
    canvas.drawLine(Offset(center.dx + 10, center.dy - 10), Offset(center.dx + 3, center.dy - 7), eyebrowPaint);
    
    // Angry mouth (frown or teeth)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 6), width: 12, height: 8),
      0.2,
      2.7,
      false,
      eyebrowPaint,
    );
  }


  
  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
        _intents.add(UserIntent.turnUp);
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
        _intents.add(UserIntent.turnDown);
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
        _intents.add(UserIntent.turnLeft);
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
        _intents.add(UserIntent.turnRight);
      }
    }
    return KeyEventResult.handled;
  }
}
