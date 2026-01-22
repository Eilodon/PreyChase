/// Battle Royale Manager - Core game loop for Vạn Cổ Chi Vương
///
/// Handles:
/// - Shrinking zone (Bo)
/// - Game phases (8 minute match)
/// - Poison damage outside zone
/// - Win condition (last alive)

import 'dart:math';
import 'package:flutter/material.dart';

/// Game phase enum
enum BRPhase {
  /// 0:00 - 0:05: Spawn phase, invulnerable
  spawn(
    name: 'Spawn',
    nameVi: 'Xuất Hiện',
    duration: 5.0,
    canTakeDamage: false,
  ),

  /// 0:05 - 2:30: Early game, farm phase
  earlyGame(
    name: 'Early Game',
    nameVi: 'Đầu Trận',
    duration: 145.0, // 2:25
    canTakeDamage: true,
  ),

  /// 2:30 - 5:00: Mid game, first shrink
  midGame(
    name: 'Mid Game',
    nameVi: 'Giữa Trận',
    duration: 150.0, // 2:30
    canTakeDamage: true,
  ),

  /// 5:00 - 7:30: Late game, second shrink
  lateGame(
    name: 'Late Game',
    nameVi: 'Cuối Trận',
    duration: 150.0, // 2:30
    canTakeDamage: true,
  ),

  /// 7:30+: Sudden death, final shrink
  suddenDeath(
    name: 'Sudden Death',
    nameVi: 'Tử Chiến',
    duration: 60.0, // 1:00 before overtime
    canTakeDamage: true,
  ),

  /// 8:30+: Overtime - extreme poison
  overtime(
    name: 'Overtime',
    nameVi: 'Hiệp Phụ',
    duration: double.infinity,
    canTakeDamage: true,
  );

  final String name;
  final String nameVi;
  final double duration;
  final bool canTakeDamage;

  const BRPhase({
    required this.name,
    required this.nameVi,
    required this.duration,
    required this.canTakeDamage,
  });
}

/// Zone shrink data per phase
class ZoneShrinkData {
  final double startRadius;
  final double endRadius;
  final double shrinkDuration;
  final double poisonDamage; // Per second

  const ZoneShrinkData({
    required this.startRadius,
    required this.endRadius,
    required this.shrinkDuration,
    required this.poisonDamage,
  });
}

/// Complete phase configuration
class PhaseConfig {
  final BRPhase phase;
  final double startTime; // Seconds from game start
  final ZoneShrinkData zone;
  final double lightningInterval; // Thiên Kiếp frequency (0 = disabled)

  const PhaseConfig({
    required this.phase,
    required this.startTime,
    required this.zone,
    this.lightningInterval = 0,
  });
}

/// Battle Royale game state
class BRGameState {
  final BRPhase currentPhase;
  final double gameTime; // Total elapsed time
  final double phaseTime; // Time in current phase
  final double currentZoneRadius;
  final double targetZoneRadius;
  final double zoneShrinkSpeed;
  final double currentPoisonDamage;
  final int aliveCount;
  final int totalPlayers;
  final bool gameOver;
  final String? winnerId;

  const BRGameState({
    this.currentPhase = BRPhase.spawn,
    this.gameTime = 0,
    this.phaseTime = 0,
    this.currentZoneRadius = BattleRoyaleManager.mapRadius,
    this.targetZoneRadius = BattleRoyaleManager.mapRadius,
    this.zoneShrinkSpeed = 0,
    this.currentPoisonDamage = 0,
    this.aliveCount = 20,
    this.totalPlayers = 20,
    this.gameOver = false,
    this.winnerId,
  });

