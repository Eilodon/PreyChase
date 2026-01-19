import 'package:equatable/equatable.dart';
import '../models/grid_point.dart';
import '../models/prey.dart';

enum GameStatus { playing, gameOver }

class GameState extends Equatable {
  final List<GridPoint> snakeBody;
  final GridPoint currentDirection;
  final GridPoint nextDirection; // Buffer next move
  final List<GridPoint> food;
  final int score;
  final GameStatus status;
  final int tick;
  
  // Phase 2: Tension & Release
  final List<PreyEntity> preys;
  final double furyMeter; // 0.0 to 1.0
  final bool isFuryActive;
  final int furyTimer; // Ticks remaining
  final int comboCount;
  final int comboTimer; // Ticks until combo reset

  const GameState({
    required this.snakeBody,
    required this.currentDirection,
    required this.nextDirection,
    required this.food,
    required this.score,
    required this.status,
    required this.tick,
    this.preys = const [],
    this.furyMeter = 0.0,
    this.isFuryActive = false,
    this.furyTimer = 0,
    this.comboCount = 0,
    this.comboTimer = 0,
  });

  static GameState initial({
    required int gridWidth,
    required int gridHeight,
    int startLength = 3,
  }) {
    // Start in middle
    final startX = gridWidth ~/ 2;
    final startY = gridHeight ~/ 2;
    final body = <GridPoint>[];
    for (int i = 0; i < startLength; i++) {
        body.add(GridPoint(startX, startY + i)); // Tail down
    }
    
    return GameState(
      snakeBody: body,
      currentDirection: GridPoint.up,
      nextDirection: GridPoint.up,
      food: [GridPoint(startX, startY - 5)], // Initial food
      score: 0,
      status: GameStatus.playing,
      tick: 0,
      preys: const [],
      furyMeter: 0.0,
      isFuryActive: false,
      furyTimer: 0,
      comboCount: 0,
      comboTimer: 0,
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
    int? furyTimer,
    int? comboCount,
    int? comboTimer,
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
      furyTimer: furyTimer ?? this.furyTimer,
      comboCount: comboCount ?? this.comboCount,
      comboTimer: comboTimer ?? this.comboTimer,
    );
  }

  @override
  List<Object?> get props => [
        snakeBody,
        currentDirection,
        nextDirection,
        food,
        score,
        status,
        tick,
        preys,
        furyMeter,
        isFuryActive,
        furyTimer,
        comboCount,
        comboTimer,
      ];
}
