/// Van Co World - Main game world for Vạn Cổ Chi Vương
///
/// Manages:
/// - All critter entities (player + AI)
/// - Battle Royale mechanics (shrinking zone)
/// - Lightning hazards (Thiên Kiếp)
/// - Food pellets and power-ups
/// - Collision detection

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../kernel/models/critter.dart';
import '../../kernel/models/ngu_hanh_faction.dart';
import '../../kernel/models/van_co_mutation.dart';
import '../../kernel/systems/battle_royale_manager.dart';
import '../../kernel/systems/lightning_system.dart';
import '../../kernel/systems/size_manager.dart';
import 'critter_component.dart';

/// Game status enum
enum VanCoGameStatus {
  waiting,    // Waiting to start
  countdown,  // 3-2-1 countdown
  playing,    // Game in progress
  paused,     // Paused
  gameOver,   // Game ended
}

/// Game event types
enum VanCoGameEvent {
  playerAte,
  playerDamaged,
  playerTierUp,
  playerDied,
  aiDied,
  phaseChanged,
  zoneShrinking,
  lightningWarning,
  lightningStrike,
  gameWon,
  gameLost,
}

/// Van Co World - Main Flame World component
class VanCoWorld extends World with KeyboardHandler, HasCollisionDetection {
  // === CONFIGURATION ===
  final NguHanhFaction playerFaction;
  final int aiCount;
  final int difficulty; // 1-10

  // === GAME STATE ===
  VanCoGameStatus status = VanCoGameStatus.waiting;
  final BattleRoyaleManager _brManager = BattleRoyaleManager();
  final LightningSystem _lightningSystem = LightningSystem();
  final Random _random = Random();

  // === ENTITIES ===
  late CritterComponent playerCritter;
  final List<CritterComponent> aiCritters = [];
  final List<FoodPelletComponent> foodPellets = [];

  // === INPUT ===
  Vector2 _mousePosition = Vector2.zero();
  final Set<LogicalKeyboardKey> _keysPressed = {};

  // === TIMERS ===
  double _lightningTimer = 0;
  double _foodSpawnTimer = 0;
  double _aiUpdateTimer = 0;

  // === CALLBACKS ===
  void Function(VanCoGameEvent event, [dynamic data])? onGameEvent;
  void Function(int placement, int kills, int timeSurvived)? onGameOver;

  // === CONSTANTS ===
  static const double foodSpawnInterval = 2.0;
  static const double aiUpdateInterval = 0.1;
  static const int maxFoodPellets = 50;

