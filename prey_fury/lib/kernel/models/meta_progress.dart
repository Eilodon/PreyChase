/// Meta Progression System - Permanent unlocks across runs
/// Part of PREY CHAOS redesign

import 'species.dart';
import 'mutation_type.dart';

/// Currency types for meta progression
enum MetaCurrency {
  /// Standard currency from runs
  evolutionPoints,
  
  /// Premium/rare currency from achievements
  primordialEssence,
}

/// Achievement categories
enum AchievementCategory {
  combat,
  survival,
  collection,
  mastery,
  secret,
}

/// Achievement definition
class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final int targetValue;
  final Map<MetaCurrency, int> rewards;
  final bool isSecret;
  
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.targetValue,
    required this.rewards,
    this.isSecret = false,
  });
}

/// Starting loadout presets
class StartingLoadout {
  final String id;
  final String name;
  final String description;
  final Map<String, double> statModifiers;
  final List<MutationType> startingMutations;
  final int unlockCost;
  final bool isUnlocked;
  
  const StartingLoadout({
    required this.id,
    required this.name,
    required this.description,
    required this.statModifiers,
    this.startingMutations = const [],
    required this.unlockCost,
    this.isUnlocked = false,
  });
}

/// Complete meta progression state (persisted)
class MetaProgressState {
  // Currency
  final int evolutionPoints;
  final int primordialEssence;
  
  // Stats
  final int totalRuns;
  final int totalPreyEaten;
  final int totalBossesDefeated;
  final int highestWaveReached;
  final int highestAscension;
  final Duration totalPlayTime;
  
  // Unlocks
  final Species selectedSpecies;
  final SpeciesTier currentTier;
  final Set<String> unlockedLoadouts;
  final Set<String> completedAchievements;
  final Set<MutationType> seenMutations;
  final Set<String> unlockedSkins;
  
  // Daily/Weekly
  final DateTime lastDailyReset;
  final int dailyChallengesCompleted;
  final int weeklyChallengesCompleted;
  
  const MetaProgressState({
    this.evolutionPoints = 0,
    this.primordialEssence = 0,
    this.totalRuns = 0,
    this.totalPreyEaten = 0,
    this.totalBossesDefeated = 0,
    this.highestWaveReached = 0,
    this.highestAscension = 0,
    this.totalPlayTime = Duration.zero,
    this.selectedSpecies = Species.crocodile,
    this.currentTier = SpeciesTier.hatchling,
    this.unlockedLoadouts = const {'default'},
    this.completedAchievements = const {},
    this.seenMutations = const {},
    this.unlockedSkins = const {'default'},
    required this.lastDailyReset,
    this.dailyChallengesCompleted = 0,
    this.weeklyChallengesCompleted = 0,
  });
  
  MetaProgressState copyWith({
    int? evolutionPoints,
    int? primordialEssence,
    int? totalRuns,
    int? totalPreyEaten,
    int? totalBossesDefeated,
    int? highestWaveReached,
    int? highestAscension,
    Duration? totalPlayTime,
    Species? selectedSpecies,
    SpeciesTier? currentTier,
    Set<String>? unlockedLoadouts,
    Set<String>? completedAchievements,
    Set<MutationType>? seenMutations,
    Set<String>? unlockedSkins,
    DateTime? lastDailyReset,
    int? dailyChallengesCompleted,
    int? weeklyChallengesCompleted,
  }) {
    return MetaProgressState(
      evolutionPoints: evolutionPoints ?? this.evolutionPoints,
      primordialEssence: primordialEssence ?? this.primordialEssence,
      totalRuns: totalRuns ?? this.totalRuns,
      totalPreyEaten: totalPreyEaten ?? this.totalPreyEaten,
      totalBossesDefeated: totalBossesDefeated ?? this.totalBossesDefeated,
      highestWaveReached: highestWaveReached ?? this.highestWaveReached,
      highestAscension: highestAscension ?? this.highestAscension,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      selectedSpecies: selectedSpecies ?? this.selectedSpecies,
      currentTier: currentTier ?? this.currentTier,
      unlockedLoadouts: unlockedLoadouts ?? this.unlockedLoadouts,
      completedAchievements: completedAchievements ?? this.completedAchievements,
      seenMutations: seenMutations ?? this.seenMutations,
      unlockedSkins: unlockedSkins ?? this.unlockedSkins,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
      dailyChallengesCompleted: dailyChallengesCompleted ?? this.dailyChallengesCompleted,
      weeklyChallengesCompleted: weeklyChallengesCompleted ?? this.weeklyChallengesCompleted,
    );
  }
  
