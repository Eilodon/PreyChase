import 'package:equatable/equatable.dart';
import '../models/grid_point.dart';
import '../models/prey.dart';
import '../models/mutation_type.dart';
import '../models/faction.dart';
import '../models/biome.dart';
import '../models/wave_event.dart';

enum GameStatus { playing, gameOver, levelComplete, paused }

enum FuryType {
  classic,      // Speed + Invincible
  lightning,    // Chain damage nearby prey
  inferno,      // Leave fire trails
  frost,        // Slow all prey
  voidFury,     // Black hole pull effect
}

/// Extended game state with all PREY CHAOS systems
class GameState extends Equatable {
  // ═══════════════════════════════════════════════════════════════════════════
  // CORE STATE
  // ═══════════════════════════════════════════════════════════════════════════
  final List<GridPoint> snakeBody;
  final GridPoint currentDirection;
  final GridPoint nextDirection;
  final List<GridPoint> food;
  final int score;
  final GameStatus status;
  final int tick;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PREY & FURY
  // ═══════════════════════════════════════════════════════════════════════════
  final List<PreyEntity> preys;
  final double furyMeter;
  final bool isFuryActive;
  final FuryType activeFuryType;
  final int furyTimer;
  final int comboCount;
  final int comboTimer;
  final int bossesDefeated;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MUTATION SYSTEM (NEW)
  // ═══════════════════════════════════════════════════════════════════════════
  final List<MutationType> activeMutations;
  final int mutationPoints; // Points to spend on new mutations
  final int playerLevel; // Level for mutation unlocks
  final int xpToNextLevel;
  final int currentXp;
  final bool secondChanceUsed; // Track if revive used this run
  final double iFrameTimer; // Invincibility frames remaining
  final int killStreak; // Kills without taking damage
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FACTION WAR (NEW)
  // ═══════════════════════════════════════════════════════════════════════════
  final FactionWarState factionState;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE EVENTS (NEW)
  // ═══════════════════════════════════════════════════════════════════════════
  final int currentWave;
  final List<ActiveWaveEvent> activeEvents;
  final double waveTimer; // Time remaining in current wave
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BIOME/ARENA (NEW)
  // ═══════════════════════════════════════════════════════════════════════════
  final BiomeState biomeState;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ASCENSION (NEW)
  // ═══════════════════════════════════════════════════════════════════════════
  final int ascensionLevel;

  const GameState({
    required this.snakeBody,
    required this.currentDirection,
    required this.nextDirection,
    required this.food,
    required this.score,
    required this.status,
    required this.tick,
    // Prey & Fury
    this.preys = const [],
    this.furyMeter = 0.0,
    this.isFuryActive = false,
    this.activeFuryType = FuryType.classic,
    this.furyTimer = 0,
    this.comboCount = 0,
    this.comboTimer = 0,
    this.bossesDefeated = 0,
    // Mutations
    this.activeMutations = const [],
    this.mutationPoints = 0,
    this.playerLevel = 1,
    this.xpToNextLevel = 100,
    this.currentXp = 0,
    this.secondChanceUsed = false,
    this.iFrameTimer = 0.0,
    this.killStreak = 0,
    // Faction
    this.factionState = const FactionWarState(),
    // Wave Events
    this.currentWave = 1,
    this.activeEvents = const [],
    this.waveTimer = 60.0,
    // Biome
    this.biomeState = const BiomeState(),
    // Ascension
    this.ascensionLevel = 0,
  });

  static GameState initial({
    required int gridWidth,
    required int gridHeight,
    int startLength = 3,
    int ascension = 0,
  }) {
    final startX = gridWidth ~/ 2;
    final startY = gridHeight ~/ 2;
    final body = <GridPoint>[];
    for (int i = 0; i < startLength; i++) {
      body.add(GridPoint(startX, startY + i));
    }
    
    return GameState(
      snakeBody: body,
      currentDirection: GridPoint.up,
      nextDirection: GridPoint.up,
      food: [GridPoint(startX, startY - 5)],
      score: 0,
      status: GameStatus.playing,
      tick: 0,
      ascensionLevel: ascension,
    );
  }

