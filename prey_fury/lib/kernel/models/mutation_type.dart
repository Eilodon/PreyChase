/// Mutation System - Core types and data
/// Part of PREY CHAOS redesign

import 'package:flutter/material.dart';

/// All mutation types available in the game
enum MutationType {
  // ═══════════════════════════════════════════════════════════════════════════
  // OFFENSIVE MUTATIONS (6)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Eaten prey poison nearby enemies for 3s
  venomousFangs,
  
  /// Kills trigger chain explosions (radius grows with combo)
  chainReaction,
  
  /// Pull nearby prey toward your jaw
  magneticJaw,
  
  /// 25% chance to deal 3x damage on bite
  criticalBite,
  
  /// Eating prey increases attack speed temporarily
  hungerFrenzy,
  
  /// Prey you damage take bleed DoT
  razorTeeth,

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFENSIVE MUTATIONS (5)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// -30% damage taken from all sources
  armoredScales,
  
  /// Heal 1 HP/second when not in combat
  regeneration,
  
  /// Brief invulnerability after taking damage (0.5s i-frames)
  ghostPhase,
  
  /// Enemies that touch you take damage
  thornAura,
  
  /// Heal 10% of damage dealt
  lifeSteal,

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY MUTATIONS (5)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Slow-motion when HP < 25%
  timeWarp,
  
  /// Revive once per level with 50% HP
  secondChance,
  
  /// +50% drop rates from all sources
  treasureHunter,
  
  /// +20% base movement speed
  speedDemon,
  
  /// Combo timer extended by 50%
  comboMaster,

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGENDARY/COMBO MUTATIONS (3) - Unlock after certain achievements
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Each kill increases speed by 5% (stacks to 50%)
  bloodThirst,
  
  /// Low HP = high damage (up to +100% at 1 HP)
  berserker,
  
  /// No-hit bonus: score multiplier grows each wave
  perfectionist,
}

/// Mutation category for UI grouping and balance
enum MutationCategory {
  offensive,
  defensive,
  utility,
  legendary,
}

/// Rarity tier affecting drop rates
enum MutationTier {
  common,    // 60% chance in pool
  rare,      // 30% chance
  legendary, // 10% chance
}

/// Complete data for a mutation
class MutationData {
  final MutationType type;
  final String name;
  final String description;
  final String emoji;
  final MutationCategory category;
  final MutationTier tier;
  final Color color;
  final List<MutationType> synergiesWith;
  final List<MutationType> antiSynergies; // Cannot combine
  
  const MutationData({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.tier,
    required this.color,
    this.synergiesWith = const [],
    this.antiSynergies = const [],
  });

  /// Get synergy bonus multiplier when combined
  double getSynergyBonus(List<MutationType> otherMutations) {
    int synergyCount = 0;
    for (final other in otherMutations) {
      if (synergiesWith.contains(other)) synergyCount++;
    }
    return 1.0 + (synergyCount * 0.15); // +15% per synergy
  }
}

