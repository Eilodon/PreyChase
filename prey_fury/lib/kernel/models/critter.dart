/// Critter - Base entity for Vạn Cổ Chi Vương
///
/// All creatures in the game (player and AI) are Critters.
/// They have size, faction, mutations, and can eat each other.

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../systems/size_manager.dart';
import 'ngu_hanh_faction.dart';
import 'mutation_type.dart';

/// Critter status in the game
enum CritterStatus {
  alive,
  dead,
  spectating,
}

/// AI behavior state
enum CritterAIState {
  farming,   // Looking for food pellets
  hunting,   // Chasing smaller critters
  fleeing,   // Running from larger critters
  fighting,  // In combat zone with similar size
  hiding,    // Staying still, waiting
}

/// Critter entity - core data class
class Critter extends Equatable {
  final String id;
  final NguHanhFaction faction;
  final double size;
  final double health;
  final double maxHealth;
  final CritterStatus status;
  final List<MutationType> mutations;
  final int kills;
  final int placement; // Final placement (1 = winner)

  // Position (for game state, actual position in Component)
  final double x;
  final double y;

  // Combat stats
  final double baseDamage;
  final double baseSpeed;

  // Cooldowns
  final double splitCooldown;
  final double skillCooldown;

  const Critter({
    required this.id,
    required this.faction,
    this.size = SizeManager.startingSize,
    this.health = 100.0,
    this.maxHealth = 100.0,
    this.status = CritterStatus.alive,
    this.mutations = const [],
    this.kills = 0,
    this.placement = 0,
    this.x = 0,
    this.y = 0,
    this.baseDamage = 10.0,
    this.baseSpeed = 200.0,
    this.splitCooldown = 0,
    this.skillCooldown = 0,
  });

  // === COMPUTED PROPERTIES ===

  /// Current size tier
  SizeTier get tier => SizeManager.getTier(size);

  /// Size as percentage (0.0 to 1.0)
  double get sizePercent => SizeManager.getPercent(size);

  /// Is at max tier (Cổ Vương)
  bool get isMaxTier => tier == SizeTier.coVuong;

  /// Is alive
  bool get isAlive => status == CritterStatus.alive;

  /// Is dead
  bool get isDead => status == CritterStatus.dead;

  /// Effective speed (modified by size and faction)
  double get effectiveSpeed {
    final sizeModifier = SizeManager.getSpeedModifier(size);
    final factionBonus = NguHanhRegistry.get(faction).baseStats.speed / 100.0;
    return baseSpeed * sizeModifier * factionBonus;
  }

  /// Effective damage (modified by size and faction)
  double get effectiveDamage {
    final sizeModifier = SizeManager.getDamageModifier(size);
    final factionBonus = NguHanhRegistry.get(faction).baseStats.attack / 10.0;
    return baseDamage * sizeModifier * factionBonus;
  }

  /// Effective max health (modified by faction)
  double get effectiveMaxHealth {
    final factionBonus = NguHanhRegistry.get(faction).baseStats.hp / 100.0;
    return maxHealth * factionBonus;
  }

  /// Visual scale for rendering
  double get visualScale => SizeManager.getVisualScale(size);

  /// Can this critter eat another?
  bool canEat(Critter other) => SizeManager.canEat(size, other.size);

  /// Will this critter be eaten by another?
  bool willBeEatenBy(Critter other) => SizeManager.willBeEatenBy(size, other.size);

  /// Are we in combat zone with another?
  bool inCombatWith(Critter other) => SizeManager.inCombatZone(size, other.size);

  /// Get size indicator for UI
  SizeIndicator indicatorFor(Critter other) => SizeManager.getIndicator(size, other.size);

  /// Has a specific mutation
  bool hasMutation(MutationType type) => mutations.contains(type);

  /// Count of active mutations
  int get mutationCount => mutations.length;

  /// Can add more mutations (max 6)
  bool get canAddMutation => mutations.length < 6;

  // === COPY WITH ===