  BRGameState copyWith({
    BRPhase? currentPhase,
    double? gameTime,
    double? phaseTime,
    double? currentZoneRadius,
    double? targetZoneRadius,
    double? zoneShrinkSpeed,
    double? currentPoisonDamage,
    int? aliveCount,
    int? totalPlayers,
    bool? gameOver,
    String? winnerId,
  }) {
    return BRGameState(
      currentPhase: currentPhase ?? this.currentPhase,
      gameTime: gameTime ?? this.gameTime,
      phaseTime: phaseTime ?? this.phaseTime,
      currentZoneRadius: currentZoneRadius ?? this.currentZoneRadius,
      targetZoneRadius: targetZoneRadius ?? this.targetZoneRadius,
      zoneShrinkSpeed: zoneShrinkSpeed ?? this.zoneShrinkSpeed,
      currentPoisonDamage: currentPoisonDamage ?? this.currentPoisonDamage,
      aliveCount: aliveCount ?? this.aliveCount,
      totalPlayers: totalPlayers ?? this.totalPlayers,
      gameOver: gameOver ?? this.gameOver,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  /// Remaining time in current phase
  double get phaseRemainingTime {
    final phaseDuration = currentPhase.duration;
    if (phaseDuration == double.infinity) return double.infinity;
    return max(0, phaseDuration - phaseTime);
  }

  /// Total game duration target (8 minutes)
  static const double targetDuration = 480.0; // 8 minutes

  /// Formatted game time (MM:SS)
  String get formattedTime {
    final minutes = (gameTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (gameTime % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Is in sudden death or overtime
  bool get isEndGame =>
      currentPhase == BRPhase.suddenDeath || currentPhase == BRPhase.overtime;
}

/// Battle Royale Manager - Pure game logic
class BattleRoyaleManager {
  // === MAP CONSTANTS ===

  /// Total map radius (center = 0,0)
  static const double mapRadius = 1000.0;

  /// Map size (2000x2000)
  static const double mapSize = mapRadius * 2;

  /// Center zone radius (final shrink target)
  static const double centerZoneRadius = 250.0;

  // === PHASE CONFIGURATIONS ===

  static const List<PhaseConfig> phaseConfigs = [
    // Spawn Phase (0:00 - 0:05)
    PhaseConfig(
      phase: BRPhase.spawn,
      startTime: 0,
      zone: ZoneShrinkData(
        startRadius: mapRadius,
        endRadius: mapRadius,
        shrinkDuration: 0,
        poisonDamage: 0,
      ),
      lightningInterval: 0,
    ),

    // Early Game (0:05 - 2:30)
    PhaseConfig(
      phase: BRPhase.earlyGame,
      startTime: 5,
      zone: ZoneShrinkData(
        startRadius: mapRadius,
        endRadius: mapRadius, // No shrink yet
        shrinkDuration: 0,
        poisonDamage: 0,
      ),
      lightningInterval: 0,
    ),

    // Mid Game (2:30 - 5:00)
    // First shrink: 1000 → 700 (30% reduction)
    PhaseConfig(
      phase: BRPhase.midGame,
      startTime: 150,
      zone: ZoneShrinkData(
        startRadius: mapRadius,
        endRadius: 700,
        shrinkDuration: 30, // 30s to shrink
        poisonDamage: 5, // 5 HP/s
      ),
      lightningInterval: 12, // Every 12s
    ),

    // Late Game (5:00 - 7:30)
    // Second shrink: 700 → 400
    PhaseConfig(
      phase: BRPhase.lateGame,
      startTime: 300,
      zone: ZoneShrinkData(
        startRadius: 700,
        endRadius: 400,
        shrinkDuration: 30,
        poisonDamage: 8, // 8 HP/s
      ),
      lightningInterval: 8, // Every 8s
    ),

    // Sudden Death (7:30 - 8:30)
    // Final shrink: 400 → 250 (center zone)
    PhaseConfig(
      phase: BRPhase.suddenDeath,
      startTime: 450,
      zone: ZoneShrinkData(
        startRadius: 400,
        endRadius: centerZoneRadius,
        shrinkDuration: 20,
        poisonDamage: 12, // 12 HP/s
      ),
      lightningInterval: 4, // Every 4s
    ),

    // Overtime (8:30+)
    // Zone stays at center, extreme poison
    PhaseConfig(
      phase: BRPhase.overtime,
      startTime: 510,
      zone: ZoneShrinkData(
        startRadius: centerZoneRadius,
        endRadius: 100, // Tiny zone
        shrinkDuration: 60,
        poisonDamage: 20, // 20 HP/s EXTREME
      ),
      lightningInterval: 2, // Every 2s CHAOTIC
    ),
  ];

  // === GAME STATE ===

  BRGameState _state = const BRGameState();

  BRGameState get state => _state;

  // === CALLBACKS ===

  void Function(BRPhase newPhase)? onPhaseChange;
  void Function(double newRadius)? onZoneShrink;
  void Function()? onZoneShrinkWarning;
  void Function(String winnerId)? onGameOver;
  void Function()? onLightningStrike;

  // === INITIALIZATION ===

  void initialize({int totalPlayers = 20}) {
    _state = BRGameState(
      totalPlayers: totalPlayers,
      aliveCount: totalPlayers,
    );
  }

  void reset() {
    _state = const BRGameState();
  }

  // === UPDATE LOOP ===

  void update(double dt) {
    if (_state.gameOver) return;

    // Update timers
    final newGameTime = _state.gameTime + dt;
    final newPhaseTime = _state.phaseTime + dt;

    // Check phase transition
    final nextPhaseConfig = _getNextPhaseConfig(newGameTime);
    if (nextPhaseConfig != null && nextPhaseConfig.phase != _state.currentPhase) {
      _transitionToPhase(nextPhaseConfig);
      return;
    }

    // Update zone shrinking
    double newRadius = _state.currentZoneRadius;
    if (_state.targetZoneRadius < _state.currentZoneRadius && _state.zoneShrinkSpeed > 0) {
      newRadius = max(
        _state.targetZoneRadius,
        _state.currentZoneRadius - (_state.zoneShrinkSpeed * dt),
      );

      if (newRadius != _state.currentZoneRadius) {
        onZoneShrink?.call(newRadius);
      }
    }

    _state = _state.copyWith(
      gameTime: newGameTime,
      phaseTime: newPhaseTime,
      currentZoneRadius: newRadius,
    );
  }

  PhaseConfig? _getNextPhaseConfig(double gameTime) {
    for (int i = phaseConfigs.length - 1; i >= 0; i--) {
      if (gameTime >= phaseConfigs[i].startTime) {
        return phaseConfigs[i];
      }
    }
    return phaseConfigs.first;
  }

  void _transitionToPhase(PhaseConfig config) {
    final zone = config.zone;
    final shrinkSpeed = zone.shrinkDuration > 0
        ? (zone.startRadius - zone.endRadius) / zone.shrinkDuration
        : 0.0;

    // Send warning before shrink
    if (zone.endRadius < _state.currentZoneRadius) {
      onZoneShrinkWarning?.call();
    }

    _state = _state.copyWith(
      currentPhase: config.phase,
      phaseTime: 0,
      targetZoneRadius: zone.endRadius,
      zoneShrinkSpeed: shrinkSpeed,
      currentPoisonDamage: zone.poisonDamage,
    );

    onPhaseChange?.call(config.phase);
  }

  // === GAME ACTIONS ===

  /// Check if position is inside safe zone
  bool isInsideZone(double x, double y) {
    final distance = sqrt(x * x + y * y);
    return distance <= _state.currentZoneRadius;
  }

  /// Get distance to zone edge (negative = inside, positive = outside)
  double distanceToZoneEdge(double x, double y) {
    final distance = sqrt(x * x + y * y);
    return distance - _state.currentZoneRadius;
  }

  /// Get poison damage at position
  double getPoisonDamageAt(double x, double y) {
    if (isInsideZone(x, y)) return 0;
    return _state.currentPoisonDamage;
  }

  /// Report player death
  void onPlayerDeath(String playerId) {
    final newAliveCount = _state.aliveCount - 1;

    _state = _state.copyWith(aliveCount: newAliveCount);

    // Check win condition
    if (newAliveCount <= 1) {
      // Find winner (would be passed in real implementation)
      _state = _state.copyWith(
        gameOver: true,
        winnerId: playerId, // Last alive
      );
      onGameOver?.call(playerId);
    }
  }

  /// Get current lightning interval (0 = disabled)
  double get currentLightningInterval {
    final config = _getNextPhaseConfig(_state.gameTime);
    return config?.lightningInterval ?? 0;
  }

  /// Should trigger lightning at this time?
  bool shouldTriggerLightning(double timeSinceLastLightning) {
    final interval = currentLightningInterval;
    if (interval <= 0) return false;
    return timeSinceLastLightning >= interval;
  }

  // === UI HELPERS ===

  /// Get zone color for rendering
  Color getZoneEdgeColor() {
    final phase = _state.currentPhase;
    switch (phase) {
      case BRPhase.spawn:
      case BRPhase.earlyGame:
        return Colors.green.withOpacity(0.3);
      case BRPhase.midGame:
        return Colors.yellow.withOpacity(0.4);
      case BRPhase.lateGame:
        return Colors.orange.withOpacity(0.5);
      case BRPhase.suddenDeath:
        return Colors.red.withOpacity(0.6);
      case BRPhase.overtime:
        return Colors.purple.withOpacity(0.7);
    }
  }

  /// Get poison zone color
  Color getPoisonZoneColor() {
    final damage = _state.currentPoisonDamage;
    if (damage <= 0) return Colors.transparent;
    if (damage <= 5) return const Color(0x4000FF00); // Light green
    if (damage <= 8) return const Color(0x60FFFF00); // Yellow
    if (damage <= 12) return const Color(0x80FF8800); // Orange
    return const Color(0xA0FF0000); // Red
  }

  /// Get phase progress (0.0 to 1.0)
  double get phaseProgress {
    final duration = _state.currentPhase.duration;
    if (duration == double.infinity) return 0;
    return (_state.phaseTime / duration).clamp(0, 1);
  }

  /// Get zone shrink progress (0.0 to 1.0)
  double get zoneShrinkProgress {
    final config = _getNextPhaseConfig(_state.gameTime);
    if (config == null) return 1;
    final zone = config.zone;
    if (zone.startRadius == zone.endRadius) return 1;

    final totalShrink = zone.startRadius - zone.endRadius;
    final currentShrink = zone.startRadius - _state.currentZoneRadius;
    return (currentShrink / totalShrink).clamp(0, 1);
  }
}
