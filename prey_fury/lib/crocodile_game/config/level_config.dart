import '../../kernel/models/prey.dart';

/// Spawn weight table for prey types
class PreySpawnTable {
  final Map<PreyType, double> weights;
  
  const PreySpawnTable(this.weights);
  
  /// Default table for level 1
  static const level1 = PreySpawnTable({
    PreyType.angryApple: 0.50,
    PreyType.zombieBurger: 0.35,
    PreyType.ninjaSushi: 0.10,
    PreyType.ghostPizza: 0.05,
    PreyType.goldenCake: 0.00,
  });
  
  static const level2 = PreySpawnTable({
    PreyType.angryApple: 0.40,
    PreyType.zombieBurger: 0.30,
    PreyType.ninjaSushi: 0.20,
    PreyType.ghostPizza: 0.10,
    PreyType.goldenCake: 0.00,
  });
  
  static const level3 = PreySpawnTable({
    PreyType.angryApple: 0.30,
    PreyType.zombieBurger: 0.25,
    PreyType.ninjaSushi: 0.25,
    PreyType.ghostPizza: 0.15,
    PreyType.goldenCake: 0.05,
  });
  
  static const level4 = PreySpawnTable({
    PreyType.angryApple: 0.20,
    PreyType.zombieBurger: 0.20,
    PreyType.ninjaSushi: 0.30,
    PreyType.ghostPizza: 0.20,
    PreyType.goldenCake: 0.10,
  });
  
  static const level5 = PreySpawnTable({
    PreyType.angryApple: 0.15,
    PreyType.zombieBurger: 0.15,
    PreyType.ninjaSushi: 0.30,
    PreyType.ghostPizza: 0.25,
    PreyType.goldenCake: 0.15,
  });
  
  static const endless = PreySpawnTable({
    PreyType.angryApple: 0.15,
    PreyType.zombieBurger: 0.20,
    PreyType.ninjaSushi: 0.25,
    PreyType.ghostPizza: 0.25,
    PreyType.goldenCake: 0.15,
  });
}

/// Obstacle spawn configuration
class ObstacleSpawnConfig {
  final int rockCount;
  final int spikeCount;
  final int mudCount;
  final int speedBoostCount;
  final int whirlpoolCount;
  final int healingPoolCount;
  final int portalPairs;
  
  const ObstacleSpawnConfig({
    this.rockCount = 5,
    this.spikeCount = 0,
    this.mudCount = 0,
    this.speedBoostCount = 0,
    this.whirlpoolCount = 0,
    this.healingPoolCount = 0,
    this.portalPairs = 0,
  });
  
  static const level1 = ObstacleSpawnConfig(
    rockCount: 8,
    spikeCount: 0,
    mudCount: 2,
    speedBoostCount: 2,
  );
  
  static const level2 = ObstacleSpawnConfig(
    rockCount: 10,
    spikeCount: 3,
    mudCount: 3,
    speedBoostCount: 2,
    whirlpoolCount: 1,
  );
  
  static const level3 = ObstacleSpawnConfig(
    rockCount: 8,
    spikeCount: 5,
    mudCount: 4,
    speedBoostCount: 3,
    whirlpoolCount: 2,
    healingPoolCount: 1,
  );
  
  static const level4 = ObstacleSpawnConfig(
    rockCount: 6,
    spikeCount: 8,
    mudCount: 5,
    speedBoostCount: 4,
    whirlpoolCount: 3,
    healingPoolCount: 2,
    portalPairs: 1,
  );
  
  static const level5 = ObstacleSpawnConfig(
    rockCount: 5,
    spikeCount: 10,
    mudCount: 6,
    speedBoostCount: 5,
    whirlpoolCount: 4,
    healingPoolCount: 2,
    portalPairs: 2,
  );
}

/// Wave difficulty pattern (oscillating)
enum WavePattern {
  easy,     // Low spawn rate, slow prey
  medium,   // Normal
  spike,    // Pack attack, fast spawn
  breather, // Fewer enemies, healing pool active
  boss,     // Boss spawn + minions
}

/// Single wave configuration
class WaveConfig {
  final WavePattern pattern;
  final double duration;  // Seconds
  final int maxPreyCount;
  final double spawnInterval;
  final bool spawnBoss;
  
  const WaveConfig({
    required this.pattern,
    required this.duration,
    required this.maxPreyCount,
    required this.spawnInterval,
    this.spawnBoss = false,
  });
}

