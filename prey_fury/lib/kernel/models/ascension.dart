/// Ascension System - Progressive difficulty modifiers
/// Part of PREY CHAOS redesign (inspired by Slay the Spire)

import 'package:flutter/material.dart';

/// Maximum ascension level
const int maxAscensionLevel = 20;

/// Ascension modifier data
class AscensionModifier {
  final int level;
  final String name;
  final String description;
  final Color color;
  final Map<String, double> modifiers;
  
  const AscensionModifier({
    required this.level,
    required this.name,
    required this.description,
    required this.color,
    required this.modifiers,
  });
  
  /// Check if this modifier affects a specific stat
  bool affects(String stat) => modifiers.containsKey(stat);
  
  /// Get modifier value for a stat
  double getModifier(String stat) => modifiers[stat] ?? 0.0;
}

/// All ascension levels and their cumulative effects
class AscensionRegistry {
  static const List<AscensionModifier> _levels = [
    // Level 0 = Normal mode (no modifiers)
    AscensionModifier(
      level: 0,
      name: 'Normal',
      description: 'Standard difficulty',
      color: Color(0xFF4CAF50),
      modifiers: {},
    ),
    
    // Tier 1: Easy modifiers (1-5)
    AscensionModifier(
      level: 1,
      name: 'Swift Prey',
      description: '+10% prey movement speed',
      color: Color(0xFF8BC34A),
      modifiers: {'preySpeed': 0.10},
    ),
    AscensionModifier(
      level: 2,
      name: 'Elite Swarms',
      description: 'Elites can spawn in normal waves',
      color: Color(0xFFCDDC39),
      modifiers: {'eliteSpawnChance': 0.15},
    ),
    AscensionModifier(
      level: 3,
      name: 'Mutation Drought',
      description: '-1 max mutation slot',
      color: Color(0xFFFFEB3B),
      modifiers: {'maxMutations': -1.0},
    ),
    AscensionModifier(
      level: 4,
      name: 'Armored Prey',
      description: 'All prey gain shields',
      color: Color(0xFFFFC107),
      modifiers: {'preyShield': 1.0},
    ),
    AscensionModifier(
      level: 5,
      name: 'Barren Lands',
      description: 'No healing zones',
      color: Color(0xFFFF9800),
      modifiers: {'healingZones': -1.0},
    ),
    
    // Tier 2: Medium modifiers (6-10)
    AscensionModifier(
      level: 6,
      name: 'Aggressive Prey',
      description: '+25% prey aggression',
      color: Color(0xFFFF5722),
      modifiers: {'preyAggression': 0.25},
    ),
    AscensionModifier(
      level: 7,
      name: 'Boss Rush',
      description: 'Bosses spawn every 3 waves',
      color: Color(0xFFF44336),
      modifiers: {'bossFrequency': 0.5},
    ),
    AscensionModifier(
      level: 8,
      name: 'Fury Famine',
      description: '-30% fury generation',
      color: Color(0xFFE91E63),
      modifiers: {'furyGeneration': -0.30},
    ),
    AscensionModifier(
      level: 9,
      name: 'Prey Vengeance',
      description: 'Prey attack +50% on ally death',
      color: Color(0xFF9C27B0),
      modifiers: {'preyVengeance': 0.50},
    ),
    AscensionModifier(
      level: 10,
      name: 'Champion Prey',
      description: '+50% prey health',
      color: Color(0xFF673AB7),
      modifiers: {'preyHealth': 0.50},
    ),
    
    // Tier 3: Hard modifiers (11-15)
    AscensionModifier(
      level: 11,
      name: 'Relentless',
      description: 'Prey never stop chasing',
      color: Color(0xFF3F51B5),
      modifiers: {'preyPersistence': 1.0},
    ),
    AscensionModifier(
      level: 12,
      name: 'Cursed Hunger',
      description: '-50% health from food',
      color: Color(0xFF2196F3),
      modifiers: {'foodHealing': -0.50},
    ),
    AscensionModifier(
      level: 13,
      name: 'Time Pressure',
      description: 'Waves are 20% shorter',
      color: Color(0xFF03A9F4),
      modifiers: {'waveDuration': -0.20},
    ),
    AscensionModifier(
      level: 14,
      name: 'Glass Cannon',
      description: '+50% damage taken',
      color: Color(0xFF00BCD4),
      modifiers: {'damageTaken': 0.50},
    ),
    AscensionModifier(
      level: 15,
      name: 'True Nightmare',
      description: 'Boss rush mode (bosses only)',
      color: Color(0xFF009688),
      modifiers: {'bossOnly': 1.0},
    ),
    
    // Tier 4: Extreme modifiers (16-20)
    AscensionModifier(
      level: 16,
      name: 'Faction Fury',
      description: 'All factions hostile to player',
      color: Color(0xFF795548),
      modifiers: {'factionHostility': 1.0},
    ),
    AscensionModifier(
      level: 17,
      name: 'Death Zone',
      description: 'Arena shrinks over time',
      color: Color(0xFF607D8B),
      modifiers: {'arenaShrink': 0.05},
    ),
    AscensionModifier(
      level: 18,
      name: 'No Second Chances',
      description: 'Second Chance mutation disabled',
      color: Color(0xFF424242),
      modifiers: {'secondChanceDisabled': 1.0},
    ),
    AscensionModifier(
      level: 19,
      name: 'Absolute Chaos',
      description: 'Random events every 15 seconds',
      color: Color(0xFF212121),
      modifiers: {'eventFrequency': 4.0},
    ),
    AscensionModifier(
      level: 20,
      name: 'IMPOSSIBLE',
      description: 'For legends only. All modifiers active at 150%.',
      color: Color(0xFFD50000),
      modifiers: {'allModifiers': 1.50},
    ),
  ];
  
