import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../kernel/models/prey.dart';
import '../config/level_config.dart';
import 'crocodile_player.dart';
import 'prey_component.dart';
import 'obstacle_component.dart';
import 'spawn_manager.dart';

/// Game state enum
enum CrocGameStatus { playing, gameOver, levelComplete, paused }

class FuryWorld extends World {
  late CrocodilePlayer player;
  late SpawnManager spawnManager;
  final Random _rnd = Random();
  
  // Game State
  CrocGameStatus status = CrocGameStatus.playing;
  int currentLevel = 1;
  int currentWave = 1;
  int totalPreysEaten = 0;
  
  // Callbacks
  final void Function(int score)? onGameOver;
  final void Function(int wave)? onWaveComplete;
  final void Function(int level, int stars)? onLevelComplete;
  final void Function(int level, String name)? onLevelStart;
  final void Function()? onBossSpawn;
  final void Function()? onTimeUp;
  
  FuryWorld({
    this.onGameOver, 
    this.onWaveComplete,
    this.onLevelComplete,
    this.onLevelStart,
    this.onBossSpawn,
    this.onTimeUp,
  });

  @override
  Future<void> onLoad() async {
    player = CrocodilePlayer(position: Vector2(0, 0));
    player.onEvent = _handlePlayerEvent;
    add(player);
    
    spawnManager = SpawnManager();
    add(spawnManager);
  }
  
  void _handlePlayerEvent(CrocGameEvent event) {
    if (event == CrocGameEvent.died) {
      _triggerGameOver();
    }
  }
  
  void _triggerGameOver() {
    if (status != CrocGameStatus.playing) return;
    status = CrocGameStatus.gameOver;
    onGameOver?.call(player.score);
  }
  
  @override
  void update(double dt) {
    if (status != CrocGameStatus.playing) return;
    super.update(dt);
    _checkCollisions();
  }
  
  void _checkCollisions() {
    // === 1. PREY COLLISION ===
    final preys = children.whereType<PreyComponent>().toList();
    for (final prey in preys) {
      final dist = prey.position.distanceTo(player.position);
      final collisionDist = (player.size.x / 2 + prey.size.x / 2 - 5);
      
      if (dist < collisionDist) {
        if (player.isFuryActive) {
          _eatPrey(prey);
        } else {
          _damageFromPrey(prey);
        }
      }
    }
    
    // === 2. SOLID OBSTACLE COLLISION ===
    final obstacles = children.whereType<ObstacleComponent>();
    for (final obs in obstacles) {
      if (!obs.isSolid) continue; // Zones handled in obstacle update
      
      final dist = obs.position.distanceTo(player.position);
      final collisionDist = (player.size.x / 2 + obs.size.x / 2);
      
      if (dist < collisionDist) {
        // Bounce
        Vector2 normal = (player.position - obs.position).normalized();
        if (normal.isZero()) normal = Vector2(1, 0);
        
        player.velocity = normal * 300;
        
        // Damage from spikes
        player.takeDamage(obs.collisionDamage);
      }
    }
    
    // === 3. BOUNDARY CHECK ===
    const double arenaSize = 900;
    if (player.position.x.abs() > arenaSize || player.position.y.abs() > arenaSize) {
      player.position.clamp(Vector2.all(-arenaSize), Vector2.all(arenaSize));
      player.velocity = -player.velocity * 0.5;
      player.takeDamage(10.0);
    }
  }
  
  void _eatPrey(PreyComponent prey) {
    final scoreValue = _getPreyScoreValue(prey.type);
    
    player.addScore(scoreValue);
    player.grow(0.3);
    player.addFury(0.1); // Small fury bonus for eating prey
    
    totalPreysEaten++;
    spawnManager.onPreyEaten();
    
    prey.onEaten();
    prey.removeFromParent();
  }
  
  void _damageFromPrey(PreyComponent prey) {
    final damage = _getPreyDamage(prey.type);
    player.takeDamage(damage);
    
    // Prey bounces away
    final knockback = (prey.position - player.position).normalized() * 200;
    prey.velocity = knockback;
    
    player.furyMeter = 0.0;
  }
  
  int _getPreyScoreValue(PreyType type) {
    switch (type) {
      case PreyType.boss: return 500;
      case PreyType.goldenCake: return 100;
      case PreyType.zombieBurger: return 30;
      case PreyType.ninjaSushi: return 20;
      case PreyType.ghostPizza: return 25;
      default: return 10;
    }
  }
  
  double _getPreyDamage(PreyType type) {
    switch (type) {
      case PreyType.boss: return 30.0;
      case PreyType.zombieBurger: return 15.0;
      case PreyType.ninjaSushi: return 10.0;
      default: return 5.0;
    }
  }
  
  /// Called when player eats food (passive pickups)
  void onFoodEaten() {
    player.addScore(10);
    player.addFury(0.2);
    player.grow(0.2);
  }
  
  /// Load a specific level
  void loadLevel(int level) {
    currentLevel = level;
    status = CrocGameStatus.playing;
    player.reset();
    spawnManager.loadLevel(level);
  }
  
  /// Restart current level
  void restartLevel() {
    loadLevel(currentLevel);
  }
  
  /// Restart entire game from level 1
  void restartGame() {
    totalPreysEaten = 0;
    loadLevel(1);
  }
  
  /// Continue to next level
  void nextLevel() {
    loadLevel(currentLevel + 1);
  }
}
