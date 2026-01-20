/// Faction System - Prey factions and their rivalries
/// Part of PREY CHAOS redesign

import 'package:flutter/material.dart';
import 'prey.dart';

/// The 4 major prey factions
enum PreyFaction {
  /// Fruit Gang - Weak individually, swarm tactics, coin drops
  fruitGang,
  
  /// Junk Food Mafia - Tanky, slow, barricade behavior
  junkFoodMafia,
  
  /// Ninja Clan - Fast, teleport, hit & run
  ninjaClan,
  
  /// Dessert Cult - Support, buff/heal other prey
  dessertCult,
}

/// Faction behavior pattern
enum FactionBehavior {
  swarm,      // Attack in groups, surround player
  barricade,  // Block paths, tank damage
  hitAndRun,  // Quick strikes, retreat
  support,    // Buff allies, rarely attack directly
}

/// Complete faction data
class FactionData {
  final PreyFaction faction;
  final String name;
  final String description;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final FactionBehavior behavior;
  final List<PreyType> members;
  final PreyFaction rivalFaction;
  final double aggressionToPlayer;  // 0.0-1.0
  final double aggressionToRival;   // 0.0-1.0
  final bool hasLeader;
  
  const FactionData({
    required this.faction,
    required this.name,
    required this.description,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.behavior,
    required this.members,
    required this.rivalFaction,
    required this.aggressionToPlayer,
    required this.aggressionToRival,
    this.hasLeader = true,
  });
}

/// Extended prey types for the faction system
enum ExtendedPreyType {
  // ═══════════════════════════════════════════════════════════════════════════
  // FRUIT GANG (5 members + 1 boss)
  // ═══════════════════════════════════════════════════════════════════════════
  angryApple,
  berserkerBanana,
  kamikazePineapple,
  sneakyStrawberry,
  grapeGang,        // Spawns in clusters
  kingWatermelon,   // Boss - splits into smaller pieces
  
  // ═══════════════════════════════════════════════════════════════════════════
  // JUNK FOOD MAFIA (5 members + 1 boss)
  // ═══════════════════════════════════════════════════════════════════════════
  zombieBurger,
  shieldPizza,      // Blocks projectiles
  barrierBurrito,   // Creates walls
  hotdogHeavy,      // Slow but massive HP
  sodaSpewer,       // Ranged attacks
  donLasagna,       // Boss - multi-phase
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NINJA CLAN (5 members + 1 boss)
  // ═══════════════════════════════════════════════════════════════════════════
  ninjaSushi,
  shadowRamen,      // Teleports
  blinkTempura,     // Dashes
  smokebombMochi,   // Creates vision blockers
  shurikenSashimi,  // Ranged
  senseiSamurai,    // Boss - sword patterns
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DESSERT CULT (5 members + 1 boss)
  // ═══════════════════════════════════════════════════════════════════════════
  healerCake,       // Heals nearby allies
  speedBuffIceCream,// Speed aura
  revivePudding,    // Resurrects fallen prey
  shieldDonut,      // Barrier spell
  ghostPizza,       // Phase through obstacles
  archbishopCroissant, // Boss - summons minions
}