  /// Get modifier for a specific level
  static AscensionModifier getLevel(int level) {
    if (level < 0) return _levels[0];
    if (level >= _levels.length) return _levels.last;
    return _levels[level];
  }
  
  /// Get all modifiers for a level (cumulative)
  static List<AscensionModifier> getActiveModifiers(int level) {
    return _levels.sublist(0, level.clamp(0, _levels.length));
  }
  
  /// Calculate cumulative modifier value for a stat
  static double getCumulativeModifier(int level, String stat) {
    double total = 0.0;
    final allModifierMultiplier = level >= 20 ? 1.5 : 1.0;
    
    for (final mod in getActiveModifiers(level + 1)) {
      if (mod.affects(stat)) {
        total += mod.getModifier(stat) * allModifierMultiplier;
      }
    }
    
    return total;
  }
  
  /// Get display name for current ascension
  static String getDisplayName(int level) {
    if (level == 0) return 'Normal';
    return 'Ascension $level';
  }
  
  /// Get color for current ascension
  static Color getColor(int level) => getLevel(level).color;
  
  /// Check if a specific feature is disabled at this level
  static bool isDisabled(int level, String feature) {
    return getCumulativeModifier(level, feature) < 0 ||
           getCumulativeModifier(level, '${feature}Disabled') > 0;
  }
}

/// Ascension run state
class AscensionState {
  final int currentLevel;
  final bool isUnlocked;
  final int highestCompleted;
  final Map<int, int> completionCount;
  
  const AscensionState({
    this.currentLevel = 0,
    this.isUnlocked = false,
    this.highestCompleted = 0,
    this.completionCount = const {},
  });
  
  AscensionState copyWith({
    int? currentLevel,
    bool? isUnlocked,
    int? highestCompleted,
    Map<int, int>? completionCount,
  }) {
    return AscensionState(
      currentLevel: currentLevel ?? this.currentLevel,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      highestCompleted: highestCompleted ?? this.highestCompleted,
      completionCount: completionCount ?? this.completionCount,
    );
  }
  
  /// Record a win at current ascension level
  AscensionState recordWin() {
    final newCount = Map<int, int>.from(completionCount);
    newCount[currentLevel] = (newCount[currentLevel] ?? 0) + 1;
    
    return copyWith(
      highestCompleted: currentLevel > highestCompleted ? currentLevel : highestCompleted,
      completionCount: newCount,
    );
  }
  
  /// Check if next ascension level is available
  bool get canAscend => highestCompleted >= currentLevel && currentLevel < maxAscensionLevel;
  
  /// Move to next ascension level
  AscensionState ascend() {
    if (!canAscend) return this;
    return copyWith(currentLevel: currentLevel + 1);
  }
}
