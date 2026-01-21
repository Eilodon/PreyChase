import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../kernel/models/prey.dart';
import 'crocodile_player.dart';
import 'fury_world.dart';

/// Emotion affects visual appearance and behavior
enum PreyVisualEmotion {
  angry,      // 😠 Default - chasing
  terrified,  // 😱 Fury active - fleeing
  desperate,  // 😰 Last alive - speed boost
}

class PreyComponent extends PositionComponent with HasWorldReference<FuryWorld> {
  final PreyType type;
  
  // Physics
  Vector2 velocity = Vector2.zero();
  double maxSpeed = 100.0;
  
  // AI State
  final Random _rnd = Random();
  Vector2 _wanderTarget = Vector2.zero();
  double _wanderTimer = 0.0;
  PreyVisualEmotion emotion = PreyVisualEmotion.angry;
  
  // Visual
  final Paint _basePaint = Paint();
  final Paint _eyeWhite = Paint()..color = Colors.white;
  final Paint _eyeBlack = Paint()..color = Colors.black;
  final Paint _sweatPaint = Paint()..color = Colors.lightBlue.shade200;
  double _animTime = 0.0;
  bool _isBeingEaten = false;

  PreyComponent({
    required this.type,
    required Vector2 position,
  }) : super(position: position, size: Vector2(28, 28), anchor: Anchor.center) {
    _initStats();
  }
  
  CrocodilePlayer get player => world.player;
  
  void _initStats() {
    switch (type) {
      case PreyType.ninjaSushi:
        maxSpeed = 150.0;
        _basePaint.color = const Color(0xFF1A237E); // Dark blue
        break;
      case PreyType.zombieBurger:
        maxSpeed = 50.0;
        _basePaint.color = const Color(0xFF4E342E); // Brown
        size = Vector2(32, 32);
        break;
      case PreyType.ghostPizza:
        maxSpeed = 80.0;
        _basePaint.color = const Color(0xFF7B1FA2).withOpacity(0.8); // Purple
        break;
      case PreyType.goldenCake:
        maxSpeed = 120.0;
        _basePaint.color = const Color(0xFFFFD700); // Gold
        break;
      case PreyType.boss:
        maxSpeed = 60.0;
        size = Vector2(48, 48);
        _basePaint.color = const Color(0xFFB71C1C); // Dark red
        break;
      default:
        maxSpeed = 80.0;
        _basePaint.color = const Color(0xFFD32F2F); // Red (Angry Apple)
    }
  }

  void onEaten() {
    _isBeingEaten = true;
    // Could add death animation here
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
    
    // === UPDATE EMOTION ===
    if (player.isFuryActive) {
      emotion = PreyVisualEmotion.terrified;
    } else if (world.children.whereType<PreyComponent>().length == 1) {
      emotion = PreyVisualEmotion.desperate;
    } else {
      emotion = PreyVisualEmotion.angry;
    }
    
    // === STEERING FORCES ===
    Vector2 force = Vector2.zero();
    
    // 1. Separation (avoid crowding)
    force.add(_separationForce() * 2.0);
    
    // 2. Main behavior based on emotion
    final dist = position.distanceTo(player.position);
    
    switch (emotion) {
      case PreyVisualEmotion.terrified:
        // FLEE from player
        force.add(_flee(player.position) * 3.0);
        break;
        
      case PreyVisualEmotion.desperate:
        // Chase aggressively (suicidal attack)
        force.add(_seek(player.position) * 2.5);
        break;
        
      case PreyVisualEmotion.angry:
        // Type-specific behavior
        if (type == PreyType.goldenCake) {
          // Always flee
          if (dist < 300) {
            force.add(_flee(player.position) * 2.5);
          } else {
            force.add(_wander(dt));
          }
        } else if (type == PreyType.ninjaSushi) {
          // Aggressive chase
          if (dist < 350) {
            force.add(_seek(player.position) * 1.5);
          } else {
            force.add(_wander(dt));
          }
        } else if (type == PreyType.zombieBurger) {
          // Slow chase
          if (dist < 200) {
            force.add(_seek(player.position) * 0.8);
          } else {
            force.add(_wander(dt));
          }
        } else {
          // Default: wander with slight chase
          if (dist < 150) {
            force.add(_seek(player.position) * 0.5);
          } else {
            force.add(_wander(dt));
          }
        }
        break;
    }
    
    // Apply force
    velocity.add(force * dt);
    
    // Speed modifier
    double speedMod = 1.0;
    if (emotion == PreyVisualEmotion.terrified) speedMod = 1.3;
    if (emotion == PreyVisualEmotion.desperate) speedMod = 1.5;
    
    // Cap speed
    final actualMaxSpeed = maxSpeed * speedMod;
    if (velocity.length > actualMaxSpeed) {
      velocity = velocity.normalized() * actualMaxSpeed;
    }
    
    position.add(velocity * dt);
    
    // Rotate to face velocity
    if (!velocity.isZero()) {
      angle = atan2(velocity.y, velocity.x);
    }
    
    // Arena bounds (-900 to 900)
    position.clamp(Vector2.all(-900), Vector2.all(900));
  }
  