/// Central faction registry
class FactionRegistry {
  static const Map<PreyFaction, FactionData> _data = {
    PreyFaction.fruitGang: FactionData(
      faction: PreyFaction.fruitGang,
      name: 'Fruit Gang',
      description: 'Weak but numerous. Strength in numbers.',
      emoji: '🍎',
      primaryColor: Color(0xFFE53935),
      secondaryColor: Color(0xFFFFEB3B),
      behavior: FactionBehavior.swarm,
      members: [PreyType.angryApple],
      rivalFaction: PreyFaction.junkFoodMafia,
      aggressionToPlayer: 0.7,
      aggressionToRival: 0.8,
    ),
    PreyFaction.junkFoodMafia: FactionData(
      faction: PreyFaction.junkFoodMafia,
      name: 'Junk Food Mafia',
      description: 'Slow but devastating. Controls territory.',
      emoji: '🍔',
      primaryColor: Color(0xFFF57C00),
      secondaryColor: Color(0xFF795548),
      behavior: FactionBehavior.barricade,
      members: [PreyType.zombieBurger],
      rivalFaction: PreyFaction.fruitGang,
      aggressionToPlayer: 0.5,
      aggressionToRival: 0.9,
    ),
    PreyFaction.ninjaClan: FactionData(
      faction: PreyFaction.ninjaClan,
      name: 'Ninja Clan',
      description: 'Silent. Deadly. Untraceable.',
      emoji: '🍣',
      primaryColor: Color(0xFF1A237E),
      secondaryColor: Color(0xFF9C27B0),
      behavior: FactionBehavior.hitAndRun,
      members: [PreyType.ninjaSushi],
      rivalFaction: PreyFaction.dessertCult,
      aggressionToPlayer: 0.9,
      aggressionToRival: 0.6,
    ),
    PreyFaction.dessertCult: FactionData(
      faction: PreyFaction.dessertCult,
      name: 'Dessert Cult',
      description: 'Support their allies. Never fight alone.',
      emoji: '🍰',
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFFFFFFFF),
      behavior: FactionBehavior.support,
      members: [PreyType.goldenCake, PreyType.ghostPizza],
      rivalFaction: PreyFaction.ninjaClan,
      aggressionToPlayer: 0.3,
      aggressionToRival: 0.4,
    ),
  };

  static FactionData get(PreyFaction faction) => _data[faction]!;
  
  static PreyFaction? getFactionFor(PreyType type) {
    for (final data in _data.values) {
      if (data.members.contains(type)) return data.faction;
    }
    return null;
  }
  
  static bool areRivals(PreyFaction a, PreyFaction b) =>
      _data[a]!.rivalFaction == b || _data[b]!.rivalFaction == a;
  
  static List<FactionData> get all => _data.values.toList();
}

/// Faction combat state tracking
class FactionWarState {
  final Map<PreyFaction, double> factionStrength; // 0.0-1.0
  final PreyFaction? dominantFaction;
  final int totalFactionKills;
  final Map<PreyFaction, int> leaderAlive; // 0 = dead, 1 = alive
  
  const FactionWarState({
    this.factionStrength = const {
      PreyFaction.fruitGang: 1.0,
      PreyFaction.junkFoodMafia: 1.0,
      PreyFaction.ninjaClan: 1.0,
      PreyFaction.dessertCult: 1.0,
    },
    this.dominantFaction,
    this.totalFactionKills = 0,
    this.leaderAlive = const {
      PreyFaction.fruitGang: 1,
      PreyFaction.junkFoodMafia: 1,
      PreyFaction.ninjaClan: 1,
      PreyFaction.dessertCult: 1,
    },
  });
  
  FactionWarState copyWith({
    Map<PreyFaction, double>? factionStrength,
    PreyFaction? dominantFaction,
    int? totalFactionKills,
    Map<PreyFaction, int>? leaderAlive,
  }) {
    return FactionWarState(
      factionStrength: factionStrength ?? this.factionStrength,
      dominantFaction: dominantFaction ?? this.dominantFaction,
      totalFactionKills: totalFactionKills ?? this.totalFactionKills,
      leaderAlive: leaderAlive ?? this.leaderAlive,
    );
  }
  
  /// When a faction leader dies, faction becomes weaker
  FactionWarState onLeaderDeath(PreyFaction faction) {
    final newStrength = Map<PreyFaction, double>.from(factionStrength);
    newStrength[faction] = (newStrength[faction]! * 0.5).clamp(0.0, 1.0);
    
    final newLeaders = Map<PreyFaction, int>.from(leaderAlive);
    newLeaders[faction] = 0;
    
    return copyWith(
      factionStrength: newStrength,
      leaderAlive: newLeaders,
    );
  }
  
  /// Calculate which faction is currently dominant
  PreyFaction? calculateDominant() {
    PreyFaction? strongest;
    double maxStrength = 0.0;
    
    for (final entry in factionStrength.entries) {
      if (entry.value > maxStrength) {
        maxStrength = entry.value;
        strongest = entry.key;
      }
    }
    
    // Need at least 0.4 strength difference to be dominant
    final others = factionStrength.values.where((v) => v != maxStrength);
    if (others.isEmpty) return null;
    final secondHighest = others.reduce((a, b) => a > b ? a : b);
    
    return (maxStrength - secondHighest) >= 0.4 ? strongest : null;
  }
}