  /// Add currency from run rewards
  MetaProgressState addRunRewards({
    required int score,
    required int preyEaten,
    required int waveReached,
    required int bossesDefeated,
    required Duration runTime,
  }) {
    // Calculate evolution points: base + score bonus + wave bonus
    final basePoints = 10;
    final scoreBonus = score ~/ 100;
    final waveBonus = waveReached * 5;
    final bossBonus = bossesDefeated * 20;
    final pointsEarned = basePoints + scoreBonus + waveBonus + bossBonus;
    
    return copyWith(
      evolutionPoints: evolutionPoints + pointsEarned,
      totalRuns: totalRuns + 1,
      totalPreyEaten: totalPreyEaten + preyEaten,
      totalBossesDefeated: totalBossesDefeated + bossesDefeated,
      highestWaveReached: waveReached > highestWaveReached ? waveReached : highestWaveReached,
      totalPlayTime: totalPlayTime + runTime,
    );
  }
  
  /// Check if species tier should upgrade
  SpeciesTier checkTierUpgrade() {
    return SpeciesRegistry.getTierForRuns(selectedSpecies, totalRuns);
  }
  
  /// Serialization for persistence
  Map<String, dynamic> toJson() => {
    'evolutionPoints': evolutionPoints,
    'primordialEssence': primordialEssence,
    'totalRuns': totalRuns,
    'totalPreyEaten': totalPreyEaten,
    'totalBossesDefeated': totalBossesDefeated,
    'highestWaveReached': highestWaveReached,
    'highestAscension': highestAscension,
    'totalPlayTimeMs': totalPlayTime.inMilliseconds,
    'selectedSpecies': selectedSpecies.index,
    'currentTier': currentTier.index,
    'unlockedLoadouts': unlockedLoadouts.toList(),
    'completedAchievements': completedAchievements.toList(),
    'seenMutations': seenMutations.map((m) => m.index).toList(),
    'unlockedSkins': unlockedSkins.toList(),
    'lastDailyReset': lastDailyReset.toIso8601String(),
    'dailyChallengesCompleted': dailyChallengesCompleted,
    'weeklyChallengesCompleted': weeklyChallengesCompleted,
  };
  
  factory MetaProgressState.fromJson(Map<String, dynamic> json) {
    return MetaProgressState(
      evolutionPoints: json['evolutionPoints'] ?? 0,
      primordialEssence: json['primordialEssence'] ?? 0,
      totalRuns: json['totalRuns'] ?? 0,
      totalPreyEaten: json['totalPreyEaten'] ?? 0,
      totalBossesDefeated: json['totalBossesDefeated'] ?? 0,
      highestWaveReached: json['highestWaveReached'] ?? 0,
      highestAscension: json['highestAscension'] ?? 0,
      totalPlayTime: Duration(milliseconds: json['totalPlayTimeMs'] ?? 0),
      selectedSpecies: Species.values[json['selectedSpecies'] ?? 0],
      currentTier: SpeciesTier.values[json['currentTier'] ?? 0],
      unlockedLoadouts: Set<String>.from(json['unlockedLoadouts'] ?? ['default']),
      completedAchievements: Set<String>.from(json['completedAchievements'] ?? []),
      seenMutations: (json['seenMutations'] as List?)
          ?.map((i) => MutationType.values[i as int])
          .toSet() ?? {},
      unlockedSkins: Set<String>.from(json['unlockedSkins'] ?? ['default']),
      lastDailyReset: DateTime.tryParse(json['lastDailyReset'] ?? '') ?? DateTime.now(),
      dailyChallengesCompleted: json['dailyChallengesCompleted'] ?? 0,
      weeklyChallengesCompleted: json['weeklyChallengesCompleted'] ?? 0,
    );
  }
  
  factory MetaProgressState.initial() => MetaProgressState(
    lastDailyReset: DateTime.now(),
  );
}

