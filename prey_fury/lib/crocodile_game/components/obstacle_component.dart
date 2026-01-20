import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'crocodile_player.dart';
import 'fury_world.dart';

/// Obstacle types with distinct effects
enum ObstacleType {
  rock,        // Bounce (no damage)
  spike,       // High damage + knockback
  mud,         // Slow zone (50% speed)
  speedBoost,  // Speed zone (150% speed)
  whirlpool,   // Pull toward center
  healingPool, // +5 HP/sec while inside
  portal,      // Teleport to paired portal
}

/// Effect applied to player when inside a zone
class ZoneEffect {
  final double speedMultiplier;
  final double healthPerSecond;
  final double pullForce;
  final Vector2? teleportTo;
  
  const ZoneEffect({
    this.speedMultiplier = 1.0,
    this.healthPerSecond = 0.0,
    this.pullForce = 0.0,
    this.teleportTo,
  });
}

class ObstacleComponent extends PositionComponent with HasWorldReference<FuryWorld> {
  final ObstacleType type;
  ObstacleComponent? pairedPortal; // For portal pairs
  
  // Visual state
  double _animTime = 0.0;
  final Paint _basePaint = Paint();
  final Paint _glowPaint = Paint();
  
  // Track if player is inside (for zones)
  bool _playerInside = false;
  
  ObstacleComponent({
    required this.type,
    required Vector2 position,
    this.pairedPortal,
  }) : super(position: position, anchor: Anchor.center) {
    _initVisuals();
  }
  
  void _initVisuals() {
    switch (type) {
      case ObstacleType.rock:
        _basePaint.color = Colors.grey.shade600;
        size = Vector2(45, 45);
        break;
        
      case ObstacleType.spike:
        _basePaint.color = const Color(0xFFD32F2F);
        size = Vector2(35, 35);
        break;
        
      case ObstacleType.mud:
        _basePaint.color = const Color(0xFF5D4037).withOpacity(0.7);
        size = Vector2(80, 80);
        break;
        
      case ObstacleType.speedBoost:
        _basePaint.color = const Color(0xFF00BCD4).withOpacity(0.6);
        size = Vector2(70, 70);
        break;
        
      case ObstacleType.whirlpool:
        _basePaint.color = const Color(0xFF1565C0).withOpacity(0.5);
        size = Vector2(90, 90);
        break;
        
      case ObstacleType.healingPool:
        _basePaint.color = const Color(0xFF4CAF50).withOpacity(0.5);
        size = Vector2(70, 70);
        break;
        
      case ObstacleType.portal:
        _basePaint.color = const Color(0xFF7B1FA2).withOpacity(0.8);
        size = Vector2(50, 50);
        break;
    }
  }
  
  /// Check if this is a solid obstacle (blocks movement)
  bool get isSolid => type == ObstacleType.rock || type == ObstacleType.spike;
  
  /// Check if this is a zone (player can be inside)
  bool get isZone => !isSolid;
  
  /// Get the effect for when player is inside
  ZoneEffect get zoneEffect {
    switch (type) {
      case ObstacleType.mud:
        return const ZoneEffect(speedMultiplier: 0.5);
      case ObstacleType.speedBoost:
        return const ZoneEffect(speedMultiplier: 1.5);
      case ObstacleType.healingPool:
        return const ZoneEffect(healthPerSecond: 5.0);
      case ObstacleType.whirlpool:
        return const ZoneEffect(pullForce: 150.0);
      case ObstacleType.portal:
        if (pairedPortal != null) {
          return ZoneEffect(teleportTo: pairedPortal!.position);
        }
        return const ZoneEffect();
      default:
        return const ZoneEffect();
    }
  }
  
  /// Get damage dealt on collision (for solid obstacles)
  double get collisionDamage {
    switch (type) {
      case ObstacleType.spike:
        return 15.0;
      case ObstacleType.rock:
        return 0.0; // Just bounce
      default:
        return 0.0;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
    
    // Check player proximity for zones
    if (isZone && world.player.isMounted) {
      final dist = position.distanceTo(world.player.position);
      final inZone = dist < (size.x / 2 + world.player.size.x / 4);
      
      if (inZone && !_playerInside) {
        _onPlayerEnter();
      } else if (!inZone && _playerInside) {
        _onPlayerExit();
      }
      
      if (inZone) {
        _applyZoneEffect(dt);
      }
    }
  }
  
  void _onPlayerEnter() {
    _playerInside = true;
    
    // Portal teleport
    if (type == ObstacleType.portal && pairedPortal != null) {
      world.player.position = pairedPortal!.position.clone();
      world.player.velocity = Vector2.zero();
      pairedPortal!._playerInside = true; // Prevent instant re-teleport
    }
  }
  
  void _onPlayerExit() {
    _playerInside = false;
    
    // Reset speed modifier when leaving zones
    if (type == ObstacleType.mud || type == ObstacleType.speedBoost) {
      world.player.clearSpeedModifier();
    }
  }
  
  void _applyZoneEffect(double dt) {
    final player = world.player;
    final effect = zoneEffect;
    
    // Speed modifier
    if (effect.speedMultiplier != 1.0) {
      player.setSpeedModifier(effect.speedMultiplier);
    }
    
    // Healing
    if (effect.healthPerSecond > 0) {
      player.heal(effect.healthPerSecond * dt);
    }
    
    // Pull force (whirlpool)
    if (effect.pullForce > 0) {
      final dir = (position - player.position).normalized();
      player.velocity.add(dir * effect.pullForce * dt);
    }
  }
  
  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    
    switch (type) {
      case ObstacleType.rock:
        _drawRock(canvas, center);
        break;
      case ObstacleType.spike:
        _drawSpike(canvas, center);
        break;
      case ObstacleType.mud:
        _drawMud(canvas, center);
        break;
      case ObstacleType.speedBoost:
        _drawSpeedBoost(canvas, center);
        break;
      case ObstacleType.whirlpool:
        _drawWhirlpool(canvas, center);
        break;
      case ObstacleType.healingPool:
        _drawHealingPool(canvas, center);
        break;
      case ObstacleType.portal:
        _drawPortal(canvas, center);
        break;
    }
  }
  