  VanCoWorld({
    required this.playerFaction,
    this.aiCount = 19,
    this.difficulty = 5,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize managers
    _brManager.initialize(totalPlayers: aiCount + 1);
    _setupManagerCallbacks();

    // Reset factory IDs
    CritterFactory.resetIds();
  }

  void _setupManagerCallbacks() {
    _brManager.onPhaseChange = (phase) {
      onGameEvent?.call(VanCoGameEvent.phaseChanged, phase);
    };

    _brManager.onZoneShrinkWarning = () {
      onGameEvent?.call(VanCoGameEvent.zoneShrinking);
    };

    _brManager.onGameOver = (winnerId) {
      _handleGameOver(winnerId);
    };

    _lightningSystem.onWarningStart = (strike) {
      onGameEvent?.call(VanCoGameEvent.lightningWarning, strike);
    };

    _lightningSystem.onStrike = (strike) {
      onGameEvent?.call(VanCoGameEvent.lightningStrike, strike);
    };

    _lightningSystem.onHit = (strike, targetId) {
      _handleLightningHit(strike, targetId);
    };
  }

  // === GAME LIFECYCLE ===

  /// Start the game
  void startGame() {
    if (status != VanCoGameStatus.waiting) return;

    // Spawn player
    _spawnPlayer();

    // Spawn AI
    _spawnAICritters();

    // Spawn initial food
    _spawnInitialFood();

    // Start game
    status = VanCoGameStatus.playing;
  }

  void _spawnPlayer() {
    final spawnPos = _getRandomSpawnPosition();
    final critter = CritterFactory.createPlayer(
      faction: playerFaction,
      x: spawnPos.x,
      y: spawnPos.y,
    );

    playerCritter = CritterComponent(
      critter: critter,
      position: spawnPos,
    );

    playerCritter.onDeath = () {
      _handlePlayerDeath();
    };

    playerCritter.onTierUp = (tier) {
      onGameEvent?.call(VanCoGameEvent.playerTierUp, tier);
      _offerMutationChoice();
    };

    add(playerCritter);
  }

  void _spawnAICritters() {
    // Distribute AI across factions
    final factions = NguHanhFaction.values;

    for (int i = 0; i < aiCount; i++) {
      final faction = factions[i % factions.length];
      final spawnPos = _getRandomSpawnPosition();

      final critter = CritterFactory.createAI(
        faction: faction,
        x: spawnPos.x,
        y: spawnPos.y,
      );

      final component = CritterComponent(
        critter: critter,
        position: spawnPos,
      );

      component.onDeath = () {
        _handleAIDeath(component);
      };

      aiCritters.add(component);
      add(component);
    }
  }

  void _spawnInitialFood() {
    for (int i = 0; i < 30; i++) {
      _spawnFoodPellet();
    }
  }

  Vector2 _getRandomSpawnPosition() {
    // Spawn within current zone, away from center
    final radius = _brManager.state.currentZoneRadius * 0.8;
    final angle = _random.nextDouble() * 2 * pi;
    final distance = radius * 0.3 + _random.nextDouble() * radius * 0.5;

    return Vector2(
      cos(angle) * distance,
      sin(angle) * distance,
    );
  }

  // === UPDATE LOOP ===

  @override
  void update(double dt) {
    super.update(dt);

    if (status != VanCoGameStatus.playing) return;

    // Update BR manager
    _brManager.update(dt);

    // Update lightning system
    final lightningInterval = _brManager.currentLightningInterval;
    _lightningSystem.update(dt, strikeInterval: lightningInterval);

    // Lightning spawning
    _lightningTimer += dt;
    if (lightningInterval > 0 && _lightningTimer >= lightningInterval) {
      _lightningTimer = 0;
      _triggerLightning();
    }

    // Food spawning
    _foodSpawnTimer += dt;
    if (_foodSpawnTimer >= foodSpawnInterval && foodPellets.length < maxFoodPellets) {
      _foodSpawnTimer = 0;
      _spawnFoodPellet();
    }

    // AI updates (throttled)
    _aiUpdateTimer += dt;
    if (_aiUpdateTimer >= aiUpdateInterval) {
      _aiUpdateTimer = 0;
      _updateAI();
    }

    // Player input
    _updatePlayerMovement(dt);

    // Poison damage
    _applyPoisonDamage(dt);

    // Collision detection
    _checkCollisions();
  }

  // === PLAYER MOVEMENT ===

  void _updatePlayerMovement(double dt) {
    // Calculate direction to mouse
    final direction = _mousePosition - playerCritter.position;

    if (direction.length > 10) {
      direction.normalize();
      final speed = playerCritter.critter.effectiveSpeed;
      playerCritter.velocity = direction * speed;
      playerCritter.position += playerCritter.velocity * dt;
    } else {
      playerCritter.velocity = Vector2.zero();
    }

    // Clamp to zone (soft boundary)
    _clampToZone(playerCritter);
  }

  void _clampToZone(CritterComponent critter) {
    final maxRadius = BattleRoyaleManager.mapRadius;
    final distance = critter.position.length;

    if (distance > maxRadius) {
      critter.position.normalize();
      critter.position.scale(maxRadius);
    }
  }

  // === AI LOGIC ===

  void _updateAI() {
    for (final ai in aiCritters) {
      if (ai.critter.isDead) continue;

      // Find threats (larger critters)
      final threats = _findThreats(ai);

      // Find prey (smaller critters)
      final prey = _findPrey(ai);

      // Find nearest food
      final nearestFood = _findNearestFood(ai);

      // Decision making
      if (threats.isNotEmpty) {
        // FLEE from nearest threat
        _aiFleeFrom(ai, threats.first);
        ai.emotion = CritterEmotion.fleeing;
      } else if (prey.isNotEmpty && _shouldHunt(ai)) {
        // HUNT weakest prey
        _aiChase(ai, prey.first);
        ai.emotion = CritterEmotion.hunting;
      } else if (nearestFood != null) {
        // FARM food
        _aiMoveTo(ai, nearestFood.position);
        ai.emotion = CritterEmotion.neutral;
      } else {
        // WANDER
        _aiWander(ai);
        ai.emotion = CritterEmotion.neutral;
      }

      // Apply movement
      _applyAIMovement(ai);

      // Clamp to zone
      _clampToZone(ai);
    }
  }

  List<CritterComponent> _findThreats(CritterComponent critter) {
    final threats = <CritterComponent>[];

    // Check player
    if (critter.willBeEatenBy(playerCritter)) {
      threats.add(playerCritter);
    }

    // Check other AI
    for (final other in aiCritters) {
      if (other == critter || other.critter.isDead) continue;
      if (critter.willBeEatenBy(other)) {
        threats.add(other);
      }
    }

    // Sort by distance
    threats.sort((a, b) {
      final distA = a.position.distanceTo(critter.position);
      final distB = b.position.distanceTo(critter.position);
      return distA.compareTo(distB);
    });

    return threats;
  }

  List<CritterComponent> _findPrey(CritterComponent critter) {
    final prey = <CritterComponent>[];

    // Check player
    if (critter.canEat(playerCritter)) {
      prey.add(playerCritter);
    }

    // Check other AI
    for (final other in aiCritters) {
      if (other == critter || other.critter.isDead) continue;
      if (critter.canEat(other)) {
        prey.add(other);
      }
    }

    // Sort by size (prefer smaller)
    prey.sort((a, b) {
      return a.critter.size.compareTo(b.critter.size);
    });

    return prey;
  }

  FoodPelletComponent? _findNearestFood(CritterComponent critter) {
    if (foodPellets.isEmpty) return null;

    FoodPelletComponent? nearest;
    double nearestDist = double.infinity;

    for (final food in foodPellets) {
      final dist = food.position.distanceTo(critter.position);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = food;
      }
    }

    return nearest;
  }