/// Complete level configuration
class LevelConfig {
  final int levelId;
  final String name;
  final double timeLimit;      // Total seconds for level
  final int targetScore;       // Win condition: reach this score
  final int targetPreyEaten;   // Alt win condition: eat this many
  final List<WaveConfig> waves;
  final PreySpawnTable spawnTable;
  final ObstacleSpawnConfig obstacles;
  final double preySpeedMultiplier;
  final double preyHealthMultiplier;
  final int bossHealth;
  
  const LevelConfig({
    required this.levelId,
    required this.name,
    required this.timeLimit,
    required this.targetScore,
    required this.targetPreyEaten,
    required this.waves,
    required this.spawnTable,
    required this.obstacles,
    this.preySpeedMultiplier = 1.0,
    this.preyHealthMultiplier = 1.0,
    this.bossHealth = 5,
  });
  
  /// All level configurations
  static const List<LevelConfig> allLevels = [
    level1,
    level2,
    level3,
    level4,
    level5,
  ];
  
  static const level1 = LevelConfig(
    levelId: 1,
    name: "Swamp Intro",
    timeLimit: 60.0,
    targetScore: 200,
    targetPreyEaten: 15,
    preySpeedMultiplier: 0.8,
    bossHealth: 5,
    spawnTable: PreySpawnTable.level1,
    obstacles: ObstacleSpawnConfig.level1,
    waves: [
      WaveConfig(pattern: WavePattern.easy, duration: 15, maxPreyCount: 5, spawnInterval: 2.5),
      WaveConfig(pattern: WavePattern.medium, duration: 15, maxPreyCount: 7, spawnInterval: 2.0),
      WaveConfig(pattern: WavePattern.spike, duration: 10, maxPreyCount: 10, spawnInterval: 1.5),
      WaveConfig(pattern: WavePattern.breather, duration: 10, maxPreyCount: 4, spawnInterval: 3.0),
      WaveConfig(pattern: WavePattern.boss, duration: 10, maxPreyCount: 6, spawnInterval: 2.0, spawnBoss: true),
    ],
  );
  
  static const level2 = LevelConfig(
    levelId: 2,
    name: "Murky Waters",
    timeLimit: 75.0,
    targetScore: 400,
    targetPreyEaten: 25,
    preySpeedMultiplier: 1.0,
    bossHealth: 8,
    spawnTable: PreySpawnTable.level2,
    obstacles: ObstacleSpawnConfig.level2,
    waves: [
      WaveConfig(pattern: WavePattern.easy, duration: 12, maxPreyCount: 6, spawnInterval: 2.0),
      WaveConfig(pattern: WavePattern.medium, duration: 15, maxPreyCount: 8, spawnInterval: 1.8),
      WaveConfig(pattern: WavePattern.spike, duration: 12, maxPreyCount: 12, spawnInterval: 1.2),
      WaveConfig(pattern: WavePattern.medium, duration: 12, maxPreyCount: 8, spawnInterval: 1.8),
      WaveConfig(pattern: WavePattern.spike, duration: 10, maxPreyCount: 14, spawnInterval: 1.0),
      WaveConfig(pattern: WavePattern.breather, duration: 8, maxPreyCount: 4, spawnInterval: 3.0),
      WaveConfig(pattern: WavePattern.boss, duration: 12, maxPreyCount: 8, spawnInterval: 1.5, spawnBoss: true),
    ],
  );
  
  static const level3 = LevelConfig(
    levelId: 3,
    name: "Ghost Bayou",
    timeLimit: 90.0,
    targetScore: 600,
    targetPreyEaten: 35,
    preySpeedMultiplier: 1.1,
    preyHealthMultiplier: 1.5,
    bossHealth: 12,
    spawnTable: PreySpawnTable.level3,
    obstacles: ObstacleSpawnConfig.level3,
    waves: [
      WaveConfig(pattern: WavePattern.medium, duration: 12, maxPreyCount: 8, spawnInterval: 1.8),
      WaveConfig(pattern: WavePattern.spike, duration: 10, maxPreyCount: 12, spawnInterval: 1.2),
      WaveConfig(pattern: WavePattern.breather, duration: 8, maxPreyCount: 5, spawnInterval: 2.5),
      WaveConfig(pattern: WavePattern.spike, duration: 12, maxPreyCount: 15, spawnInterval: 1.0),
      WaveConfig(pattern: WavePattern.medium, duration: 12, maxPreyCount: 10, spawnInterval: 1.5),
      WaveConfig(pattern: WavePattern.spike, duration: 10, maxPreyCount: 18, spawnInterval: 0.8),
      WaveConfig(pattern: WavePattern.breather, duration: 8, maxPreyCount: 4, spawnInterval: 3.0),
      WaveConfig(pattern: WavePattern.boss, duration: 15, maxPreyCount: 10, spawnInterval: 1.2, spawnBoss: true),
    ],
  );
  