  void _drawRock(Canvas canvas, Offset center) {
    // Irregular rock shape
    final path = Path();
    path.moveTo(center.dx - size.x * 0.4, center.dy + size.y * 0.2);
    path.lineTo(center.dx - size.x * 0.3, center.dy - size.y * 0.35);
    path.lineTo(center.dx + size.x * 0.1, center.dy - size.y * 0.4);
    path.lineTo(center.dx + size.x * 0.4, center.dy - size.y * 0.1);
    path.lineTo(center.dx + size.x * 0.35, center.dy + size.y * 0.35);
    path.lineTo(center.dx - size.x * 0.1, center.dy + size.y * 0.4);
    path.close();
    
    canvas.drawPath(path, _basePaint);
    
    // Highlight
    canvas.drawCircle(
      Offset(center.dx - 5, center.dy - 8),
      5,
      Paint()..color = Colors.grey.shade400,
    );
  }
  
  void _drawSpike(Canvas canvas, Offset center) {
    // Multiple triangle spikes
    final spikePaint = Paint()..color = const Color(0xFFB71C1C);
    
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final tipX = center.dx + cos(angle) * size.x * 0.45;
      final tipY = center.dy + sin(angle) * size.y * 0.45;
      
      final path = Path();
      path.moveTo(tipX, tipY);
      path.lineTo(
        center.dx + cos(angle + 0.4) * size.x * 0.2,
        center.dy + sin(angle + 0.4) * size.y * 0.2,
      );
      path.lineTo(
        center.dx + cos(angle - 0.4) * size.x * 0.2,
        center.dy + sin(angle - 0.4) * size.y * 0.2,
      );
      path.close();
      canvas.drawPath(path, spikePaint);
    }
    
    // Center
    canvas.drawCircle(center, size.x * 0.2, _basePaint);
  }
  
  void _drawMud(Canvas canvas, Offset center) {
    // Irregular mud puddle
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.x, height: size.y * 0.7),
      _basePaint,
    );
    
    // Bubbles
    for (int i = 0; i < 3; i++) {
      final bubbleOffset = Offset(
        center.dx + cos(_animTime * 2 + i) * size.x * 0.2,
        center.dy + sin(_animTime * 2 + i) * size.y * 0.2,
      );
      canvas.drawCircle(
        bubbleOffset,
        3 + sin(_animTime * 3 + i) * 2,
        Paint()..color = Colors.brown.shade300,
      );
    }
  }
  
  void _drawSpeedBoost(Canvas canvas, Offset center) {
    // Glowing pad with arrows
    canvas.drawCircle(center, size.x / 2, _basePaint);
    
    // Chevron arrows
    final arrowPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 3; i++) {
      final yOffset = (i - 1) * 15.0 + sin(_animTime * 5) * 5;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - 15, center.dy + yOffset + 5)
          ..lineTo(center.dx, center.dy + yOffset - 5)
          ..lineTo(center.dx + 15, center.dy + yOffset + 5),
        arrowPaint,
      );
    }
  }
  
  void _drawWhirlpool(Canvas canvas, Offset center) {
    // Rotating spiral
    canvas.drawCircle(center, size.x / 2, _basePaint);
    
    final spiralPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final spiral = Path();
    for (double t = 0; t < 3 * pi; t += 0.1) {
      final r = t * 5 + 10;
      final angle = t + _animTime * 3;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (t == 0) {
        spiral.moveTo(x, y);
      } else {
        spiral.lineTo(x, y);
      }
    }
    canvas.drawPath(spiral, spiralPaint);
    
    // Center
    canvas.drawCircle(center, 8, Paint()..color = Colors.white.withOpacity(0.5));
  }
  
  void _drawHealingPool(Canvas canvas, Offset center) {
    // Green glowing pool
    final glowSize = size.x / 2 + sin(_animTime * 3) * 5;
    canvas.drawCircle(
      center,
      glowSize,
      Paint()..color = Colors.green.withOpacity(0.3),
    );
    canvas.drawCircle(center, size.x / 2 - 10, _basePaint);
    
    // Plus sign
    final plusPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(center.dx - 12, center.dy),
      Offset(center.dx + 12, center.dy),
      plusPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy + 12),
      plusPaint,
    );
  }
  
  void _drawPortal(Canvas canvas, Offset center) {
    // Spinning portal ring
    final rotation = _animTime * 2;
    
    // Outer glow
    canvas.drawCircle(
      center,
      size.x / 2 + sin(_animTime * 5) * 3,
      Paint()..color = Colors.purple.withOpacity(0.3),
    );
    
    // Ring
    canvas.drawCircle(
      center,
      size.x / 2,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    
    // Inner swirl
    for (int i = 0; i < 3; i++) {
      final angle = rotation + i * 2 * pi / 3;
      canvas.drawCircle(
        Offset(
          center.dx + cos(angle) * size.x * 0.25,
          center.dy + sin(angle) * size.y * 0.25,
        ),
        4,
        Paint()..color = Colors.purpleAccent,
      );
    }
    
    // Center void
    canvas.drawCircle(center, size.x * 0.15, Paint()..color = Colors.black);
  }
}
