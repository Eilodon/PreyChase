import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../kernel/models/prey.dart'; // Reuse Enum
import '../../view/style/game_styles.dart'; // Reuse Paints if possible, or new ones
import 'crocodile_player.dart';

class PreyComponent extends PositionComponent with HasGameRef {
  final PreyType type;
  final CrocodilePlayer player;
  
  // Physics
  Vector2 velocity = Vector2.zero();
  double maxSpeed = 100.0;
  
  // AI State
  final Random _rnd = Random();
  Vector2 _wanderTarget = Vector2.zero();
  double _wanderTimer = 0.0;
  
  // Visuals
  final Paint _paint = Paint();

  PreyComponent({
    required this.type,
    required this.player,
    required Vector2 position,
  }) : super(position: position, size: Vector2(24, 24), anchor: Anchor.center) {
    _initStats();
  }
  
  void _initStats() {
    switch (type) {
      case PreyType.ninjaSushi:
        maxSpeed = 150.0;
        _paint.color = const Color(0xFFE91E63);
        break;
      case PreyType.zombieBurger:
        maxSpeed = 50.0;
        _paint.color = const Color(0xFF4CAF50);
        break;
      case PreyType.ghostPizza:
        maxSpeed = 80.0;
        _paint.color = const Color(0xFF9C27B0).withOpacity(0.7);
        break;
      case PreyType.boss:
        maxSpeed = 40.0;
        size = Vector2(48, 48);
        _paint.color = const Color(0xFFFF0000);
        break;
      default:
        maxSpeed = 100.0;
        _paint.color = const Color(0xFFFF5722);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Steering Forces
    Vector2 force = Vector2.zero();
    
    // 1. Separation (Avoid crowding)
    force.add(_separationForce() * 2.0);
    
    // 2. Behavior (Chase/Flee/Wander)
    double dist = position.distanceTo(player.position);
    
    if (type == PreyType.goldenCake) {
       if (dist < 250) {
          force.add(_flee(player.position) * 3.0); // Run away fast
       } else {
          force.add(_wander(dt));
       }
    } else if (type == PreyType.angryApple || type == PreyType.zombieBurger) {
       // Passive food or Slow zombies
       if (dist < 100) {
          force.add(_flee(player.position) * 1.5); // Scared slightly
       } else {
          force.add(_wander(dt));
       }
    } else if (type == PreyType.ninjaSushi) {
       // Aggressive
       if (dist < 300) {
          force.add(_seek(player.position) * 1.0);
       } else {
          force.add(_wander(dt));
       }
    } else {
       force.add(_wander(dt));
    }
    
    // Apply Force
    velocity.add(force * dt);
    
    // Cap Speed
    if (velocity.length > maxSpeed) {
       velocity = velocity.normalized() * maxSpeed;
    }
    
    position.add(velocity * dt);
    
    // Rotate to face velocity
    if (!velocity.isZero()) {
      angle = atan2(velocity.y, velocity.x);
    }
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
           (_rnd.nextDouble()*2-1)*300,
           (_rnd.nextDouble()*2-1)*300
        );
     }
     // Seek invisible wander target relative to self
     return _seek(position + _wanderTarget);
  }
  
  Vector2 _separationForce() {
     Vector2 steering = Vector2.zero();
     int count = 0;
     // Optimization: Don't check all parents children every frame if too many?
     // For < 50 items it's fine.
     final neighbors = parent?.children.whereType<PreyComponent>() ?? [];
     
     for (final other in neighbors) {
        if (other == this) continue;
        double d = position.distanceTo(other.position);
        if (d > 0 && d < 40) { // Separation radius
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
    // Simple shape for now
    if (type == PreyType.boss) {
       canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, _paint);
    } else {
       canvas.drawRect(size.toRect(), _paint);
    }
    
    // Eyes
    canvas.drawCircle(Offset(size.x*0.7, size.y*0.3), 3, Paint()..color=Colors.white);
  }
}