  static const level4 = LevelConfig(
    levelId: 4,
    name: "Ninja Marshlands",
    timeLimit: 90.0,
    targetScore: 900,
    targetPreyEaten: 45,
    preySpeedMultiplier: 1.2,
    preyHealthMultiplier: 2.0,
    bossHealth: 15,
    spawnTable: PreySpawnTable.level4,
    obstacles: ObstacleSpawnConfig.level4,
    waves: [
      WaveConfig(pattern: WavePattern.spike, duration: 10, maxPreyCount: 10, spawnInterval: 1.5),
      WaveConfig(pattern: WavePattern.medium, duration: 12, maxPreyCount: 12, spawnInterval: 1.2),
      WaveConfig(pattern: WavePattern.spike, duration: 12, maxPreyCount: 16, spawnInterval: 0.8),
      WaveConfig(pattern: WavePattern.breather, duration: 8, maxPreyCount: 5, spawnInterval: 2.5),
      WaveConfig(pattern: WavePattern.spike, duration: 12, maxPreyCount: 18, spawnInterval: 0.7),
      WaveConfig(pattern: WavePattern.spike, duration: 10, maxPreyCount: 20, spawnInterval: 0.6),
      WaveConfig(pattern: WavePattern.breather, duration: 8, maxPreyCount: 4, spawnInterval: 3.0),
      WaveConfig(pattern: WavePattern.boss, duration: 18, maxPreyCount: 12, spawnInterval: 1.0, spawnBoss: true),
    ],
  );
  
  static const level5 = LevelConfig(
    levelId: 5,
    name: "Crocodile's Lair",
    timeLimit: 120.0,
    targetScore: 1500,
    targetPreyEaten: 60,
    preySpeedMultiplier: 1.3,
    preyHealthMultiplier: 3.0,
    bossHealth: 20,
    spawnTable: PreySpawnTable.level5,
    obstacles: ObstacleSpawnConfig.level5,
    waves: [
      WaveConfig(pattern: WavePattern.spike, duration: 12, maxPreyCount: 12, spawnInterval: 1.2),
      WaveConfig(pattern: WavePattern.spike, duration: 12, maxPreyCount: 16, spawnInterval: 0.8),
      WaveConfig(pattern: WavePattern.medium, duration: 10, maxPreyCount: 14, spawnInterval: 1.0),
      WaveConfig(pattern: WavePattern.spike, duration: 12, maxPreyCount: 20, spawnInterval: 0.6),
      WaveConfig(pattern: WavePattern.breather, duration: 10, maxPreyCount: 6, spawnInterval: 2.0),
      WaveConfig(pattern: WavePattern.spike, duration: 15, maxPreyCount: 22, spawnInterval: 0.5),
      WaveConfig(pattern: WavePattern.spike, duration: 12, maxPreyCount: 25, spawnInterval: 0.4),
      WaveConfig(pattern: WavePattern.breather, duration: 10, maxPreyCount: 5, spawnInterval: 2.5),
      WaveConfig(pattern: WavePattern.boss, duration: 25, maxPreyCount: 15, spawnInterval: 0.8, spawnBoss: true),
    ],
  );
  
  /// Endless mode config generator
  static LevelConfig endless(int waveNumber) {
    final scaling = 1.0 + (waveNumber * 0.05);
    return LevelConfig(
      levelId: 100 + waveNumber,
      name: "Endless Wave $waveNumber",
      timeLimit: double.infinity,
      targetScore: 999999,
      targetPreyEaten: 999999,
      preySpeedMultiplier: scaling,
      preyHealthMultiplier: 1.0 + (waveNumber ~/ 5) * 0.5,
      bossHealth: 5 + (waveNumber ~/ 3) * 3,
      spawnTable: PreySpawnTable.endless,
      obstacles: ObstacleSpawnConfig.level5,
      waves: [
        WaveConfig(
          pattern: waveNumber % 5 == 0 ? WavePattern.boss : 
                   waveNumber % 3 == 0 ? WavePattern.spike : WavePattern.medium,
          duration: 30.0,
          maxPreyCount: 10 + (waveNumber * 2),
          spawnInterval: (2.0 / scaling).clamp(0.3, 2.0),
          spawnBoss: waveNumber % 5 == 0,
        ),
      ],
    );
  }
}