  bool _shouldHunt(CritterComponent ai) {
    // More aggressive in later phases
    final phaseAggression = _brManager.state.currentPhase.index * 0.1;

    // Difficulty affects aggression
    final difficultyAggression = difficulty * 0.05;

    // Random factor
    final randomFactor = _random.nextDouble();

    return randomFactor < (0.3 + phaseAggression + difficultyAggression);
  }

  void _aiFleeFrom(CritterComponent ai, CritterComponent threat) {
    final direction = ai.position - threat.position;
    if (direction.length > 0) {
      direction.normalize();
      ai.targetPosition = ai.position + direction * 200;
    }
  }

  void _aiChase(CritterComponent ai, CritterComponent target) {
    ai.targetPosition = target.position.clone();
  }

  void _aiMoveTo(CritterComponent ai, Vector2 target) {
    ai.targetPosition = target.clone();
  }

  void _aiWander(CritterComponent ai) {
    if (ai.targetPosition.distanceTo(ai.position) < 50) {
      // Pick new random target
      final angle = _random.nextDouble() * 2 * pi;
      final distance = 100 + _random.nextDouble() * 200;
      ai.targetPosition = ai.position + Vector2(cos(angle), sin(angle)) * distance;
    }
  }

  void _applyAIMovement(CritterComponent ai) {
    final direction = ai.targetPosition - ai.position;

    if (direction.length > 10) {
      direction.normalize();
      final speed = ai.critter.effectiveSpeed;
      ai.velocity = direction * speed;
      ai.position += ai.velocity * aiUpdateInterval;
    } else {
      ai.velocity = Vector2.zero();
    }
  }

  // === COLLISION DETECTION ===

