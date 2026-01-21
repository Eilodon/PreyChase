import 'package:flutter/material.dart';

/// Power-up system for in-run progression (Vampire Survivors-style)
///
/// Players select power-ups during gameplay to customize their build
/// Inspired by: Vampire Survivors, Brotato, Hades

enum PowerUpCategory {
  offensive, // Damage, fury, attack
  defensive, // Health, armor, regeneration
  mobility, // Speed, dash, teleport
  utility, // Score, XP, collection
}

enum PowerUpRarity {
  common, // 60% chance
  rare, // 30% chance
  epic, // 9% chance
  legendary, // 1% chance
}

class PowerUp {
  final String id;
  final String name;
  final String description;
  final PowerUpCategory category;
  final PowerUpRarity rarity;
  final String icon; // Emoji icon

  // Stackable power-ups can be selected multiple times
  final bool stackable;
  final int maxStacks;

  // Current stack count (0 = not acquired)
  int stacks = 0;

  PowerUp({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.icon,
    this.stackable = true,
    this.maxStacks = 5,
  });

  bool get canStack => stackable && stacks < maxStacks;
  bool get isMaxed => stacks >= maxStacks;

  /// Static registry of all available power-ups
  static final Map<String, PowerUp> registry = {
    // === OFFENSIVE ===
    'fury_duration': PowerUp(
      id: 'fury_duration',
      name: 'Extended Fury',
      description: 'Fury Mode lasts +2 seconds',
      category: PowerUpCategory.offensive,
      rarity: PowerUpRarity.common,
      icon: '🔥',
      maxStacks: 3, // Max +6 seconds
    ),
    'fury_damage': PowerUp(
      id: 'fury_damage',
      name: 'Fury Power',
      description: 'Deal +50% damage during Fury',
      category: PowerUpCategory.offensive,
      rarity: PowerUpRarity.common,
      icon: '💥',
      maxStacks: 4, // Max +200% damage
    ),
    'magnetic_range': PowerUp(
      id: 'magnetic_range',
      name: 'Magnetic Jaws',
      description: 'Pull prey from +50% farther',
      category: PowerUpCategory.offensive,
      rarity: PowerUpRarity.rare,
      icon: '🧲',
      maxStacks: 3,
    ),
    'chain_fury': PowerUp(
      id: 'chain_fury',
      name: 'Fury Chain',
      description: 'Kills during Fury extend duration by 0.5s',
      category: PowerUpCategory.offensive,
      rarity: PowerUpRarity.epic,
      icon: '⚡',
      stackable: false, // Unique effect
    ),
    'rage_mode': PowerUp(
      id: 'rage_mode',
      name: 'Berserker',
      description: 'Fury activates automatically at low HP',
      category: PowerUpCategory.offensive,
      rarity: PowerUpRarity.legendary,
      icon: '😡',
      stackable: false,
    ),

    // === DEFENSIVE ===
    'max_health': PowerUp(
      id: 'max_health',
      name: 'Thick Scales',
      description: '+20 Max HP',
      category: PowerUpCategory.defensive,
      rarity: PowerUpRarity.common,
      icon: '❤️',
      maxStacks: 5, // Max +100 HP
    ),
    'health_regen': PowerUp(
      id: 'health_regen',
      name: 'Regeneration',
      description: 'Regenerate +2 HP per second',
      category: PowerUpCategory.defensive,
      rarity: PowerUpRarity.rare,
      icon: '💚',
      maxStacks: 3, // Max +6 HP/s
    ),
    'armor': PowerUp(
      id: 'armor',
      name: 'Armored Hide',
      description: 'Take 10% less damage from all sources',
      category: PowerUpCategory.defensive,
      rarity: PowerUpRarity.rare,
      icon: '🛡️',
      maxStacks: 4, // Max 40% reduction
    ),
    'second_chance': PowerUp(
      id: 'second_chance',
      name: 'Phoenix Feather',
      description: 'Revive once when killed with 50% HP',
      category: PowerUpCategory.defensive,
      rarity: PowerUpRarity.epic,
      icon: '🔄',
      stackable: false,
    ),
    'invincibility_frames': PowerUp(
      id: 'invincibility_frames',
      name: 'Ghost Phase',
      description: '1 second invincibility after taking damage',
      category: PowerUpCategory.defensive,
      rarity: PowerUpRarity.legendary,
      icon: '👻',
      stackable: false,
    ),

    // === MOBILITY ===
    'move_speed': PowerUp(
      id: 'move_speed',
      name: 'Swift Swimmer',
      description: '+15% movement speed',
      category: PowerUpCategory.mobility,
      rarity: PowerUpRarity.common,
      icon: '💨',
      maxStacks: 4, // Max +60% speed
    ),
    'dash_ability': PowerUp(
      id: 'dash_ability',
      name: 'Quick Dash',
      description: 'Unlock dash ability (Shift key)',
      category: PowerUpCategory.mobility,
      rarity: PowerUpRarity.rare,
      icon: '⚡',
      stackable: false,
    ),
    'dash_cooldown': PowerUp(
      id: 'dash_cooldown',
      name: 'Rapid Dash',
      description: 'Reduce dash cooldown by 20%',
      category: PowerUpCategory.mobility,
      rarity: PowerUpRarity.rare,
      icon: '🏃',
      maxStacks: 3,
    ),
    'teleport': PowerUp(
      id: 'teleport',
      name: 'Blink',
      description: 'Teleport to cursor location (E key, 10s cooldown)',
      category: PowerUpCategory.mobility,
      rarity: PowerUpRarity.epic,
      icon: '✨',
      stackable: false,
    ),
    'time_slow': PowerUp(
      id: 'time_slow',
      name: 'Time Warp',
      description: 'Slow all enemies by 30% for 3 seconds (Q key)',
      category: PowerUpCategory.mobility,
      rarity: PowerUpRarity.legendary,
      icon: '⏰',
      stackable: false,
    ),

    // === UTILITY ===
    'score_multiplier': PowerUp(
      id: 'score_multiplier',
      name: 'Golden Touch',
      description: '+25% score from all sources',
      category: PowerUpCategory.utility,
      rarity: PowerUpRarity.common,
      icon: '💰',
      maxStacks: 4, // Max +100% score
    ),
    'fury_gain': PowerUp(
      id: 'fury_gain',
      name: 'Fury Builder',
      description: 'Gain +25% more Fury meter',
      category: PowerUpCategory.utility,
      rarity: PowerUpRarity.rare,
      icon: '⚡',
      maxStacks: 3,
    ),
    'xp_boost': PowerUp(
      id: 'xp_boost',
      name: 'Fast Learner',
      description: '+50% XP gain for species progression',
      category: PowerUpCategory.utility,
      rarity: PowerUpRarity.rare,
      icon: '📈',
      maxStacks: 2,
    ),
    'magnet': PowerUp(
      id: 'magnet',
      name: 'Item Magnet',
      description: 'Auto-collect items from farther away',
      category: PowerUpCategory.utility,
      rarity: PowerUpRarity.epic,
      icon: '🧲',
      stackable: false,
    ),
    'lucky': PowerUp(
      id: 'lucky',
      name: 'Lucky Croc',
      description: 'Higher chance of rare power-ups appearing',
      category: PowerUpCategory.utility,
      rarity: PowerUpRarity.legendary,
      icon: '🍀',
      stackable: false,
    ),
  };

  /// Creates a copy of this power-up for offering to player
  PowerUp copy() {
    return PowerUp(
      id: id,
      name: name,
      description: description,
      category: category,
      rarity: rarity,
      icon: icon,
      stackable: stackable,
      maxStacks: maxStacks,
    )..stacks = stacks;
  }

  /// Get color for rarity
  static Color getRarityColor(PowerUpRarity rarity) {
    switch (rarity) {
      case PowerUpRarity.common:
        return const Color(0xFFFFFFFF); // White
      case PowerUpRarity.rare:
        return const Color(0xFF3B82F6); // Blue
      case PowerUpRarity.epic:
        return const Color(0xFFA855F7); // Purple
      case PowerUpRarity.legendary:
        return const Color(0xFFFFD700); // Gold
    }
  }
}
