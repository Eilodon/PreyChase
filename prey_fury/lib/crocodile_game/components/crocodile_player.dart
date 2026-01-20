import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Game event types for visual feedback
enum CrocGameEvent {
  ateFood,
  atePrey,
  damaged,
  furyActivated,
  furyEnded,
  died,
}

class CrocodilePlayer extends PositionComponent with KeyboardHandler {
  // === CORE STATS ===
  double fatLevel = 0.0; // 0.0 to 10.0
  double health = 100.0; // 0-100
  double maxHealth = 100.0;
  
  // === FURY SYSTEM ===
  double furyMeter = 0.0; // 0.0 to 1.0
  bool isFuryActive = false;
  double furyDuration = 0.0; // Seconds remaining
  static const double furyMaxDuration = 5.0;
  
  // === SCORE ===
  int score = 0;
  int comboMultiplier = 1;
  double comboTimer = 0.0;
  static const double comboTimeout = 2.0; // Seconds to maintain combo
  
  // === PHYSICS ===
  double _baseWidth = 32.0;
  Vector2 velocity = Vector2.zero();
  Vector2 inputDirection = Vector2.zero();
  
  // Event callback for World to handle
  void Function(CrocGameEvent event)? onEvent;
  
  // === SPEED MODIFIER (from zones) ===
  double _speedModifier = 1.0;
  
  // Getters
  double get maxSpeed => 200.0 * (1.0 - (fatLevel * 0.03)) * (isFuryActive ? 1.5 : 1.0) * _speedModifier;
  Vector2 get hitboxSize => Vector2(_baseWidth + (fatLevel * 4), 32 + (fatLevel * 2));
  bool get canActivateFury => furyMeter >= 1.0 && !isFuryActive;
  bool get isDead => health <= 0;
  
  // Animation
  double _time = 0.0;
  double _damageFlash = 0.0;
  
  // Paints
  final Paint _bodyPaint = Paint()..color = const Color(0xFF4A7C59);
  final Paint _furyBodyPaint = Paint()..color = const Color(0xFFFF6B00);
  final Paint _bellyPaint = Paint()..color = const Color(0xFFD4E09B);
  final Paint _eyeWhite = Paint()..color = Colors.white;
  final Paint _eyePupil = Paint()..color = Colors.black;
  final Paint _damagePaint = Paint()..color = Colors.red.withOpacity(0.5);

  CrocodilePlayer({required Vector2 position}) 
    : super(position: position, size: Vector2(32, 32), anchor: Anchor.center);

  // === ACTIONS ===
  
  void addScore(int points) {
    score += points * comboMultiplier;
    comboMultiplier = min(5, comboMultiplier + 1);
    comboTimer = comboTimeout;
  }
  
  void addFury(double amount) {
    if (isFuryActive) return;
    furyMeter = min(1.0, furyMeter + amount);
  }
  
  void activateFury() {
    if (!canActivateFury) return;
    isFuryActive = true;
    furyDuration = furyMaxDuration;
    furyMeter = 0.0;
    onEvent?.call(CrocGameEvent.furyActivated);
  }
  
  void takeDamage(double amount) {
    if (isFuryActive) return; // Invincible during fury
    
    health = max(0, health - amount);
    _damageFlash = 0.3;
    comboMultiplier = 1;
    comboTimer = 0;
    
    // Shrink on damage
    fatLevel = max(0, fatLevel - 0.5);
    
    onEvent?.call(CrocGameEvent.damaged);
    
    if (health <= 0) {
      onEvent?.call(CrocGameEvent.died);
    }
  }
  
  void grow(double amount) {
    fatLevel = (fatLevel + amount).clamp(0.0, 10.0);
  }
  
  void reset() {
    health = maxHealth;
    fatLevel = 0.0;
    furyMeter = 0.0;
    isFuryActive = false;
    furyDuration = 0.0;
    score = 0;
    comboMultiplier = 1;
    comboTimer = 0.0;
    velocity = Vector2.zero();
    position = Vector2.zero();
    _speedModifier = 1.0;
  }
  
  /// Heal the player (from healing pools)
  void heal(double amount) {
    health = min(maxHealth, health + amount);
  }
  
  /// Set speed modifier (from zones like mud/speedBoost)
  void setSpeedModifier(double multiplier) {
    _speedModifier = multiplier;
  }
  
  /// Clear speed modifier (when exiting zones)
  void clearSpeedModifier() {
    _speedModifier = 1.0;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Build direction from WASD/Arrows
    inputDirection = Vector2.zero();
    
    if (keysPressed.contains(LogicalKeyboardKey.keyW) || 
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) || 
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || 
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || 
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Fury activation
    if (event is KeyDownEvent && 
        (event.logicalKey == LogicalKeyboardKey.space ||
         event.logicalKey == LogicalKeyboardKey.keyF)) {
      activateFury();
    }
    
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    
    // === FURY UPDATE ===
    if (isFuryActive) {
      furyDuration -= dt;
      if (furyDuration <= 0) {
        isFuryActive = false;
        furyDuration = 0;
        onEvent?.call(CrocGameEvent.furyEnded);
      }
    }
    
    // === COMBO DECAY ===
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        comboMultiplier = 1;
      }
    }
    
    // === DAMAGE FLASH ===
    if (_damageFlash > 0) {
      _damageFlash -= dt;
    }
    
    // === PHYSICS ===
    if (inputDirection.isZero()) {
      velocity.scale(0.9);
      if (velocity.length < 10) velocity.setZero();
    } else {
      velocity.lerp(inputDirection.normalized() * maxSpeed, 0.1);
    }
    
    position.add(velocity * dt);
    size = hitboxSize;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    
    // Breathing animation
    double breath = sin(_time * 5) * (0.05 + fatLevel * 0.01);
    
    canvas.save();
    canvas.translate(w/2, h/2);
    canvas.scale(1.0 + breath, 1.0 - breath);
    canvas.translate(-w/2, -h/2);
    
    // Body (fury = orange, normal = green)
    final bodyPaint = isFuryActive ? _furyBodyPaint : _bodyPaint;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), 
      bodyPaint
    );
    
    // Belly
    canvas.drawOval(Rect.fromLTWH(4, 8, w - 8, h - 8), _bellyPaint);
    
    // Eyes
    canvas.drawCircle(Offset(6, 6), 4, _eyeWhite);
    canvas.drawCircle(Offset(6, 6), 2, _eyePupil);
    canvas.drawCircle(Offset(w - 6, 6), 4, _eyeWhite);
    canvas.drawCircle(Offset(w - 6, 6), 2, _eyePupil);
    
    // Mouth
    canvas.drawRect(Rect.fromLTWH(8, h - 10, w - 16, 2), _eyePupil);
    
    // Fury glow effect
    if (isFuryActive) {
      final glowPaint = Paint()
        ..color = Colors.orange.withOpacity(0.3 + sin(_time * 10) * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(w/2, h/2), w * 0.7, glowPaint);
    }
    
    canvas.restore();
    
    // Damage flash overlay
    if (_damageFlash > 0) {
      canvas.drawRect(size.toRect(), _damagePaint);
    }
  }
}