/// Central mutation registry with all data
class MutationRegistry {
  static const Map<MutationType, MutationData> _data = {
    // OFFENSIVE
    MutationType.venomousFangs: MutationData(
      type: MutationType.venomousFangs,
      name: 'Venomous Fangs',
      description: 'Eaten prey poison nearby enemies for 3s',
      emoji: '🐍',
      category: MutationCategory.offensive,
      tier: MutationTier.common,
      color: Color(0xFF7CB342),
      synergiesWith: [MutationType.chainReaction, MutationType.razorTeeth],
    ),
    MutationType.chainReaction: MutationData(
      type: MutationType.chainReaction,
      name: 'Chain Reaction',
      description: 'Kills trigger explosions that damage nearby prey',
      emoji: '💥',
      category: MutationCategory.offensive,
      tier: MutationTier.rare,
      color: Color(0xFFFF7043),
      synergiesWith: [MutationType.venomousFangs, MutationType.criticalBite],
    ),
    MutationType.magneticJaw: MutationData(
      type: MutationType.magneticJaw,
      name: 'Magnetic Jaw',
      description: 'Pull nearby prey toward your jaw',
      emoji: '🧲',
      category: MutationCategory.offensive,
      tier: MutationTier.common,
      color: Color(0xFF5C6BC0),
      synergiesWith: [MutationType.hungerFrenzy],
    ),
    MutationType.criticalBite: MutationData(
      type: MutationType.criticalBite,
      name: 'Critical Bite',
      description: '25% chance to deal 3x damage',
      emoji: '⚡',
      category: MutationCategory.offensive,
      tier: MutationTier.rare,
      color: Color(0xFFFFCA28),
      synergiesWith: [MutationType.chainReaction, MutationType.berserker],
    ),
    MutationType.hungerFrenzy: MutationData(
      type: MutationType.hungerFrenzy,
      name: 'Hunger Frenzy',
      description: 'Eating increases attack speed for 3s',
      emoji: '🔥',
      category: MutationCategory.offensive,
      tier: MutationTier.common,
      color: Color(0xFFEF5350),
      synergiesWith: [MutationType.magneticJaw, MutationType.bloodThirst],
    ),
    MutationType.razorTeeth: MutationData(
      type: MutationType.razorTeeth,
      name: 'Razor Teeth',
      description: 'Damaged prey bleed over time',
      emoji: '🦷',
      category: MutationCategory.offensive,
      tier: MutationTier.common,
      color: Color(0xFFB71C1C),
      synergiesWith: [MutationType.venomousFangs, MutationType.lifeSteal],
    ),
    
    // DEFENSIVE
    MutationType.armoredScales: MutationData(
      type: MutationType.armoredScales,
      name: 'Armored Scales',
      description: '-30% damage from all sources',
      emoji: '🛡️',
      category: MutationCategory.defensive,
      tier: MutationTier.common,
      color: Color(0xFF78909C),
      synergiesWith: [MutationType.thornAura, MutationType.regeneration],
      antiSynergies: [MutationType.berserker],
    ),
    MutationType.regeneration: MutationData(
      type: MutationType.regeneration,
      name: 'Regeneration',
      description: 'Heal 1 HP/sec out of combat',
      emoji: '💚',
      category: MutationCategory.defensive,
      tier: MutationTier.common,
      color: Color(0xFF66BB6A),
      synergiesWith: [MutationType.armoredScales, MutationType.secondChance],
    ),
    MutationType.ghostPhase: MutationData(
      type: MutationType.ghostPhase,
      name: 'Ghost Phase',
      description: '0.5s invulnerability after damage',
      emoji: '👻',
      category: MutationCategory.defensive,
      tier: MutationTier.rare,
      color: Color(0xFFB39DDB),
      synergiesWith: [MutationType.perfectionist, MutationType.timeWarp],
    ),
    MutationType.thornAura: MutationData(
      type: MutationType.thornAura,
      name: 'Thorn Aura',
      description: 'Enemies touching you take 5 damage',
      emoji: '🌵',
      category: MutationCategory.defensive,
      tier: MutationTier.rare,
      color: Color(0xFF8D6E63),
      synergiesWith: [MutationType.armoredScales],
    ),
    MutationType.lifeSteal: MutationData(
      type: MutationType.lifeSteal,
      name: 'Life Steal',
      description: 'Heal 10% of damage dealt',
      emoji: '🩸',
      category: MutationCategory.defensive,
      tier: MutationTier.rare,
      color: Color(0xFFD32F2F),
      synergiesWith: [MutationType.razorTeeth, MutationType.berserker],
    ),
    
    // UTILITY
    MutationType.timeWarp: MutationData(
      type: MutationType.timeWarp,
      name: 'Time Warp',
      description: 'Slow-motion when HP < 25%',
      emoji: '⏱️',
      category: MutationCategory.utility,
      tier: MutationTier.rare,
      color: Color(0xFF00ACC1),
      synergiesWith: [MutationType.ghostPhase, MutationType.secondChance],
    ),
    MutationType.secondChance: MutationData(
      type: MutationType.secondChance,
      name: 'Second Chance',
      description: 'Revive once per level at 50% HP',
      emoji: '💫',
      category: MutationCategory.utility,
      tier: MutationTier.legendary,
      color: Color(0xFFFFD54F),
      synergiesWith: [MutationType.timeWarp, MutationType.regeneration],
    ),
    MutationType.treasureHunter: MutationData(
      type: MutationType.treasureHunter,
      name: 'Treasure Hunter',
      description: '+50% drop rates',
      emoji: '💎',
      category: MutationCategory.utility,
      tier: MutationTier.common,
      color: Color(0xFF26A69A),
      synergiesWith: [MutationType.comboMaster],
    ),
    MutationType.speedDemon: MutationData(
      type: MutationType.speedDemon,
      name: 'Speed Demon',
      description: '+20% movement speed',
      emoji: '💨',
      category: MutationCategory.utility,
      tier: MutationTier.common,
      color: Color(0xFF42A5F5),
      synergiesWith: [MutationType.bloodThirst, MutationType.hungerFrenzy],
    ),
    MutationType.comboMaster: MutationData(
      type: MutationType.comboMaster,
      name: 'Combo Master',
      description: 'Combo timer +50% duration',
      emoji: '🎯',
      category: MutationCategory.utility,
      tier: MutationTier.common,
      color: Color(0xFFAB47BC),
      synergiesWith: [MutationType.treasureHunter, MutationType.perfectionist],
    ),
    
    // LEGENDARY
    MutationType.bloodThirst: MutationData(
      type: MutationType.bloodThirst,
      name: 'Blood Thirst',
      description: 'Each kill = +5% speed (max 50%)',
      emoji: '🩸',
      category: MutationCategory.legendary,
      tier: MutationTier.legendary,
      color: Color(0xFFC62828),
      synergiesWith: [MutationType.speedDemon, MutationType.hungerFrenzy],
    ),
    MutationType.berserker: MutationData(
      type: MutationType.berserker,
      name: 'Berserker',
      description: 'Low HP = +100% damage at 1 HP',
      emoji: '😈',
      category: MutationCategory.legendary,
      tier: MutationTier.legendary,
      color: Color(0xFFD50000),
      synergiesWith: [MutationType.lifeSteal, MutationType.criticalBite],
      antiSynergies: [MutationType.armoredScales],
    ),
    MutationType.perfectionist: MutationData(
      type: MutationType.perfectionist,
      name: 'Perfectionist',
      description: 'No-hit = growing score multiplier',
      emoji: '✨',
      category: MutationCategory.legendary,
      tier: MutationTier.legendary,
      color: Color(0xFFFFD700),
      synergiesWith: [MutationType.ghostPhase, MutationType.comboMaster],
    ),
  };

  /// Get mutation data by type
  static MutationData get(MutationType type) => _data[type]!;
  
  /// Get all mutations of a category
  static List<MutationData> byCategory(MutationCategory category) =>
      _data.values.where((m) => m.category == category).toList();
  
  /// Get all mutations of a tier
  static List<MutationData> byTier(MutationTier tier) =>
      _data.values.where((m) => m.tier == tier).toList();
  
  /// Check if two mutations have synergy
  static bool hasSynergy(MutationType a, MutationType b) =>
      _data[a]!.synergiesWith.contains(b);
  
  /// Check if two mutations are incompatible
  static bool hasAntiSynergy(MutationType a, MutationType b) =>
      _data[a]!.antiSynergies.contains(b);
  
  /// Get all active synergies for a set of mutations
  static List<(MutationType, MutationType)> getActiveSynergies(
    List<MutationType> mutations,
  ) {
    final synergies = <(MutationType, MutationType)>[];
    for (int i = 0; i < mutations.length; i++) {
      for (int j = i + 1; j < mutations.length; j++) {
        if (hasSynergy(mutations[i], mutations[j])) {
          synergies.add((mutations[i], mutations[j]));
        }
      }
    }
    return synergies;
  }
}
