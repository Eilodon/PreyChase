import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CrocodilePlayer extends PositionComponent {
  // Stats
  double fatLevel = 0.0; // 0.0 to 10.0
  double _baseWidth = 32.0;
  
  // Physics
  Vector2 velocity = Vector2.zero();
  
  // Getters for dynamic stats
  double get maxSpeed => 200.0 * (1.0 - (fatLevel * 0.05)); // Slower when fat
  Vector2 get hitboxSize => Vector2(_baseWidth + (fatLevel * 4), 32 + (fatLevel * 2));
  
  // Animation State
  double _time = 0.0;
  
  // Paint objects (Cached)
  final Paint _bodyPaint = Paint()..color = const Color(0xFF4A7C59); // Swamp Green
  final Paint _bellyPaint = Paint()..color = const Color(0xFFD4E09B); // Cream
  final Paint _eyeWhite = Paint()..color = Colors.white;
  final Paint _eyePupil = Paint()..color = Colors.black;

  CrocodilePlayer({required Vector2 position}) : super(position: position, size: Vector2(32, 32), anchor: Anchor.center);

  void setVelocity(Vector2 input) {
     if (input.isZero()) {
        // Friction
        velocity.scale(0.9);
        if (velocity.length < 10) velocity.setZero();
     } else {
        // Acceleration
        velocity.lerp(input.normalized() * maxSpeed, 0.1);
     }
  }

  void grow(double amount) {
     fatLevel = (fatLevel + amount).clamp(0.0, 10.0);
     // Visual Pop?
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    
    // Physics Integration
    position.add(velocity * dt);
    
    // Update Size for camera/collision
    size = hitboxSize;
  }

  @override
  void render(Canvas canvas) {
    // Procedural Rendering of "Pixel Art" Crocodile
    // Base size 32x32.
    // Body is a rounded rect.
    
    final w = size.x;
    final h = size.y;
    
    // Breathing animation (Squash/Stretch simulation)
    double breath = sin(_time * 5) * (0.05 + fatLevel * 0.01);
    
    canvas.save();
    canvas.translate(w/2, h/2);
    canvas.scale(1.0 + breath, 1.0 - breath);
    canvas.translate(-w/2, -h/2);
    
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), 
      _bodyPaint
    );
    
    // Belly (Oval) - Grows with fatLevel
    canvas.drawOval(
      Rect.fromLTWH(4, 8, w - 8, h - 8), 
      _bellyPaint
    );
    
    // Eyes (Pop out)
    // Left
    canvas.drawCircle(Offset(6, 6), 4, _eyeWhite);
    canvas.drawCircle(Offset(6, 6), 2, _eyePupil);
    // Right
    canvas.drawCircle(Offset(w - 6, 6), 4, _eyeWhite);
    canvas.drawCircle(Offset(w - 6, 6), 2, _eyePupil);
    
    // Mouth
    canvas.drawRect(Rect.fromLTWH(8, h - 10, w - 16, 2), _eyePupil..color = Colors.black12);
    
    canvas.restore();
  }
  
  // Removed old setVelocity to replace above
}