/// Predefined achievements
class AchievementRegistry {
  static const List<Achievement> all = [
    // Combat
    Achievement(
      id: 'first_blood',
      name: 'First Blood',
      description: 'Eat your first prey',
      emoji: '🩸',
      category: AchievementCategory.combat,
      targetValue: 1,
      rewards: {MetaCurrency.evolutionPoints: 10},
    ),
    Achievement(
      id: 'predator',
      name: 'Predator',
      description: 'Eat 100 prey in a single run',
      emoji: '🦷',
      category: AchievementCategory.combat,
      targetValue: 100,
      rewards: {MetaCurrency.evolutionPoints: 50},
    ),
    Achievement(
      id: 'boss_slayer',
      name: 'Boss Slayer',
      description: 'Defeat 10 bosses',
      emoji: '👹',
      category: AchievementCategory.combat,
      targetValue: 10,
      rewards: {MetaCurrency.primordialEssence: 5},
    ),
    Achievement(
      id: 'combo_king',
      name: 'Combo King',
      description: 'Reach SSS style rating',
      emoji: '👑',
      category: AchievementCategory.combat,
      targetValue: 1,
      rewards: {MetaCurrency.primordialEssence: 10},
    ),
    
    // Survival
    Achievement(
      id: 'survivor',
      name: 'Survivor',
      description: 'Reach wave 10',
      emoji: '🏆',
      category: AchievementCategory.survival,
      targetValue: 10,
      rewards: {MetaCurrency.evolutionPoints: 30},
    ),
    Achievement(
      id: 'endurance',
      name: 'Endurance',
      description: 'Survive for 10 minutes',
      emoji: '⏱️',
      category: AchievementCategory.survival,
      targetValue: 600,
      rewards: {MetaCurrency.evolutionPoints: 40},
    ),
    Achievement(
      id: 'perfect_run',
      name: 'Perfect Run',
      description: 'Complete a wave without taking damage',
      emoji: '✨',
      category: AchievementCategory.survival,
      targetValue: 1,
      rewards: {MetaCurrency.primordialEssence: 3},
    ),
    
    // Collection
    Achievement(
      id: 'mutation_collector',
      name: 'Mutation Collector',
      description: 'See all mutations',
      emoji: '🧬',
      category: AchievementCategory.collection,
      targetValue: 18,
      rewards: {MetaCurrency.primordialEssence: 15},
    ),
    Achievement(
      id: 'species_master',
      name: 'Species Master',
      description: 'Reach Alpha tier with any species',
      emoji: '🐊',
      category: AchievementCategory.collection,
      targetValue: 1,
      rewards: {MetaCurrency.primordialEssence: 20},
    ),
    
    // Secret
    Achievement(
      id: 'pacifist',
      name: 'Pacifist',
      description: 'Complete wave 5 without eating prey',
      emoji: '☮️',
      category: AchievementCategory.secret,
      targetValue: 1,
      rewards: {MetaCurrency.primordialEssence: 25},
      isSecret: true,
    ),
  ];
  
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Predefined loadouts
class LoadoutRegistry {
  static const List<StartingLoadout> all = [
    StartingLoadout(
      id: 'default',
      name: 'Balanced',
      description: 'Standard starting loadout',
      statModifiers: {},
      unlockCost: 0,
      isUnlocked: true,
    ),
    StartingLoadout(
      id: 'speedster',
      name: 'Speedster',
      description: '+25% speed, -15% health',
      statModifiers: {'speed': 0.25, 'health': -0.15},
      unlockCost: 100,
    ),
    StartingLoadout(
      id: 'tank',
      name: 'Tank',
      description: '+40% health, -20% speed',
      statModifiers: {'health': 0.40, 'speed': -0.20},
      unlockCost: 100,
    ),
    StartingLoadout(
      id: 'berserker',
      name: 'Berserker',
      description: '+30% damage, -25% health, start with Berserker mutation',
      statModifiers: {'damage': 0.30, 'health': -0.25},
      startingMutations: [MutationType.berserker],
      unlockCost: 250,
    ),
    StartingLoadout(
      id: 'gambler',
      name: 'Gambler',
      description: '2x rewards, 2x spawn rate',
      statModifiers: {'reward': 1.0, 'spawnRate': 1.0},
      unlockCost: 200,
    ),
  ];
}
