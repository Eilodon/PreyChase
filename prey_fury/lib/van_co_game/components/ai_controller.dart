/// AI Controller - Size-based AI behaviors for Vạn Cổ Chi Vương
///
/// AI Decision Making:
/// 1. SURVIVE: Flee from threats (larger critters)
/// 2. HUNT: Chase prey (smaller critters)
/// 3. FARM: Collect food pellets
/// 4. ZONE: Stay inside safe zone
///
/// Personality affects aggression and risk-taking

import 'dart:math';

import 'package:flame/components.dart';

import '../../kernel/models/ngu_hanh_faction.dart';
import '../../kernel/systems/size_manager.dart';
import 'critter_component.dart';

/// AI Personality types
enum AIPersonality {
  /// 70% hunt, 30% farm - Very aggressive
  aggressive(huntChance: 0.7, farmChance: 0.3, fleeThreshold: 1.15),

  /// 50% hunt, 50% farm - Balanced
  balanced(huntChance: 0.5, farmChance: 0.5, fleeThreshold: 1.10),

  /// 30% hunt, 70% farm - Careful
  passive(huntChance: 0.3, farmChance: 0.7, fleeThreshold: 1.05),

  /// Always attack, ignore threats - Reckless
  berserker(huntChance: 0.9, farmChance: 0.1, fleeThreshold: 1.30),

  /// Prioritize survival - Only eat when safe
  survivor(huntChance: 0.2, farmChance: 0.8, fleeThreshold: 1.02);

  final double huntChance;
  final double farmChance;
  final double fleeThreshold; // Flee when enemy is this ratio larger

  const AIPersonality({
    required this.huntChance,
    required this.farmChance,
    required this.fleeThreshold,
  });

  static AIPersonality random(Random rng) {
    return AIPersonality.values[rng.nextInt(AIPersonality.values.length)];
  }
}

/// AI State machine states
enum AIState {
  idle,       // Standing still, deciding
  farming,    // Moving to food
  hunting,    // Chasing prey
  fleeing,    // Running from threat
  fighting,   // In combat with similar size
  retreating, // Moving to safe zone
}

/// AI Controller for a single critter
class AIController extends Component {
  final CritterComponent critter;
  final AIPersonality personality;
  final Random _random;

  // === STATE ===
  AIState state = AIState.idle;
  Vector2 targetPosition = Vector2.zero();
  CritterComponent? targetCritter;
  double stateTimer = 0;
  double decisionCooldown = 0;

  // === CONFIGURATION ===
  static const double visionRange = 300.0;
  static const double dangerRange = 150.0;
  static const double decisionInterval = 0.5; // Decide every 0.5s
  static const double wanderDistance = 200.0;
  static const double separationDistance = 50.0;

  // === ZONE AWARENESS ===
  double zoneRadius = 1000.0;
  Vector2 zoneCenter = Vector2.zero();

  AIController({
    required this.critter,
    AIPersonality? personality,
    int? seed,
  }) : personality = personality ?? AIPersonality.balanced,
       _random = Random(seed);

  // === UPDATE ===

  @override
  void update(double dt) {
    super.update(dt);

    // Update timers
    stateTimer += dt;
    decisionCooldown -= dt;

    // Make decisions periodically
    if (decisionCooldown <= 0) {
      decisionCooldown = decisionInterval + _random.nextDouble() * 0.2; // Add jitter
      _makeDecision();
    }

    // Execute current behavior
    _executeBehavior(dt);
  }

  // === DECISION MAKING ===

  void _makeDecision() {
    // Get nearby entities
    final threats = _scanThreats();
    final prey = _scanPrey();
    final foods = _scanFood();

    // Check zone
    final isOutsideZone = !_isInsideZone(critter.position);
    final isNearZoneEdge = _distanceToZoneEdge(critter.position) < 100;

    // Priority 1: Flee from zone if outside
    if (isOutsideZone) {
      _setState(AIState.retreating);
      targetPosition = _getZoneRetreatPosition();
      return;
    }

    // Priority 2: Flee from threats (unless berserker)
    if (threats.isNotEmpty && personality != AIPersonality.berserker) {
      final nearestThreat = threats.first;
      final distance = critter.position.distanceTo(nearestThreat.position);

      // Flee if threat is close enough
      if (distance < dangerRange * personality.fleeThreshold) {
        _setState(AIState.fleeing);
        targetCritter = nearestThreat;
        targetPosition = _getFleePosition(nearestThreat);
        return;
      }
    }

    // Priority 3: Hunt prey or farm food
    final shouldHunt = _random.nextDouble() < personality.huntChance;

    if (shouldHunt && prey.isNotEmpty) {
      // Hunt the weakest prey
      final target = _selectPrey(prey);
      _setState(AIState.hunting);
      targetCritter = target;
      targetPosition = target.position.clone();
      return;
    }

    if (foods.isNotEmpty) {
      // Farm nearest food
      final nearestFood = foods.first;
      _setState(AIState.farming);
      targetPosition = nearestFood;
      return;
    }

    // Priority 4: Wander (but stay in zone)
    _setState(AIState.idle);
    targetPosition = _getWanderPosition();

    // Adjust for zone edge
    if (isNearZoneEdge) {
      targetPosition = _adjustForZone(targetPosition);
    }
  }