  Vector2 _seek(Vector2 target) {
    return (target - position).normalized() * maxSpeed - velocity;
  }
  
  Vector2 _flee(Vector2 target) {
    return (position - target).normalized() * maxSpeed - velocity;
  }
  
  Vector2 _wander(double dt) {
    _wanderTimer += dt;
    if (_wanderTimer > 0.5) {
      _wanderTimer = 0;
      _wanderTarget = Vector2(
        (_rnd.nextDouble() * 2 - 1) * 300,
        (_rnd.nextDouble() * 2 - 1) * 300,
      );
    }
    return _seek(position + _wanderTarget);
  }
  
  // === PERFORMANCE FIX: Use spatial grid instead of O(N²) search ===
  Vector2 _separationForce() {
    Vector2 steering = Vector2.zero();
    int count = 0;

    // Old O(N²) approach (SLOW):
    // final neighbors = parent?.children.whereType<PreyComponent>() ?? [];

    // New O(N) approach using spatial grid (FAST):
    const separationRadius = 40.0;
    final neighbors = world.preyGrid.getNeighborsInRadius(position, separationRadius);

    for (final other in neighbors) {
      if (other == this) continue;

      final d = position.distanceTo(other.position);
      if (d > 0 && d < separationRadius) {
        Vector2 diff = position - other.position;
        diff.normalize();
        diff /= d; // Weight by distance
        steering.add(diff);
        count++;
      }
    }

    if (count > 0) {
      steering /= count.toDouble();
      if (steering.length > 0) {
        steering = steering.normalized() * maxSpeed - velocity;
      }
    }

    return steering;
  }
  
  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(-angle); // Undo rotation for drawing
    canvas.translate(-size.x / 2, -size.y / 2);
    
    // Draw based on type
    switch (type) {
      case PreyType.zombieBurger:
        _drawBurger(canvas);
        break;
      case PreyType.ninjaSushi:
        _drawSushi(canvas);
        break;
      case PreyType.ghostPizza:
        _drawPizza(canvas);
        break;
      case PreyType.goldenCake:
        _drawCake(canvas);
        break;
      case PreyType.boss:
        _drawBoss(canvas);
        break;
      default:
        _drawApple(canvas);
    }
    
    // Draw face based on emotion
    _drawFace(canvas);
    
