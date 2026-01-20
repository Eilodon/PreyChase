/// Wave Event System - Dynamic challenges and opportunities
/// Part of PREY CHAOS redesign

import 'package:flutter/material.dart';

/// Types of wave events
enum WaveEventType {
  // ═══════════════════════════════════════════════════════════════════════════
  // CHALLENGES (make game harder temporarily)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// No food spawns for 30 seconds
  foodDrought,
  
  /// Triple spawn rate
  preyRush,
  
  /// 5 elite mini-bosses spawn
  elitePack,
  
  /// Reduced visibility (fog of war)
  darkZone,
  
  /// All prey gain +50% speed
  preyFrenzy,
  
  /// Boss enters enraged mode
  enragedBoss,

  // ═══════════════════════════════════════════════════════════════════════════
  // OPPORTUNITIES (rewards for skilled play)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// 5x coin drops
  goldRush,
  
  /// Random mutations appear as pickups
  mutationRain,
  
  /// Slow-mo zones appear
  timeSlowZone,
  
  /// Healing springs activate
  healingSpring,
  
  /// Double fury generation
  furyBoost,

  // ═══════════════════════════════════════════════════════════════════════════
  // BOSS PHASES (special boss mechanics)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Boss HP < 50% triggers berserk
  bossEnrage,
  
  /// Boss summons 20 minions
  minionSummon,
  
  /// Arena transforms mid-fight
  arenaTransform,
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FACTION EVENTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Two factions start fighting each other
  factionWar,
  
  /// Faction leader appears
  leaderSpawn,
}

/// Event category for filtering
enum WaveEventCategory {
  challenge,
  opportunity,
  bossPhase,
  faction,
}

/// Complete wave event data
class WaveEvent {
  final WaveEventType type;
  final String name;
  final String announcement; // "⚡ PREY RUSH INCOMING!"
  final String description;
  final Color color;
  final WaveEventCategory category;
  final double duration; // Seconds, 0 = instant
  final double modifier; // Event-specific value
  
  const WaveEvent({
    required this.type,
    required this.name,
    required this.announcement,
    required this.description,
    required this.color,
    required this.category,
    required this.duration,
    this.modifier = 1.0,
  });
}