  void _checkCollisions() {
    // Player vs AI
    for (final ai in aiCritters) {
      if (ai.critter.isDead) continue;

      final distance = playerCritter.position.distanceTo(ai.position);
      final collisionDist = (playerCritter.size.x + ai.size.x) / 2;

      if (distance < collisionDist) {
        _handleCritterCollision(playerCritter, ai);
      }
    }

    // AI vs AI
    for (int i = 0; i < aiCritters.length; i++) {
      if (aiCritters[i].critter.isDead) continue;

      for (int j = i + 1; j < aiCritters.length; j++) {
        if (aiCritters[j].critter.isDead) continue;

        final distance = aiCritters[i].position.distanceTo(aiCritters[j].position);
        final collisionDist = (aiCritters[i].size.x + aiCritters[j].size.x) / 2;

        if (distance < collisionDist) {
          _handleCritterCollision(aiCritters[i], aiCritters[j]);
        }
      }
    }

    // Player vs Food
    for (final food in foodPellets.toList()) {
      final distance = playerCritter.position.distanceTo(food.position);
      if (distance < playerCritter.size.x / 2 + food.size.x / 2) {
        playerCritter.eatFood();
        food.removeFromParent();
        foodPellets.remove(food);
      }
    }

    // AI vs Food
    for (final ai in aiCritters) {
      if (ai.critter.isDead) continue;

      for (final food in foodPellets.toList()) {
        final distance = ai.position.distanceTo(food.position);
        if (distance < ai.size.x / 2 + food.size.x / 2) {
          ai.eatFood();
          food.removeFromParent();
          foodPellets.remove(food);
        }
      }
    }
  }

  void _handleCritterCollision(CritterComponent a, CritterComponent b) {
    final relation = SizeManager.getRelation(a.critter.size, b.critter.size);

    switch (relation) {
      case SizeRelation.canEat:
        // A eats B
        a.eat(b);
        b.takeDamage(b.critter.health); // Instant kill
        if (a == playerCritter) {
          onGameEvent?.call(VanCoGameEvent.playerAte, b.critter);
        }
        break;

      case SizeRelation.willBeEaten:
        // B eats A
        b.eat(a);
        a.takeDamage(a.critter.health); // Instant kill
        if (b == playerCritter) {
          onGameEvent?.call(VanCoGameEvent.playerAte, a.critter);
        }
        break;

      case SizeRelation.combat:
        // Combat - both take damage
        final damageA = b.critter.effectiveDamage;
        final damageB = a.critter.effectiveDamage;

        // Apply faction counter bonus
        final factionBonusA = NguHanhRegistry.getDamageMultiplier(
          a.critter.faction,
          b.critter.faction,
        );
        final factionBonusB = NguHanhRegistry.getDamageMultiplier(
          b.critter.faction,
          a.critter.faction,
        );

        a.takeDamage(damageA * factionBonusB);
        b.takeDamage(damageB * factionBonusA);

        a.emotion = CritterEmotion.combat;
        b.emotion = CritterEmotion.combat;
        break;
    }
  }

  // === POISON DAMAGE ===

  void _applyPoisonDamage(double dt) {
    // Player
    final playerPoisonDmg = _brManager.getPoisonDamageAt(
      playerCritter.position.x,
      playerCritter.position.y,
    );
    if (playerPoisonDmg > 0) {
      playerCritter.takeDamage(playerPoisonDmg * dt);
      onGameEvent?.call(VanCoGameEvent.playerDamaged, playerPoisonDmg * dt);
    }

    // AI
    for (final ai in aiCritters) {
      if (ai.critter.isDead) continue;

      final poisonDmg = _brManager.getPoisonDamageAt(
        ai.position.x,
        ai.position.y,
      );
      if (poisonDmg > 0) {
        ai.takeDamage(poisonDmg * dt);
      }
    }
  }

  // === LIGHTNING ===

  void _triggerLightning() {
    // Gather all targets
    final targets = <LightningTarget>[
      LightningTarget(
        id: playerCritter.critter.id,
        x: playerCritter.position.x,
        y: playerCritter.position.y,
        size: playerCritter.critter.size,
      ),
    ];

    for (final ai in aiCritters) {
      if (ai.critter.isDead) continue;
      targets.add(LightningTarget(
        id: ai.critter.id,
        x: ai.position.x,
        y: ai.position.y,
        size: ai.critter.size,
      ));
    }

    // Create targeted strike
    final isSuddenDeath = _brManager.state.isEndGame;
    _lightningSystem.createTargetedStrike(
      targets: targets,
      inSafeZone: false,
      isSuddenDeath: isSuddenDeath,
    );
  }

