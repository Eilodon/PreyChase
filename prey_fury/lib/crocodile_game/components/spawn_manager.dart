import 'dart:math';
import 'package:flame/components.dart';
import '../../kernel/models/prey.dart';
import '../config/level_config.dart';
import 'fury_world.dart';
import 'prey_component.dart';
import 'obstacle_component.dart';

/// Zone for balanced spawning (3x3 grid)
class SpawnZone {
  final int x, y;
  final Vector2 min, max;
  int preyCount = 0;
  
  SpawnZone(this.x, this.y, this.min, this.max);
  
  Vector2 randomPoint(Random rnd) {
    return Vector2(
      min.x + rnd.nextDouble() * (max.x - min.x),
      min.y + rnd.nextDouble() * (max.y - min.y),
    );
  }
  
  bool contains(Vector2 pos) {
    return pos.x >= min.x && pos.x < max.x && pos.y >= min.y && pos.y < max.y;
  }
}

class SpawnManager extends Component with HasWorldReference<FuryWorld> {
  final Random _rnd = Random();
  
  // Timers
  double _spawnTimer = 0.0;
  double _waveTimer = 0.0;
  double _levelTimer = 0.0;
  
  // Level state
  late LevelConfig _levelConfig;
  int _currentWaveIndex = 0;
  bool _bossSpawned = false;
  int _preysEatenThisLevel = 0;
  
  // Zone-based spawning (3x3 grid)
  late List<SpawnZone> _zones;
  static const double arenaSize = 900.0;
  
  SpawnManager();
  
  @override
  Future<void> onLoad() async {
    _initZones();
    loadLevel(1); // Start with level 1
  }
  
