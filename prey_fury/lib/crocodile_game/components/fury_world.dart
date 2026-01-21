import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../kernel/models/prey.dart';
import '../config/level_config.dart';
import 'crocodile_player.dart';
import 'prey_component.dart';
import 'obstacle_component.dart';
import 'spawn_manager.dart';
import 'spatial_grid.dart';
import 'power_up_manager.dart';
import 'juice_manager.dart';
import '../audio/audio_manager.dart';

/// Game state enum
enum CrocGameStatus { playing, gameOver, levelComplete, paused }

class FuryWorld extends World {
  late CrocodilePlayer player;
  late SpawnManager spawnManager;
  late PowerUpManager powerUpManager;
  late JuiceManager juiceManager;
  late AudioManager audioManager;
  final Random _rnd = Random();

  // === PERFORMANCE: Spatial grid for prey AI optimization ===
  final SpatialGrid<PreyComponent> preyGrid = SpatialGrid(cellSize: 80);

  // === LEVEL-UP SYSTEM ===
  double _timeSinceLastLevelUp = 0.0;
  int _killsSinceLastLevelUp = 0;
  static const double levelUpTimeInterval = 30.0; // Every 30 seconds
  static const int levelUpKillInterval = 10; // Every 10 kills

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

    // Initialize power-up system
    powerUpManager = PowerUpManager(player: player);
    add(powerUpManager);

    // Initialize juice effects system
    juiceManager = JuiceManager();
    add(juiceManager);

    // Initialize audio system
    audioManager = AudioManager();
    await audioManager.initialize();
    audioManager.startMusic(); // Start background music
  }
  
  void _handlePlayerEvent(CrocGameEvent event) {
    switch (event) {
      case CrocGameEvent.died:
        _triggerGameOver();
        audioManager.playDeath(); // Death sound
        audioManager.stopMusic();
        break;
      case CrocGameEvent.furyActivated:
        juiceManager.freezeFuryActivation(); // 100ms freeze
        audioManager.playFuryActivate(); // Epic sound!
        audioManager.setMusicIntensity(MusicIntensity.fury); // Switch to fury music
        break;
      case CrocGameEvent.furyEnded:
        audioManager.playFuryEnd();
        audioManager.setMusicIntensity(MusicIntensity.calm); // Back to calm music
        break;
      case CrocGameEvent.damaged:
        juiceManager.hitStopDamage(); // Hit stop effect
        final damagePercent = 1.0 - (player.health / player.maxHealth);
        audioManager.playTakeDamage(damagePercent: damagePercent);
        break;
      case CrocGameEvent.atePrey:
        juiceManager.freezePreyEat(); // 50ms freeze
        audioManager.playEatPrey(comboLevel: player.comboMultiplier);
        if (player.comboMultiplier > 1) {
          audioManager.playComboIncrease(player.comboMultiplier);
        }
        break;
      default:
        break;
    }
  }
  
  void _triggerGameOver() {
    if (status != CrocGameStatus.playing) return;
    status = CrocGameStatus.gameOver;
    onGameOver?.call(player.score);
  }

  void _triggerLevelUp() {
    if (status != CrocGameStatus.playing) return;
    if (powerUpManager.isSelectingPowerUp) return; // Already selecting

    // Audio feedback
    audioManager.playLevelUp();
    audioManager.playPowerUpAppear();

    // Pause game
    status = CrocGameStatus.paused;

    // Offer power-up selection
    powerUpManager.offerPowerUpSelection();
  }

  void resumeFromPowerUpSelection() {
    status = CrocGameStatus.playing;
  }
  
  @override
  void update(double dt) {
    if (status != CrocGameStatus.playing) return;

    // === JUICE: Apply time scale (freeze frame / hit stop) ===
    final scaledDt = dt * juiceManager.timeScale;

    // === PERFORMANCE: Rebuild spatial grid before AI updates ===
    final allPreys = children.whereType<PreyComponent>().toList();
    preyGrid.rebuild(allPreys);

    // Update with scaled delta time for game objects
    for (final component in children) {
      if (component is! JuiceManager) { // Don't scale juice manager itself
        component.update(scaledDt);
      }
    }

    _checkCollisions();

    // === LEVEL-UP TRIGGERS (use real dt, not scaled) ===
    _timeSinceLastLevelUp += dt;

    // Time-based level-up (every 30 seconds)
    if (_timeSinceLastLevelUp >= levelUpTimeInterval) {
      _triggerLevelUp();
      _timeSinceLastLevelUp = 0.0;
    }

    // Kill-based level-up (every 10 kills)
    // Note: _killsSinceLastLevelUp is incremented in _eatPrey()

    // Reset spatial grid stats for next frame
    preyGrid.resetStats();
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
    _killsSinceLastLevelUp++;
    spawnManager.onPreyEaten();

    // Trigger juice effect
    player.onEvent?.call(CrocGameEvent.atePrey);

    // Check for kill-based level-up
    if (_killsSinceLastLevelUp >= levelUpKillInterval) {
      _triggerLevelUp();
      _killsSinceLastLevelUp = 0;
    }

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