    canvas.restore();
  }
  
  void _drawBurger(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    
    // Bottom bun
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.6, w, h * 0.4), const Radius.circular(4)),
      Paint()..color = const Color(0xFFD4A373),
    );
    
    // Patty
    canvas.drawRect(
      Rect.fromLTWH(2, h * 0.4, w - 4, h * 0.25),
      Paint()..color = const Color(0xFF5D4037),
    );
    
    // Lettuce
    final lettucePath = Path();
    for (int i = 0; i < 4; i++) {
      lettucePath.addOval(Rect.fromLTWH(i * w / 4, h * 0.35, w / 3, h * 0.15));
    }
    canvas.drawPath(lettucePath, Paint()..color = Colors.green);
    
    // Top bun
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h * 0.4), const Radius.circular(8)),
      Paint()..color = const Color(0xFFD4A373),
    );
    
    // Sesame seeds
    canvas.drawCircle(Offset(w * 0.3, h * 0.15), 2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.7, h * 0.2), 2, Paint()..color = Colors.white);
  }
  
  void _drawSushi(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    
    // Rice base
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.3, w, h * 0.6), const Radius.circular(4)),
      Paint()..color = Colors.white,
    );
    
    // Nori strip
    canvas.drawRect(
      Rect.fromLTWH(w * 0.3, 0, w * 0.4, h),
      Paint()..color = const Color(0xFF1B5E20),
    );
    
    // Fish on top
    canvas.drawOval(
      Rect.fromLTWH(2, 0, w - 4, h * 0.4),
      Paint()..color = const Color(0xFFFF8A65),
    );
  }
  
  void _drawPizza(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final center = Offset(w / 2, h / 2);
    
    // Ghost body (floating blob)
    final ghostPath = Path();
    ghostPath.moveTo(w * 0.1, h * 0.7);
    ghostPath.quadraticBezierTo(w * 0.1, 0, w * 0.5, 0);
    ghostPath.quadraticBezierTo(w * 0.9, 0, w * 0.9, h * 0.7);
    // Wavy bottom
    for (int i = 0; i < 3; i++) {
      ghostPath.quadraticBezierTo(
        w * (0.9 - i * 0.25), h * (i % 2 == 0 ? 0.85 : 0.95),
        w * (0.65 - i * 0.25), h * 0.8,
      );
    }
    ghostPath.close();
    
    // Apply transparency for ghost effect
    final ghostPaint = Paint()..color = _basePaint.color;
    canvas.drawPath(ghostPath, ghostPaint);
    
    // Pepperoni dots
    canvas.drawCircle(Offset(w * 0.3, h * 0.4), 4, Paint()..color = Colors.red.shade700);
    canvas.drawCircle(Offset(w * 0.6, h * 0.3), 3, Paint()..color = Colors.red.shade700);
    canvas.drawCircle(Offset(w * 0.5, h * 0.55), 4, Paint()..color = Colors.red.shade700);
  }
  
  void _drawCake(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    
    // Cake base
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2, h * 0.3, w - 4, h * 0.65), const Radius.circular(4)),
      _basePaint,
    );
    
    // Cream top
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.25, w, h * 0.15), const Radius.circular(8)),
      Paint()..color = Colors.white,
    );
    
    // Cherry on top
    canvas.drawCircle(Offset(w / 2, h * 0.15), 5, Paint()..color = Colors.red);
    canvas.drawLine(Offset(w / 2, h * 0.1), Offset(w / 2 + 3, 0), Paint()..color = Colors.green..strokeWidth = 2);
    
    // Sparkle
    final sparkle = sin(_animTime * 8) * 0.5 + 0.5;
    canvas.drawCircle(
      Offset(w * 0.7, h * 0.2),
      3 * sparkle,
      Paint()..color = Colors.white.withOpacity(sparkle),
    );
  }
  
  void _drawApple(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final center = Offset(w / 2, h / 2);
    
    // Apple body
    canvas.drawCircle(center, w / 2 - 2, _basePaint);
    
    // Stem
    canvas.drawLine(
      Offset(w / 2, 2),
      Offset(w / 2 + 2, -4),
      Paint()..color = const Color(0xFF5D4037)..strokeWidth = 2,
    );
    
    // Leaf
    final leafPath = Path();
    leafPath.moveTo(w / 2 + 2, 0);
    leafPath.quadraticBezierTo(w / 2 + 8, -4, w / 2 + 10, 2);
    leafPath.quadraticBezierTo(w / 2 + 6, 2, w / 2 + 2, 0);
    canvas.drawPath(leafPath, Paint()..color = Colors.green);
  }
  
  void _drawBoss(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final center = Offset(w / 2, h / 2);
    
    // Pulsing aura
    final pulse = (sin(_animTime * 3) + 1) / 2;
    canvas.drawCircle(
      center,
      w / 2 + 5 + pulse * 5,
      Paint()..color = Colors.red.withOpacity(0.3),
    );
    
    // Body
    canvas.drawCircle(center, w / 2, _basePaint);
    
    // Crown
    final crownPath = Path();
    crownPath.moveTo(w * 0.2, h * 0.3);
    crownPath.lineTo(w * 0.2, h * 0.1);
    crownPath.lineTo(w * 0.35, h * 0.2);
    crownPath.lineTo(w * 0.5, 0);
    crownPath.lineTo(w * 0.65, h * 0.2);
    crownPath.lineTo(w * 0.8, h * 0.1);
    crownPath.lineTo(w * 0.8, h * 0.3);
    crownPath.close();
    canvas.drawPath(crownPath, Paint()..color = Colors.yellow.shade700);
  }
  
  void _drawFace(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final eyeY = h * 0.35;
    final eyeSize = type == PreyType.boss ? 6.0 : 4.0;
    
    switch (emotion) {
      case PreyVisualEmotion.terrified:
        // Big scared eyes
        canvas.drawCircle(Offset(w * 0.3, eyeY), eyeSize + 2, _eyeWhite);
        canvas.drawCircle(Offset(w * 0.7, eyeY), eyeSize + 2, _eyeWhite);
        // Tiny pupils
        canvas.drawCircle(Offset(w * 0.3, eyeY), 2, _eyeBlack);
        canvas.drawCircle(Offset(w * 0.7, eyeY), 2, _eyeBlack);
        // Sweat drop
        canvas.drawCircle(Offset(w * 0.85, eyeY - 5), 3, _sweatPaint);
        // Screaming mouth
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w / 2, h * 0.65), width: 10, height: 8),
          _eyeBlack,
        );
        break;
        
      case PreyVisualEmotion.desperate:
        // Intense eyes
        canvas.drawCircle(Offset(w * 0.3, eyeY), eyeSize, _eyeWhite);
        canvas.drawCircle(Offset(w * 0.7, eyeY), eyeSize, _eyeWhite);
        canvas.drawCircle(Offset(w * 0.3, eyeY), eyeSize - 1, Paint()..color = Colors.red);
        canvas.drawCircle(Offset(w * 0.7, eyeY), eyeSize - 1, Paint()..color = Colors.red);
        // Gritted teeth
        canvas.drawRect(
          Rect.fromCenter(center: Offset(w / 2, h * 0.65), width: 12, height: 4),
          _eyeWhite,
        );
        canvas.drawLine(
          Offset(w / 2, h * 0.63),
          Offset(w / 2, h * 0.67),
          _eyeBlack..strokeWidth = 1,
        );
        break;
        
      case PreyVisualEmotion.angry:
        // Normal angry eyes
        canvas.drawCircle(Offset(w * 0.3, eyeY), eyeSize, _eyeWhite);
        canvas.drawCircle(Offset(w * 0.7, eyeY), eyeSize, _eyeWhite);
        canvas.drawCircle(Offset(w * 0.3, eyeY), eyeSize - 1, _eyeBlack);
        canvas.drawCircle(Offset(w * 0.7, eyeY), eyeSize - 1, _eyeBlack);
        // Angry eyebrows
        canvas.drawLine(
          Offset(w * 0.2, eyeY - 6),
          Offset(w * 0.4, eyeY - 3),
          Paint()..color = Colors.black..strokeWidth = 2,
        );
        canvas.drawLine(
          Offset(w * 0.8, eyeY - 6),
          Offset(w * 0.6, eyeY - 3),
          Paint()..color = Colors.black..strokeWidth = 2,
        );
        // Frown
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w / 2, h * 0.7), width: 12, height: 8),
          0.2, 2.7, false,
          Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke,
        );
        break;
    }
  }
}