/// Central wave event registry
class WaveEventRegistry {
  static const Map<WaveEventType, WaveEvent> _events = {
    // CHALLENGES
    WaveEventType.foodDrought: WaveEvent(
      type: WaveEventType.foodDrought,
      name: 'Food Drought',
      announcement: '🏜️ FOOD DROUGHT!',
      description: 'No food for 30 seconds. Hunt prey to survive!',
      color: Color(0xFFFF9800),
      category: WaveEventCategory.challenge,
      duration: 30.0,
    ),
    WaveEventType.preyRush: WaveEvent(
      type: WaveEventType.preyRush,
      name: 'Prey Rush',
      announcement: '⚡ PREY RUSH!',
      description: 'Triple spawn rate! Survive the swarm!',
      color: Color(0xFFF44336),
      category: WaveEventCategory.challenge,
      duration: 20.0,
      modifier: 3.0,
    ),
    WaveEventType.elitePack: WaveEvent(
      type: WaveEventType.elitePack,
      name: 'Elite Pack',
      announcement: '👹 ELITE PACK!',
      description: '5 mini-bosses approach!',
      color: Color(0xFF9C27B0),
      category: WaveEventCategory.challenge,
      duration: 0.0, // Instant spawn
      modifier: 5.0,
    ),
    WaveEventType.darkZone: WaveEvent(
      type: WaveEventType.darkZone,
      name: 'Dark Zone',
      announcement: '🌑 DARKNESS FALLS',
      description: 'Visibility reduced to 30%',
      color: Color(0xFF212121),
      category: WaveEventCategory.challenge,
      duration: 25.0,
      modifier: 0.3,
    ),
    WaveEventType.preyFrenzy: WaveEvent(
      type: WaveEventType.preyFrenzy,
      name: 'Prey Frenzy',
      announcement: '💨 PREY FRENZY!',
      description: 'All prey gain +50% speed!',
      color: Color(0xFF03A9F4),
      category: WaveEventCategory.challenge,
      duration: 15.0,
      modifier: 1.5,
    ),
    WaveEventType.enragedBoss: WaveEvent(
      type: WaveEventType.enragedBoss,
      name: 'Boss Enrage',
      announcement: '😡 BOSS ENRAGED!',
      description: 'Boss HP < 50%! Attack patterns intensify!',
      color: Color(0xFFD50000),
      category: WaveEventCategory.bossPhase,
      duration: 0.0, // Until boss dies
    ),
    
    // OPPORTUNITIES
    WaveEventType.goldRush: WaveEvent(
      type: WaveEventType.goldRush,
      name: 'Gold Rush',
      announcement: '💰 GOLD RUSH!',
      description: '5x coin drops! Time to feast!',
      color: Color(0xFFFFD700),
      category: WaveEventCategory.opportunity,
      duration: 15.0,
      modifier: 5.0,
    ),
    WaveEventType.mutationRain: WaveEvent(
      type: WaveEventType.mutationRain,
      name: 'Mutation Rain',
      announcement: '🧬 MUTATION RAIN!',
      description: 'Mutation pickups falling from the sky!',
      color: Color(0xFF7C4DFF),
      category: WaveEventCategory.opportunity,
      duration: 10.0,
    ),
    WaveEventType.timeSlowZone: WaveEvent(
      type: WaveEventType.timeSlowZone,
      name: 'Time Slow',
      announcement: '⏱️ TIME DISTORTION',
      description: 'Slow-motion zones appear!',
      color: Color(0xFF00BCD4),
      category: WaveEventCategory.opportunity,
      duration: 20.0,
      modifier: 0.5,
    ),
    WaveEventType.healingSpring: WaveEvent(
      type: WaveEventType.healingSpring,
      name: 'Healing Springs',
      announcement: '💚 HEALING SPRINGS',
      description: 'Healing zones activated!',
      color: Color(0xFF4CAF50),
      category: WaveEventCategory.opportunity,
      duration: 15.0,
    ),
    WaveEventType.furyBoost: WaveEvent(
      type: WaveEventType.furyBoost,
      name: 'Fury Boost',
      announcement: '🔥 FURY SURGE!',
      description: 'Double fury generation!',
      color: Color(0xFFFF5722),
      category: WaveEventCategory.opportunity,
      duration: 12.0,
      modifier: 2.0,
    ),
    
    // BOSS PHASES
    WaveEventType.bossEnrage: WaveEvent(
      type: WaveEventType.bossEnrage,
      name: 'Boss Enrage',
      announcement: '💀 FINAL PHASE!',
      description: 'Boss becomes enraged!',
      color: Color(0xFFB71C1C),
      category: WaveEventCategory.bossPhase,
      duration: 0.0,
    ),
    WaveEventType.minionSummon: WaveEvent(
      type: WaveEventType.minionSummon,
      name: 'Minion Summon',
      announcement: '👻 MINIONS INCOMING!',
      description: 'Boss summons 20 minions!',
      color: Color(0xFF673AB7),
      category: WaveEventCategory.bossPhase,
      duration: 0.0,
      modifier: 20.0,
    ),
    WaveEventType.arenaTransform: WaveEvent(
      type: WaveEventType.arenaTransform,
      name: 'Arena Transform',
      announcement: '🌋 ARENA SHIFT!',
      description: 'The battlefield transforms!',
      color: Color(0xFFE65100),
      category: WaveEventCategory.bossPhase,
      duration: 0.0,
    ),
    
    // FACTION EVENTS
    WaveEventType.factionWar: WaveEvent(
      type: WaveEventType.factionWar,
      name: 'Faction War',
      announcement: '⚔️ FACTION WAR!',
      description: 'Two factions are fighting! Exploit the chaos!',
      color: Color(0xFF795548),
      category: WaveEventCategory.faction,
      duration: 30.0,
    ),
    WaveEventType.leaderSpawn: WaveEvent(
      type: WaveEventType.leaderSpawn,
      name: 'Leader Spawn',
      announcement: '👑 FACTION LEADER!',
      description: 'A faction leader has appeared!',
      color: Color(0xFFFFC107),
      category: WaveEventCategory.faction,
      duration: 0.0,
    ),
  };
  
  static WaveEvent get(WaveEventType type) => _events[type]!;
  
  static List<WaveEvent> byCategory(WaveEventCategory category) =>
      _events.values.where((e) => e.category == category).toList();
  
  static List<WaveEvent> get challenges =>
      byCategory(WaveEventCategory.challenge);
  
  static List<WaveEvent> get opportunities =>
      byCategory(WaveEventCategory.opportunity);
}

/// Active event state during gameplay
class ActiveWaveEvent {
  final WaveEventType type;
  final double remainingDuration;
  final double originalDuration;
  final int triggerWave;
  
  const ActiveWaveEvent({
    required this.type,
    required this.remainingDuration,
    required this.originalDuration,
    required this.triggerWave,
  });
  
  bool get isExpired => remainingDuration <= 0 && originalDuration > 0;
  double get progress => originalDuration > 0 
      ? 1.0 - (remainingDuration / originalDuration) 
      : 1.0;
  
  ActiveWaveEvent tick(double dt) => ActiveWaveEvent(
    type: type,
    remainingDuration: remainingDuration - dt,
    originalDuration: originalDuration,
    triggerWave: triggerWave,
  );
}