  void _setState(AIState newState) {
    if (state != newState) {
      state = newState;
      stateTimer = 0;

      // Update critter emotion
      switch (newState) {
        case AIState.hunting:
          critter.emotion = CritterEmotion.hunting;
          break;
        case AIState.fleeing:
        case AIState.retreating:
          critter.emotion = CritterEmotion.fleeing;
          break;
        case AIState.fighting:
          critter.emotion = CritterEmotion.combat;
          break;
        default:
          critter.emotion = CritterEmotion.neutral;
      }
    }
  }

  // === BEHAVIOR EXECUTION ===

  void _executeBehavior(double dt) {
    switch (state) {
      case AIState.hunting:
        _executeHunting(dt);
        break;
      case AIState.fleeing:
        _executeFleeing(dt);
        break;
      case AIState.retreating:
        _executeRetreating(dt);
        break;
      case AIState.farming:
      case AIState.idle:
      default:
        _executeMovement(dt);
    }
  }

  void _executeHunting(double dt) {
    if (targetCritter == null || targetCritter!.critter.isDead) {
      _setState(AIState.idle);
      return;
    }

    // Update target position (prey is moving)
    targetPosition = targetCritter!.position.clone();

    // Predict prey movement
    if (targetCritter!.velocity.length > 10) {
      targetPosition += targetCritter!.velocity * 0.3; // Lead the target
    }

    _executeMovement(dt);
  }

  void _executeFleeing(double dt) {
    if (targetCritter == null || targetCritter!.critter.isDead) {
      _setState(AIState.idle);
      return;
    }

    // Recalculate flee direction
    targetPosition = _getFleePosition(targetCritter!);

    _executeMovement(dt);
  }

  void _executeRetreating(double dt) {
    // Move toward zone center
    targetPosition = _getZoneRetreatPosition();
    _executeMovement(dt);

    // Check if back in zone
    if (_isInsideZone(critter.position)) {
      _setState(AIState.idle);
    }
  }

  void _executeMovement(double dt) {
    final direction = targetPosition - critter.position;
    final distance = direction.length;

    if (distance > 5) {
      direction.normalize();

      // Apply separation from nearby critters
      final separation = _calculateSeparation();
      direction.add(separation);
      direction.normalize();

      // Move
      final speed = critter.critter.effectiveSpeed;
      critter.velocity = direction * speed;
      critter.position += critter.velocity * dt;
    } else {
      // Arrived at target
      critter.velocity.scale(0.8);

      if (state == AIState.farming || state == AIState.idle) {
        // Pick new target after arriving
        decisionCooldown = 0;
      }
    }
  }

  // === SCANNING ===

  List<CritterComponent> _scanThreats() {
    final threats = <CritterComponent>[];
    final world = parent;

    if (world == null) return threats;

    // Scan for larger critters
    for (final child in world.children) {
      if (child is CritterComponent && child != critter && child.critter.isAlive) {
        final distance = critter.position.distanceTo(child.position);
        if (distance < visionRange && critter.willBeEatenBy(child)) {
          threats.add(child);
        }
      }
    }

    // Sort by distance (nearest first)
    threats.sort((a, b) {
      final distA = critter.position.distanceTo(a.position);
      final distB = critter.position.distanceTo(b.position);
      return distA.compareTo(distB);
    });

    return threats;
  }

  List<CritterComponent> _scanPrey() {
    final prey = <CritterComponent>[];
    final world = parent;

    if (world == null) return prey;

    // Scan for smaller critters
    for (final child in world.children) {
      if (child is CritterComponent && child != critter && child.critter.isAlive) {
        final distance = critter.position.distanceTo(child.position);
        if (distance < visionRange && critter.canEat(child)) {
          prey.add(child);
        }
      }
    }

    // Sort by size (smallest first - easier target)
    prey.sort((a, b) => a.critter.size.compareTo(b.critter.size));

    return prey;
  }

  List<Vector2> _scanFood() {
    final foods = <Vector2>[];
    final world = parent;

    if (world == null) return foods;

    // Scan for food pellets
    for (final child in world.children) {
      if (child is PositionComponent && child.runtimeType.toString().contains('Food')) {
        final distance = critter.position.distanceTo(child.position);
        if (distance < visionRange) {
          foods.add(child.position.clone());
        }
      }
    }

    // Sort by distance (nearest first)
    foods.sort((a, b) {
      final distA = critter.position.distanceTo(a);
      final distB = critter.position.distanceTo(b);
      return distA.compareTo(distB);
    });

    return foods;
  }

