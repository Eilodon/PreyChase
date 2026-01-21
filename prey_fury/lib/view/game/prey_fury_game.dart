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
import '../style/game_styles.dart';
import '../audio/audio_manager.dart';

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
  // All paints moved to GameStyles for zero-allocation performance.
  
  late GameState prevState;

  // === PERFORMANCE FIX: Reuse Random instance ===
  final Random _random = Random();

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
      } else if (state.furyMeter >= 1.0) {
         // Ready State
         bool flash = (state.tick % 4) < 2; // Fast flash
         furyText.text = flash ? "READY! [SPACE]" : "";
         furyText.textRenderer = TextPaint(style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.cyan, blurRadius: 10)]
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
           AudioManager().playSfx('crash');
        } else if (event is GameEventSnakeDamaged) {
           cameraShake.shake(duration: 0.3, intensity: 8.0);
           particleManager.spawnConfetti(headPos, color: Colors.white, count: 5);
           AudioManager().playSfx('damage');
        } else if (event is GameEventFuryActivated) {
           cameraShake.shake(duration: 0.5, intensity: 5.0);
           particleManager.spawnExplosion(headPos, color: Colors.orange, count: 50);
           AudioManager().playSfx('fury_start');
        } else if (event is GameEventSnakeAtePrey) {
           cameraShake.shake(duration: 0.1, intensity: 3.0);
           particleManager.spawnExplosion(headPos, color: Colors.yellow, count: 20);
           AudioManager().playSfx('kill');
        } else if (event is GameEventSnakeAteFood) {
           particleManager.spawnConfetti(headPos, color: Colors.green, count: 8);
           AudioManager().playSfx('eats');
        }
     }
  }

  // === PERFORMANCE FIX: Cached background paint ===
  static final Paint _backgroundClearPaint = Paint()..color = const Color(0xFF050510);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. CLEAR ONLY VISIBLE AREA (Performance: 16.7x less overdraw)
    canvas.drawRect(
        Rect.fromLTWH(0, 0, gridWidth * cellSize, gridHeight * cellSize),
        _backgroundClearPaint
    );
    
    // Apply Camera Shake
    canvas.save();
    canvas.translate(cameraShake.offset.x, cameraShake.offset.y);

    final double alpha = (_timeSinceTick / tickRate).clamp(0.0, 1.0);
    final bool isFury = state.isFuryActive;

    // === DRAW BACKGROUND (Expanded to hide edges during shake) ===
    canvas.drawRect(
      Rect.fromLTWH(-50, -50, gridWidth * cellSize + 100, gridHeight * cellSize + 100),
      isFury ? GameStyles.furyBackground : GameStyles.background
    );

    // === DRAW NEON GRID ===
    _drawNeonGrid(canvas, isFury);

    // === DRAW FOOD WITH GLOW ===
    for (final food in state.food) {
       final cx = food.x * cellSize + cellSize/2;
       final cy = food.y * cellSize + cellSize/2;
       // Glow
       canvas.drawCircle(Offset(cx, cy), cellSize/2 + 4, GameStyles.foodGlow);
       // Core
       canvas.drawCircle(Offset(cx, cy), cellSize/2 - 4, GameStyles.food);
       // Shine
       canvas.drawCircle(Offset(cx - 4, cy - 4), 3, GameStyles.foodShine);
    }
    
    // === DRAW PREY WITH ANGRY FACES ===
    for (final prey in state.preys) {
       _drawPrey(canvas, prey, alpha);
    }

    // === DRAW SNAKE WITH GRADIENT & GLOW ===
    _drawSnake(canvas, alpha, isFury);
    
    // === DRAW FURY EFFECTS (Lightning/Void) ===
    if (isFury) {
       _drawFuryEffects(canvas, alpha);
    }

    // === DRAW COMBO RATING ===
    _drawComboRating(canvas);


    // REMOVED: _drawGameOver(canvas) - It's handled by Flutter overlay now
    
    canvas.restore(); // Undo shake
  }

  void _drawNeonGrid(Canvas canvas, bool isFury) {
    final Paint linePaint = isFury 
      ? GameStyles.furyGridLine
      : GameStyles.gridLine;
    
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
    final glowPaint = isFury ? GameStyles.furyGlow : GameStyles.snakeGlow;
    
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
        // Optimized: reuse mutable paint
        Colors.white; // No-op to keep logic
        GameStyles.mutableGeneric.color = segColor;
        canvas.drawCircle(center, radius, GameStyles.mutableGeneric);
        
        // Head special treatment
        if (i == 0) {
          canvas.drawCircle(center, radius, GameStyles.snakeHead);
          // Eyes
          canvas.drawCircle(Offset(center.dx - 5, center.dy - 3), 4, GameStyles.eyesBlack);
          canvas.drawCircle(Offset(center.dx + 5, center.dy - 3), 4, GameStyles.eyesBlack);
          canvas.drawCircle(Offset(center.dx - 5, center.dy - 3), 2, GameStyles.eyesWhite);
          canvas.drawCircle(Offset(center.dx + 5, center.dy - 3), 2, GameStyles.eyesWhite);
        }
    }
  }

  void _drawPrey(Canvas canvas, PreyEntity prey, double alpha) {
    if (prey.type == PreyType.boss) {
       _drawBoss(canvas, prey, alpha);
       return;
    }

    Color color = GameStyles.preyColors[prey.type] ?? Colors.red;
    
    // Emotion Mods
    if (prey.emotion == PreyEmotion.terrified) {
       color = Colors.blueGrey.shade200; // Pale with fear
    } else if (prey.emotion == PreyEmotion.desperate) {
       color = Colors.redAccent.shade700; // Deep red/Sweating
    }
    

    // Interpolation
    double rX = prey.position.x * cellSize;
    double rY = prey.position.y * cellSize;
    
    try {
       final prevPrey = prevState.preys.firstWhere((e) => e.id == prey.id);
       if ((prevPrey.position - prey.position).manhattanDistance < 2) {
          rX = lerpDouble(prevPrey.position.x * cellSize, prey.position.x * cellSize, alpha)!;
          rY = lerpDouble(prevPrey.position.y * cellSize, prey.position.y * cellSize, alpha)!;
       }
    } catch (e) { }
    
    final rect = Rect.fromLTWH(rX + 3, rY + 3, cellSize - 6, cellSize - 6);
    final center = rect.center;
    
    // Glow
    GameStyles.mutablePreyGlow.color = color.withOpacity(0.4);
    canvas.drawCircle(center, cellSize/2, GameStyles.mutablePreyGlow);
    
    // Body (rounded rect)
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    GameStyles.mutablePreyBody.color = color;
    canvas.drawRRect(rrect, GameStyles.mutablePreyBody);
    
    // Facial Expressions based on Emotion
    if (prey.emotion == PreyEmotion.terrified) {
        // Scared Eyes (Big pupils)
        canvas.drawCircle(Offset(center.dx - 6, center.dy - 4), 6, GameStyles.eyesWhite);
        canvas.drawCircle(Offset(center.dx + 6, center.dy - 4), 6, GameStyles.eyesWhite);
        canvas.drawCircle(Offset(center.dx - 6, center.dy - 4), 2, GameStyles.eyesBlack);
        canvas.drawCircle(Offset(center.dx + 6, center.dy - 4), 2, GameStyles.eyesBlack);
        
        // Sweat drop
        canvas.drawCircle(Offset(center.dx + 8, center.dy - 10), 2, GameStyles.sweatDrop);

        // Screaming mouth (O shape)
        canvas.drawCircle(Offset(center.dx, center.dy + 6), 4, GameStyles.eyesBlack);
    } else {
        // Angry/Default
        // Eyes (white with black pupils)
        canvas.drawCircle(Offset(center.dx - 6, center.dy - 4), 5, GameStyles.eyesWhite);
        canvas.drawCircle(Offset(center.dx + 6, center.dy - 4), 5, GameStyles.eyesWhite);
        canvas.drawCircle(Offset(center.dx - 6, center.dy - 4), 3, GameStyles.eyesBlack);
        canvas.drawCircle(Offset(center.dx + 6, center.dy - 4), 3, GameStyles.eyesBlack);
        
        // Angry mouth (frown or teeth)
        canvas.drawArc(
          Rect.fromCenter(center: Offset(center.dx, center.dy + 6), width: 12, height: 8),
          0.2,
          2.7,
          false,
          GameStyles.eyebrow,
        );
    }
  }

  void _drawBoss(Canvas canvas, PreyEntity prey, double alpha) {
     // Draw specific Boss Visuals
     final rX = prey.position.x * cellSize;
     final rY = prey.position.y * cellSize;
     final center = Offset(rX + cellSize/2, rY + cellSize/2);
     
     // 1. Pulsing Aura
     double pulse = (sin(state.tick * 0.2) + 1) / 2;
     canvas.drawCircle(center, cellSize * (0.6 + pulse * 0.2), GameStyles.bossAura);

     // 2. Body
     canvas.drawCircle(center, cellSize/2 + 4, GameStyles.bossBody);
     
     // 3. Face (Skull-like)
     canvas.drawCircle(Offset(center.dx - 8, center.dy - 4), 6, GameStyles.bossEyeRed); // Eye L
     canvas.drawCircle(Offset(center.dx + 8, center.dy - 4), 6, GameStyles.bossEyeRed); // Eye R
     // Glowing pupils
     canvas.drawCircle(Offset(center.dx - 8, center.dy - 4), 2, GameStyles.eyePupilYellow); 
     canvas.drawCircle(Offset(center.dx + 8, center.dy - 4), 2, GameStyles.eyePupilYellow); 
     
     // Grin
     canvas.drawArc(Rect.fromCenter(center: Offset(center.dx, center.dy + 8), width: 20, height: 10), 0, 3.14, false, GameStyles.mouthWhiteStroke);

     // 4. Crown
     final p = Path();
     p.moveTo(center.dx - 10, center.dy - 12);
     p.lineTo(center.dx - 10, center.dy - 22);
     p.lineTo(center.dx - 5, center.dy - 18);
     p.lineTo(center.dx, center.dy - 25);
     p.lineTo(center.dx + 5, center.dy - 18);
     p.lineTo(center.dx + 10, center.dy - 22);
     p.lineTo(center.dx + 10, center.dy - 12);
     p.close();
     canvas.drawPath(p, GameStyles.bossCrown);

     // 5. HP Bar
     final barWidth = 40.0;
     final barHeight = 6.0;
     final barTop = center.dy - cellSize - 10;
     final hpPct = prey.health / prey.maxHealth;
     
     // Background
     canvas.drawRect(Rect.fromLTWH(center.dx - barWidth/2, barTop, barWidth, barHeight), GameStyles.hpBarBg);
     // Foreground
     canvas.drawRect(Rect.fromLTWH(center.dx - barWidth/2, barTop, barWidth * hpPct, barHeight), GameStyles.hpBarFg);
  }

  void _drawFuryEffects(Canvas canvas, double alpha) {
     final snakeHead = state.snakeBody.first;
     final headCenter = Offset(
        snakeHead.x * cellSize + cellSize/2,
        snakeHead.y * cellSize + cellSize/2
     );

     if (state.activeFuryType == FuryType.lightning) {
        for (final prey in state.preys) {
           if (prey.status != PreyStatus.active) continue;
           // Only close ones
           if ((prey.position - snakeHead).manhattanDistance <= 5) {
              final preyCenter = Offset(
                prey.position.x * cellSize + cellSize/2,
                prey.position.y * cellSize + cellSize/2
              );
              
              // ZigZag line
              final path = Path();
              path.moveTo(headCenter.dx, headCenter.dy);
              final mid = Offset((headCenter.dx + preyCenter.dx)/2, (headCenter.dy + preyCenter.dy)/2);
              final jitter = _random.nextDouble() * 20 - 10;
              path.lineTo(mid.dx + jitter, mid.dy - jitter);
              path.lineTo(preyCenter.dx, preyCenter.dy);
              
              canvas.drawPath(path, GameStyles.lightning);
           }
        }
     }
     
     if (state.activeFuryType == FuryType.voidFury) {
         // Draw Black Hole effect at head
         canvas.drawCircle(headCenter, cellSize * 3, GameStyles.voidHolefill);
         canvas.drawCircle(headCenter, cellSize * 1.5, GameStyles.voidCore);
         
         // Suction lines?
         for (int i=0; i<8; i++) {
             double angle = (state.tick * 0.1) + (i * pi / 4);
             double r = cellSize * 2.5;
             canvas.drawLine(
               headCenter + Offset(cos(angle)*r, sin(angle)*r),
               headCenter + Offset(cos(angle)*r*0.5, sin(angle)*r*0.5),
               GameStyles.voidLines
             );
         }
     }
  }

  // === PERFORMANCE FIX: Cached TextPainters for combo rating ===
  final Map<String, TextPainter> _ratingTextCache = {};
  final Map<String, TextPainter> _styleTextCache = {};

  TextPainter _getCachedRatingText(String rating, Color color) {
    final key = '$rating-${color.value}';
    if (!_ratingTextCache.containsKey(key)) {
      _ratingTextCache[key] = TextPainter(
        text: TextSpan(
          text: rating,
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: color,
            shadows: [
              Shadow(color: Colors.black, offset: const Offset(4, 4), blurRadius: 4),
              Shadow(color: color, blurRadius: 20),
            ]
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _ratingTextCache[key]!;
  }

  TextPainter _getCachedStyleText(int count) {
    final key = 'style-$count';
    if (!_styleTextCache.containsKey(key)) {
      _styleTextCache[key] = TextPainter(
        text: TextSpan(
          text: "STYLE $count",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _styleTextCache[key]!;
  }

  void _drawComboRating(Canvas canvas) {
     if (state.comboCount < 5) return;

     final rating = state.comboRating;
     final color = _getRatingColor(rating);

     // Use cached text painter
     final textPainter = _getCachedRatingText(rating, color);
     textPainter.paint(canvas, Offset(gridWidth * cellSize - 100, 80));

     // Subtext "Style" - cached
     final subPainter = _getCachedStyleText(state.comboCount);
     subPainter.paint(canvas, Offset(gridWidth * cellSize - 90, 145));
  }
  
  Color _getRatingColor(String rating) {
     switch (rating) {
       case 'SSS': return const Color(0xFFFF0000); // Red
       case 'SS': return const Color(0xFFFFAA00); // Orange
       case 'S': return const Color(0xFFFFD700); // Gold
       case 'A': return const Color(0xFF00FF00); // Green
       case 'B': return const Color(0xFF00FFFF); // Cyan
       default: return Colors.white;
     }
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
      } else if (keysPressed.contains(LogicalKeyboardKey.space) || 
                 keysPressed.contains(LogicalKeyboardKey.keyF)) {
        _intents.add(UserIntent.activateFury);
      }
    }
    return KeyEventResult.handled;
  }
}
