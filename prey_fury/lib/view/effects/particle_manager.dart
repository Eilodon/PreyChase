import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class ParticleManager extends Component {
  final Random _random = Random();

  void spawnConfetti(Vector2 position, {Color color = Colors.white, int count = 10}) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 100 + 50;
      
      add(
        ParticleSystemComponent(
          particle: AcceleratedParticle(
            lifespan: 0.5,
            position: position,
            speed: Vector2(cos(angle), sin(angle)) * speed,
            child: CircleParticle(
              radius: 2,
              paint: Paint()..color = color,
            ),
          ),
        ),
      );
    }
  }

  void spawnExplosion(Vector2 position, {Color color = Colors.orange, int count = 30}) {
    // Ring explosion
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: count,
          lifespan: 0.8,
          generator: (i) {
             final angle = (i / count) * 2 * pi;
             return AcceleratedParticle(
                position: position,
                speed: Vector2(cos(angle), sin(angle)) * 200,
                child: ComputedParticle(
                   renderer: (canvas, particle) {
                      final paint = Paint()..color = color.withOpacity(1 - particle.progress);
                      canvas.drawCircle(Offset.zero, 4 * (1 - particle.progress), paint);
                   }
                )
             );
          }
        )
      )
    );
  }
}