  // === POSITION CALCULATIONS ===

  CritterComponent _selectPrey(List<CritterComponent> prey) {
    // Prefer prey that's:
    // 1. Closer
    // 2. Smaller (easier kill)
    // 3. Same faction's rival (faction bonus)

    CritterComponent? best;
    double bestScore = -1;

    final myFaction = critter.critter.faction;

    for (final p in prey) {
      final distance = critter.position.distanceTo(p.position);
      final sizeRatio = critter.critter.size / p.critter.size;

      // Score: higher is better target
      var score = (visionRange - distance) / visionRange; // 0-1 for distance
      score += (sizeRatio - 1.1) * 2; // Bonus for size advantage

      // Faction bonus (target countered faction)
      if (NguHanhRegistry.counters(myFaction, p.critter.faction)) {
        score += 0.5;
      }

      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }

    return best ?? prey.first;
  }

  Vector2 _getFleePosition(CritterComponent threat) {
    // Flee in opposite direction
    final direction = critter.position - threat.position;
    if (direction.length > 0) {
      direction.normalize();
    } else {
      // Random direction if exactly on top
      final angle = _random.nextDouble() * 2 * pi;
      direction.setValues(cos(angle), sin(angle));
    }

    // Flee a good distance
    var fleeTarget = critter.position + direction * dangerRange * 2;

    // Adjust for zone boundary
    fleeTarget = _adjustForZone(fleeTarget);

    return fleeTarget;
  }

  Vector2 _getWanderPosition() {
    // Random direction and distance
    final angle = _random.nextDouble() * 2 * pi;
    final distance = wanderDistance * (0.5 + _random.nextDouble() * 0.5);

    return critter.position + Vector2(cos(angle), sin(angle)) * distance;
  }

  Vector2 _getZoneRetreatPosition() {
    // Move toward zone center
    final direction = zoneCenter - critter.position;
    if (direction.length > 0) {
      direction.normalize();
    }

    // Target a point well inside the zone
    return zoneCenter + direction * (-zoneRadius * 0.3);
  }

  Vector2 _calculateSeparation() {
    final separation = Vector2.zero();
    final world = parent;

    if (world == null) return separation;

    int count = 0;

    for (final child in world.children) {
      if (child is CritterComponent && child != critter) {
        final distance = critter.position.distanceTo(child.position);
        if (distance < separationDistance && distance > 0) {
          // Push away from nearby critter
          final away = critter.position - child.position;
          away.normalize();
          away.scale(1.0 - distance / separationDistance); // Stronger when closer
          separation.add(away);
          count++;
        }
      }
    }

    if (count > 0) {
      separation.scale(1.0 / count);
    }

    return separation;
  }

  // === ZONE HELPERS ===

  bool _isInsideZone(Vector2 position) {
    final distance = position.distanceTo(zoneCenter);
    return distance <= zoneRadius;
  }

  double _distanceToZoneEdge(Vector2 position) {
    final distance = position.distanceTo(zoneCenter);
    return zoneRadius - distance;
  }

  Vector2 _adjustForZone(Vector2 position) {
    final distance = position.distanceTo(zoneCenter);

    if (distance > zoneRadius * 0.9) {
      // Pull back toward center
      final direction = zoneCenter - position;
      direction.normalize();
      return position + direction * (distance - zoneRadius * 0.8);
    }

    return position;
  }

  // === EXTERNAL UPDATES ===

  void updateZone(Vector2 center, double radius) {
    zoneCenter = center;
    zoneRadius = radius;
  }
}

/// Factory for creating AI controllers with varied personalities
class AIControllerFactory {
  static final Random _random = Random();

  /// Create AI controller with random personality based on difficulty
  static AIController create(CritterComponent critter, int difficulty) {
    // Higher difficulty = more aggressive AI
    final personalities = <AIPersonality>[];

    if (difficulty <= 3) {
      // Easy: mostly passive
      personalities.addAll([
        AIPersonality.passive,
        AIPersonality.passive,
        AIPersonality.balanced,
        AIPersonality.survivor,
      ]);
    } else if (difficulty <= 6) {
      // Medium: balanced mix
      personalities.addAll([
        AIPersonality.passive,
        AIPersonality.balanced,
        AIPersonality.balanced,
        AIPersonality.aggressive,
      ]);
    } else {
      // Hard: aggressive
      personalities.addAll([
        AIPersonality.balanced,
        AIPersonality.aggressive,
        AIPersonality.aggressive,
        AIPersonality.berserker,
      ]);
    }

    final personality = personalities[_random.nextInt(personalities.length)];

    return AIController(
      critter: critter,
      personality: personality,
      seed: _random.nextInt(10000),
    );
  }
}