  void _initZones() {
    _zones = [];
    final zoneSize = arenaSize * 2 / 3;
    
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        _zones.add(SpawnZone(
          x, y,
          Vector2(-arenaSize + x * zoneSize, -arenaSize + y * zoneSize),
          Vector2(-arenaSize + (x + 1) * zoneSize, -arenaSize + (y + 1) * zoneSize),
        ));
      }
    }
  }
  
  void loadLevel(int levelId) {
    if (levelId <= LevelConfig.allLevels.length) {
      _levelConfig = LevelConfig.allLevels[levelId - 1];
    } else {
      // Endless mode
      _levelConfig = LevelConfig.endless(levelId - LevelConfig.allLevels.length);
    }
    
    _currentWaveIndex = 0;
    _waveTimer = 0;
    _levelTimer = 0;
    _spawnTimer = 0;
    _bossSpawned = false;
    _preysEatenThisLevel = 0;
    
    // Clear existing prey
    world.children.whereType<PreyComponent>().forEach((p) => p.removeFromParent());
    
    // Spawn obstacles based on level config
    _spawnObstacles();
    
    // Notify world of new level
    world.onLevelStart?.call(_levelConfig.levelId, _levelConfig.name);
  }
  
  void _spawnObstacles() {
    // Clear existing obstacles
    world.children.whereType<ObstacleComponent>().forEach((o) => o.removeFromParent());
    
    final config = _levelConfig.obstacles;
    
    // Spawn each type
    _spawnObstacleType(ObstacleType.rock, config.rockCount);
    _spawnObstacleType(ObstacleType.spike, config.spikeCount);
    _spawnObstacleType(ObstacleType.mud, config.mudCount);
    _spawnObstacleType(ObstacleType.speedBoost, config.speedBoostCount);
    _spawnObstacleType(ObstacleType.whirlpool, config.whirlpoolCount);
    _spawnObstacleType(ObstacleType.healingPool, config.healingPoolCount);
    
    // Portal pairs
    for (int i = 0; i < config.portalPairs; i++) {
      final pos1 = _getBalancedSpawnPos(minDistFromPlayer: 200);
      final pos2 = _getBalancedSpawnPos(minDistFromPlayer: 200);
      
      final portal1 = ObstacleComponent(type: ObstacleType.portal, position: pos1);
      final portal2 = ObstacleComponent(type: ObstacleType.portal, position: pos2);
      portal1.pairedPortal = portal2;
      portal2.pairedPortal = portal1;
      
      world.add(portal1);
      world.add(portal2);
    }
  }
  
  void _spawnObstacleType(ObstacleType type, int count) {
    for (int i = 0; i < count; i++) {
      final pos = _getBalancedSpawnPos(minDistFromPlayer: 150);
      world.add(ObstacleComponent(type: type, position: pos));
    }
  }

  WaveConfig get _currentWave {
    if (_currentWaveIndex < _levelConfig.waves.length) {
      return _levelConfig.waves[_currentWaveIndex];
    }
    // Fallback for endless
    return _levelConfig.waves.last;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (world.status != CrocGameStatus.playing) return;
    
    _spawnTimer += dt;
    _waveTimer += dt;
    _levelTimer += dt;
    
    // Update zone counts
    _updateZoneCounts();
    
    // 1. Check win condition
    if (_checkWinCondition()) {
      world.onLevelComplete?.call(_levelConfig.levelId, _calculateStars());
      return;
    }
    
    // 2. Check time limit
    if (_levelConfig.timeLimit != double.infinity && _levelTimer >= _levelConfig.timeLimit) {
      // Time up - check if enough score
      if (world.player.score >= _levelConfig.targetScore * 0.7) {
        // Mercy pass with 1 star
        world.onLevelComplete?.call(_levelConfig.levelId, 1);
      } else {
        world.onTimeUp?.call();
      }
      return;
    }
    
    // 3. Spawn prey based on current wave
    final wave = _currentWave;
    final currentPreyCount = world.children.whereType<PreyComponent>().length;
    
    if (currentPreyCount < wave.maxPreyCount && _spawnTimer >= wave.spawnInterval) {
      _spawnTimer = 0;
      _spawnPrey();
    }
    
    // 4. Spawn boss if needed
    if (wave.spawnBoss && !_bossSpawned) {
      _spawnBoss();
      _bossSpawned = true;
    }
    
    // 5. Wave progression
    if (_waveTimer >= wave.duration) {
      _advanceWave();
    }
  }
  
  void _updateZoneCounts() {
    for (final zone in _zones) {
      zone.preyCount = 0;
    }
    
    for (final prey in world.children.whereType<PreyComponent>()) {
      for (final zone in _zones) {
        if (zone.contains(prey.position)) {
          zone.preyCount++;
          break;
        }
      }
    }
  }
  
  bool _checkWinCondition() {
    // Win if score or prey count reached
    return world.player.score >= _levelConfig.targetScore ||
           _preysEatenThisLevel >= _levelConfig.targetPreyEaten;
  }
  
  int _calculateStars() {
    int stars = 1; // Base star for completing
    
    // Health bonus
    if (world.player.health >= world.player.maxHealth * 0.5) stars++;
    
    // Score bonus
    if (world.player.score >= _levelConfig.targetScore * 1.5) stars++;
    
    return stars.clamp(1, 3);
  }
  
  void _spawnPrey() {
    final pos = _getBalancedSpawnPos(minDistFromPlayer: 300);
    final type = _rollPreyType();
    
    world.add(PreyComponent(type: type, position: pos));
  }
  
  PreyType _rollPreyType() {
    final table = _levelConfig.spawnTable.weights;
    final roll = _rnd.nextDouble();
    
    double cumulative = 0.0;
    for (final entry in table.entries) {
      cumulative += entry.value;
      if (roll < cumulative) {
        return entry.key;
      }
    }
    
    return PreyType.angryApple; // Fallback
  }
  
  void _spawnBoss() {
    final pos = _getBalancedSpawnPos(minDistFromPlayer: 400);
    world.add(PreyComponent(type: PreyType.boss, position: pos));
    world.onBossSpawn?.call();
  }
  
  void _advanceWave() {
    _currentWaveIndex++;
    _waveTimer = 0;
    _bossSpawned = false;
    
    if (_currentWaveIndex < _levelConfig.waves.length) {
      world.onWaveComplete?.call(_currentWaveIndex);
    }
  }
  
  /// Get spawn position using zone-based balancing
  Vector2 _getBalancedSpawnPos({double minDistFromPlayer = 300}) {
    // Find zone with fewest prey (excluding center zone where player likely is)
    _zones.shuffle(_rnd);
    final sortedZones = _zones.toList()..sort((a, b) => a.preyCount.compareTo(b.preyCount));
    
    for (final zone in sortedZones) {
      // Try to find valid position in this zone
      for (int attempt = 0; attempt < 5; attempt++) {
        final pos = zone.randomPoint(_rnd);
        
        // Check distance from player
        if (pos.distanceTo(world.player.position) >= minDistFromPlayer) {
          return pos;
        }
      }
    }
    
    // Fallback: random position
    return Vector2(
      (_rnd.nextDouble() * 2 - 1) * arenaSize * 0.8,
      (_rnd.nextDouble() * 2 - 1) * arenaSize * 0.8,
    );
  }
  
  /// Called by world when prey is eaten
  void onPreyEaten() {
    _preysEatenThisLevel++;
  }
  
  /// Get remaining time for HUD
  double get remainingTime {
    if (_levelConfig.timeLimit == double.infinity) return -1;
    return (_levelConfig.timeLimit - _levelTimer).clamp(0, double.infinity);
  }
  
  /// Get current level info
  LevelConfig get levelConfig => _levelConfig;
  int get currentWaveIndex => _currentWaveIndex;
  int get totalWaves => _levelConfig.waves.length;
  
  void reset() {
    loadLevel(1);
  }
}