  void _handleLightningHit(LightningStrike strike, String targetId) {
    // Find target
    if (targetId == playerCritter.critter.id) {
      final damage = playerCritter.critter.effectiveMaxHealth * strike.damage;
      playerCritter.takeDamage(damage);
      onGameEvent?.call(VanCoGameEvent.playerDamaged, damage);
    } else {
      for (final ai in aiCritters) {
        if (ai.critter.id == targetId) {
          final damage = ai.critter.effectiveMaxHealth * strike.damage;
          ai.takeDamage(damage);
          break;
        }
      }
    }
  }

  // === FOOD SPAWNING ===

  void _spawnFoodPellet() {
    final pos = _getRandomSpawnPosition();

    // Only spawn inside current zone
    if (!_brManager.isInsideZone(pos.x, pos.y)) return;

    final food = FoodPelletComponent(position: pos);
    foodPellets.add(food);
    add(food);
  }

  // === DEATH HANDLING ===

  void _handlePlayerDeath() {
    final aliveCount = aiCritters.where((ai) => ai.critter.isAlive).length + 1;
    final placement = aliveCount;
    final kills = playerCritter.critter.kills;
    final timeSurvived = _brManager.state.gameTime.toInt();

    status = VanCoGameStatus.gameOver;
    onGameEvent?.call(VanCoGameEvent.playerDied);
    onGameEvent?.call(VanCoGameEvent.gameLost);
    onGameOver?.call(placement, kills, timeSurvived);
  }

  void _handleAIDeath(CritterComponent ai) {
    _brManager.onPlayerDeath(ai.critter.id);
    onGameEvent?.call(VanCoGameEvent.aiDied, ai.critter);

    // Check if player won
    final aliveAI = aiCritters.where((a) => a.critter.isAlive).length;
    if (aliveAI == 0 && playerCritter.critter.isAlive) {
      _handlePlayerWin();
    }
  }

  void _handlePlayerWin() {
    final kills = playerCritter.critter.kills;
    final timeSurvived = _brManager.state.gameTime.toInt();

    status = VanCoGameStatus.gameOver;
    onGameEvent?.call(VanCoGameEvent.gameWon);
    onGameOver?.call(1, kills, timeSurvived);
  }

  void _handleGameOver(String winnerId) {
    if (winnerId == playerCritter.critter.id) {
      _handlePlayerWin();
    } else {
      _handlePlayerDeath();
    }
  }

  // === MUTATION SYSTEM ===

  void _offerMutationChoice() {
    // Roll 3 mutations
    final currentMutations = playerCritter.critter.mutations
        .map((m) => _convertMutation(m))
        .whereType<VanCoMutation>()
        .toList();

    final choices = VanCoMutationRegistry.rollMutations(3, exclude: currentMutations);

    // TODO: Show UI for mutation choice
    // For now, auto-select first
    if (choices.isNotEmpty) {
      // Apply mutation effect
    }
  }

  VanCoMutation? _convertMutation(dynamic mutation) {
    // Convert from old mutation type if needed
    return null;
  }

  // === INPUT HANDLING ===

  void onMouseMove(Vector2 position) {
    _mousePosition = position;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keysPressed.clear();
    _keysPressed.addAll(keysPressed);

    // Space - Split
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _handleSplit();
    }

    // W - Eject mass
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyW) {
      _handleEjectMass();
    }

    // Escape - Pause
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _togglePause();
    }

    return true;
  }

  void _handleSplit() {
    // TODO: Implement split mechanic
  }

  void _handleEjectMass() {
    // TODO: Implement eject mass mechanic
  }

  void _togglePause() {
    if (status == VanCoGameStatus.playing) {
      status = VanCoGameStatus.paused;
    } else if (status == VanCoGameStatus.paused) {
      status = VanCoGameStatus.playing;
    }
  }

  // === GETTERS ===

  BRGameState get brState => _brManager.state;
  List<LightningStrike> get activeStrikes => _lightningSystem.activeStrikes;
  int get aliveCount => aiCritters.where((ai) => ai.critter.isAlive).length + 1;
}

/// Food Pellet Component
class FoodPelletComponent extends PositionComponent {
  static const double pelletSize = 8.0;

  final Paint _paint = Paint()..color = Colors.lightGreen;

  FoodPelletComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(pelletSize),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      _paint,
    );
  }
}