  Critter copyWith({
    String? id,
    NguHanhFaction? faction,
    double? size,
    double? health,
    double? maxHealth,
    CritterStatus? status,
    List<MutationType>? mutations,
    int? kills,
    int? placement,
    double? x,
    double? y,
    double? baseDamage,
    double? baseSpeed,
    double? splitCooldown,
    double? skillCooldown,
  }) {
    return Critter(
      id: id ?? this.id,
      faction: faction ?? this.faction,
      size: size ?? this.size,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      status: status ?? this.status,
      mutations: mutations ?? this.mutations,
      kills: kills ?? this.kills,
      placement: placement ?? this.placement,
      x: x ?? this.x,
      y: y ?? this.y,
      baseDamage: baseDamage ?? this.baseDamage,
      baseSpeed: baseSpeed ?? this.baseSpeed,
      splitCooldown: splitCooldown ?? this.splitCooldown,
      skillCooldown: skillCooldown ?? this.skillCooldown,
    );
  }

  // === GAME ACTIONS ===

  /// Eat another critter and grow
  Critter eat(Critter prey) {
    final newSize = SizeManager.sizeAfterEating(size, prey.size);
    final tierChanged = SizeManager.tierChanged(size, newSize);

    return copyWith(
      size: newSize,
      kills: kills + 1,
      // Health bonus on kill
      health: (health + 10).clamp(0, effectiveMaxHealth),
    );
  }

  /// Take damage
  Critter takeDamage(double damage) {
    final newHealth = (health - damage).clamp(0.0, effectiveMaxHealth);
    final newStatus = newHealth <= 0 ? CritterStatus.dead : status;

    // Size loss on damage (5% per hit)
    final newSize = SizeManager.sizeAfterDamage(size, 0.05);

    return copyWith(
      health: newHealth,
      status: newStatus,
      size: newSize,
    );
  }

  /// Heal
  Critter heal(double amount) {
    return copyWith(
      health: (health + amount).clamp(0.0, effectiveMaxHealth),
    );
  }

  /// Grow from food
  Critter eatFood() {
    final growth = size * SizeManager.growthFromFood;
    return copyWith(
      size: (size + growth).clamp(SizeManager.minSize, SizeManager.maxSize),
    );
  }

  /// Add mutation (on tier up)
  Critter addMutation(MutationType mutation) {
    if (!canAddMutation) return this;
    if (hasMutation(mutation)) return this;

    return copyWith(
      mutations: [...mutations, mutation],
    );
  }

  /// Die and set placement
  Critter die(int finalPlacement) {
    return copyWith(
      status: CritterStatus.dead,
      placement: finalPlacement,
    );
  }

  @override
  List<Object?> get props => [
    id, faction, size, health, status, mutations, kills, placement, x, y,
  ];
}

/// Factory for creating critters
class CritterFactory {
  static int _idCounter = 0;

  /// Generate unique ID
  static String generateId() {
    _idCounter++;
    return 'critter_$_idCounter';
  }

  /// Reset ID counter (for new game)
  static void resetIds() {
    _idCounter = 0;
  }

  /// Create player critter
  static Critter createPlayer({
    required NguHanhFaction faction,
    double x = 0,
    double y = 0,
  }) {
    final factionData = NguHanhRegistry.get(faction);
    return Critter(
      id: 'player',
      faction: faction,
      size: SizeManager.startingSize,
      health: factionData.baseStats.hp.toDouble(),
      maxHealth: factionData.baseStats.hp.toDouble(),
      baseSpeed: factionData.baseStats.speed.toDouble(),
      baseDamage: factionData.baseStats.attack.toDouble(),
      x: x,
      y: y,
    );
  }

  /// Create AI critter
  static Critter createAI({
    required NguHanhFaction faction,
    required double x,
    required double y,
    double? startingSize,
  }) {
    final factionData = NguHanhRegistry.get(faction);
    return Critter(
      id: generateId(),
      faction: faction,
      size: startingSize ?? SizeManager.startingSize,
      health: factionData.baseStats.hp.toDouble(),
      maxHealth: factionData.baseStats.hp.toDouble(),
      baseSpeed: factionData.baseStats.speed.toDouble(),
      baseDamage: factionData.baseStats.attack.toDouble(),
      x: x,
      y: y,
    );
  }

  /// Create boss critter (Cổ Trùng Mẫu)
  static Critter createBoss({
    required double x,
    required double y,
  }) {
    return Critter(
      id: 'boss_${generateId()}',
      faction: NguHanhFaction.tho, // Earth faction (tanky)
      size: SizeManager.maxSize * 0.6, // Start at 60% max
      health: 200.0,
      maxHealth: 200.0,
      baseSpeed: 80.0,
      baseDamage: 15.0,
      x: x,
      y: y,
    );
  }
}