  GameState copyWith({
    List<GridPoint>? snakeBody,
    GridPoint? currentDirection,
    GridPoint? nextDirection,
    List<GridPoint>? food,
    int? score,
    GameStatus? status,
    int? tick,
    List<PreyEntity>? preys,
    double? furyMeter,
    bool? isFuryActive,
    FuryType? activeFuryType,
    int? furyTimer,
    int? comboCount,
    int? comboTimer,
    int? bossesDefeated,
    // Mutations
    List<MutationType>? activeMutations,
    int? mutationPoints,
    int? playerLevel,
    int? xpToNextLevel,
    int? currentXp,
    bool? secondChanceUsed,
    double? iFrameTimer,
    int? killStreak,
    // Faction
    FactionWarState? factionState,
    // Wave Events
    int? currentWave,
    List<ActiveWaveEvent>? activeEvents,
    double? waveTimer,
    // Biome
    BiomeState? biomeState,
    // Ascension
    int? ascensionLevel,
  }) {
    return GameState(
      snakeBody: snakeBody ?? this.snakeBody,
      currentDirection: currentDirection ?? this.currentDirection,
      nextDirection: nextDirection ?? this.nextDirection,
      food: food ?? this.food,
      score: score ?? this.score,
      status: status ?? this.status,
      tick: tick ?? this.tick,
      preys: preys ?? this.preys,
      furyMeter: furyMeter ?? this.furyMeter,
      isFuryActive: isFuryActive ?? this.isFuryActive,
      activeFuryType: activeFuryType ?? this.activeFuryType,
      furyTimer: furyTimer ?? this.furyTimer,
      comboCount: comboCount ?? this.comboCount,
      comboTimer: comboTimer ?? this.comboTimer,
      bossesDefeated: bossesDefeated ?? this.bossesDefeated,
      // Mutations
      activeMutations: activeMutations ?? this.activeMutations,
      mutationPoints: mutationPoints ?? this.mutationPoints,
      playerLevel: playerLevel ?? this.playerLevel,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      currentXp: currentXp ?? this.currentXp,
      secondChanceUsed: secondChanceUsed ?? this.secondChanceUsed,
      iFrameTimer: iFrameTimer ?? this.iFrameTimer,
      killStreak: killStreak ?? this.killStreak,
      // Faction
      factionState: factionState ?? this.factionState,
      // Wave Events
      currentWave: currentWave ?? this.currentWave,
      activeEvents: activeEvents ?? this.activeEvents,
      waveTimer: waveTimer ?? this.waveTimer,
      // Biome
      biomeState: biomeState ?? this.biomeState,
      // Ascension
      ascensionLevel: ascensionLevel ?? this.ascensionLevel,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  String get comboRating {
    if (comboCount >= 50) return 'SSS';
    if (comboCount >= 30) return 'SS';
    if (comboCount >= 20) return 'S';
    if (comboCount >= 15) return 'A';
    if (comboCount >= 10) return 'B';
    if (comboCount >= 5) return 'C';
    return 'D';
  }
  
  /// Check if can add more mutations (max 6)
  bool get canAddMutation => activeMutations.length < 6;
  
  /// Get total synergy bonus from active mutations
  double get synergyMultiplier {
    final synergies = MutationRegistry.getActiveSynergies(activeMutations);
    return 1.0 + (synergies.length * 0.15);
  }
  
  /// Check if an event type is currently active
  bool isEventActive(WaveEventType type) =>
      activeEvents.any((e) => e.type == type && !e.isExpired);
  
  /// Get current biome data
  BiomeData get currentBiome => biomeState.data;
  
  /// XP progress percentage
  double get levelProgress => currentXp / xpToNextLevel;

  @override
  List<Object?> get props => [
    snakeBody, currentDirection, nextDirection, food, score, status, tick,
    preys, furyMeter, isFuryActive, activeFuryType, furyTimer,
    comboCount, comboTimer, bossesDefeated,
    activeMutations, mutationPoints, playerLevel, currentXp,
    secondChanceUsed, iFrameTimer, killStreak,
    factionState, currentWave, activeEvents, waveTimer,
    biomeState, ascensionLevel,
  ];
}
