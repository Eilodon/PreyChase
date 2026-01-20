/// Biome System - Dynamic arenas with unique effects
/// Part of PREY CHAOS redesign

import 'package:flutter/material.dart';

/// Arena biome types
enum BiomeType {
  /// Starting biome - forgiving, water-based
  swampStart,
  
  /// Fire hazards, damage zones
  lavaField,
  
  /// Slippery movement, freeze effects
  iceTundra,
  
  /// Teleport portals, gravity anomalies
  voidRift,
}

/// Environmental effects within biomes
enum EnvironmentEffect {
  // Swamp
  muddyGround,    // -20% speed in mud
  healingPools,   // Regen zones
  
  // Lava
  damageZones,    // Constant damage
  eruptingGeysers,// Periodic explosions
  
  // Ice
  slipperyFloor,  // Momentum-based movement
  freezeBlast,    // Periodic freeze waves
  
  // Void
  gravityWells,   // Pull toward center
  blinkPortals,   // Teleport player/prey
  voidStorm,      // Random teleportation
}

/// Arena hazard types
enum HazardType {
  meteor,         // Falling damage zones
  flood,          // Rising water/lava
  earthquake,     // Crumbling platforms
  storm,          // Vision obstruction + random damage
  vortex,         // Pull everything to center
}

/// Complete biome data
class BiomeData {
  final BiomeType type;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color ambientLight;
  final List<EnvironmentEffect> effects;
  final double damageMultiplier;
  final double speedMultiplier;
  final double visibilityMultiplier;
  final int unlockedAtWave;
  
  const BiomeData({
    required this.type,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.ambientLight,
    required this.effects,
    this.damageMultiplier = 1.0,
    this.speedMultiplier = 1.0,
    this.visibilityMultiplier = 1.0,
    this.unlockedAtWave = 1,
  });
}

/// Biome registry
class BiomeRegistry {
  static const Map<BiomeType, BiomeData> _biomes = {
    BiomeType.swampStart: BiomeData(
      type: BiomeType.swampStart,
      name: 'Murky Swamp',
      description: 'Where our journey begins. Muddy but safe.',
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFF1B5E20),
      ambientLight: Color(0x4081C784),
      effects: [EnvironmentEffect.muddyGround, EnvironmentEffect.healingPools],
      speedMultiplier: 0.9,
      unlockedAtWave: 1,
    ),
    BiomeType.lavaField: BiomeData(
      type: BiomeType.lavaField,
      name: 'Volcanic Fields',
      description: 'Fiery wasteland. Watch your step.',
      primaryColor: Color(0xFFD84315),
      secondaryColor: Color(0xFFBF360C),
      ambientLight: Color(0x40FF5722),
      effects: [EnvironmentEffect.damageZones, EnvironmentEffect.eruptingGeysers],
      damageMultiplier: 1.25,
      unlockedAtWave: 5,
    ),
    BiomeType.iceTundra: BiomeData(
      type: BiomeType.iceTundra,
      name: 'Frozen Tundra',
      description: 'Treacherous ice. Momentum is key.',
      primaryColor: Color(0xFF4FC3F7),
      secondaryColor: Color(0xFF0288D1),
      ambientLight: Color(0x4081D4FA),
      effects: [EnvironmentEffect.slipperyFloor, EnvironmentEffect.freezeBlast],
      speedMultiplier: 1.3, // Faster but harder to control
      unlockedAtWave: 10,
    ),
    BiomeType.voidRift: BiomeData(
      type: BiomeType.voidRift,
      name: 'Void Rift',
      description: 'Reality breaks. Trust nothing.',
      primaryColor: Color(0xFF7C4DFF),
      secondaryColor: Color(0xFF311B92),
      ambientLight: Color(0x40B388FF),
      effects: [EnvironmentEffect.gravityWells, EnvironmentEffect.blinkPortals, EnvironmentEffect.voidStorm],
      visibilityMultiplier: 0.7,
      damageMultiplier: 1.5,
      unlockedAtWave: 15,
    ),
  };
  
  static BiomeData get(BiomeType type) => _biomes[type]!;
  
  static List<BiomeData> get all => _biomes.values.toList();
  
  static BiomeData forWave(int wave) {
    // Progress through biomes as waves advance
    if (wave >= 15) return _biomes[BiomeType.voidRift]!;
    if (wave >= 10) return _biomes[BiomeType.iceTundra]!;
    if (wave >= 5) return _biomes[BiomeType.lavaField]!;
    return _biomes[BiomeType.swampStart]!;
  }
}

/// Active hazard during gameplay
class ActiveHazard {
  final String id;
  final HazardType type;
  final double x;
  final double y;
  final double radius;
  final double remainingDuration;
  final double damage;
  
  const ActiveHazard({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.radius,
    required this.remainingDuration,
    this.damage = 10.0,
  });
  
  ActiveHazard tick(double dt) => ActiveHazard(
    id: id,
    type: type,
    x: x,
    y: y,
    radius: radius,
    remainingDuration: remainingDuration - dt,
    damage: damage,
  );
  
  bool get isExpired => remainingDuration <= 0;
}

/// Biome state during gameplay
class BiomeState {
  final BiomeType currentBiome;
  final BiomeType? transitioningTo;
  final double transitionProgress; // 0.0 - 1.0
  final List<ActiveHazard> activeHazards;
  final double hazardSpawnTimer;
  
  const BiomeState({
    this.currentBiome = BiomeType.swampStart,
    this.transitioningTo,
    this.transitionProgress = 0.0,
    this.activeHazards = const [],
    this.hazardSpawnTimer = 0.0,
  });
  
  BiomeData get data => BiomeRegistry.get(currentBiome);
  
  BiomeState copyWith({
    BiomeType? currentBiome,
    BiomeType? transitioningTo,
    double? transitionProgress,
    List<ActiveHazard>? activeHazards,
    double? hazardSpawnTimer,
  }) {
    return BiomeState(
      currentBiome: currentBiome ?? this.currentBiome,
      transitioningTo: transitioningTo ?? this.transitioningTo,
      transitionProgress: transitionProgress ?? this.transitionProgress,
      activeHazards: activeHazards ?? this.activeHazards,
      hazardSpawnTimer: hazardSpawnTimer ?? this.hazardSpawnTimer,
    );
  }
}
