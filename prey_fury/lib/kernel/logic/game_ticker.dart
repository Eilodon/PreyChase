import 'dart:math';
import '../actions/user_intent.dart';
import '../models/grid_point.dart';
import '../state/game_state.dart';
import '../models/prey.dart';
import '../events/game_event.dart';

class GameTickResult {
  final GameState state;
  final List<GameEvent> events;
  
  const GameTickResult(this.state, this.events);
}

class GameTicker {
  final int gridWidth;
  final int gridHeight;
  final Random _random;

  GameTicker({
    required this.gridWidth,
    required this.gridHeight,
    int? seed,
  }) : _random = Random(seed);

  GameTickResult tick(GameState state, List<UserIntent> intents) {
    if (state.status != GameStatus.playing) return GameTickResult(state, []);
    
    final events = <GameEvent>[];

    // --- 0. PRE-CALCULATION ---
    int nextTick = state.tick + 1;
    
    // Fury Timer Decay
    int newFuryTimer = state.furyTimer;
    bool newIsFuryActive = state.isFuryActive;
    if (newIsFuryActive) {
      newFuryTimer = max(0, newFuryTimer - 1);
      if (newFuryTimer <= 0) {
        newIsFuryActive = false;
      }
    }

    // Combo Timer Decay
    int newComboTimer = max(0, state.comboTimer - 1);
    int newComboCount = state.comboCount;
    double newFuryMeter = state.furyMeter;
    
    if (newComboTimer <= 0) {
      newComboCount = 0;
    }

    // --- 1. SNAKE MOVEMENT INPUT ---
    GridPoint nextDirection = _resolveDirection(state.currentDirection, state.nextDirection, intents);
    final currentHead = state.snakeBody.first;
    final newHead = currentHead + nextDirection;

    // --- 2. PREY MANAGEMENT ---
    // Spawn new prey (Every 50 ticks, max 3 for now)
    List<PreyEntity> nextPreys = List.from(state.preys);
    if (state.preys.length < 3 && nextTick % 50 == 0) {
       final spawnPos = _findEmptySpot(state.snakeBody, state.food, state.preys);
       if (spawnPos != null) {
          nextPreys.add(PreyEntity(
             id: 'prey_$nextTick',
             type: PreyType.angryApple, // Start simple
             position: spawnPos,
             spawnTick: nextTick,
          ));
       }
    }

    // Move existing prey
    List<PreyEntity> movedPreys = [];
    for (var prey in nextPreys) {
       if (prey.status != PreyStatus.active) continue;
       
       // Check if it's time to move
       if (nextTick % prey.moveInterval == 0) {
          // Move towards CLOSEST snake segment (not just head!)
          final closestTarget = _findClosestSnakeSegment(prey.position, state.snakeBody);
          GridPoint delta = closestTarget - prey.position;
          GridPoint move = GridPoint.zero;
          
          if (delta.x.abs() > delta.y.abs()) {
             move = delta.x > 0 ? GridPoint.right : GridPoint.left;
          } else if (delta.y != 0) {
             move = delta.y > 0 ? GridPoint.down : GridPoint.up;
          }
          
          // Basic Wall check for prey
          GridPoint nextPos = prey.position + move;
          if (_isValidPos(nextPos)) {
             movedPreys.add(prey.copyWith(position: nextPos));
          } else {
             movedPreys.add(prey); // Stay put
          }
       } else {
          movedPreys.add(prey);
       }
    }

    // --- 3. COLLISION RESOLUTION ---
    
    // A. Wall Collision (Snake)
    if (!_isValidPos(newHead)) {
       events.add(const GameEventSnakeHitWall());
       events.add(const GameEventGameOver());
       return GameTickResult(state.copyWith(status: GameStatus.gameOver), events);
    }
    
    // B. Snake vs Prey
    // We check overlap with newHead OR existing body.
    // Simplifying: Check Head vs Prey collision first (Eating/Damage)
    // Then Body vs Prey damage check.
    
    int scoreDelta = 0;
    bool snakeTookDamage = false;
    List<PreyEntity> finalPreys = [];
    
    for (var prey in movedPreys) {
       bool hitHead = (prey.position == newHead);
       bool hitBody = state.snakeBody.contains(prey.position); // Prioritize head logic
       
       if (hitHead) {
           if (newIsFuryActive) {
               // EAT PREY!
               scoreDelta += prey.scoreValue;
               events.add(const GameEventSnakeAtePrey());
               // Fury Extends slightly
               newFuryTimer += 10;
               // Prey Dies
               continue; // Don't add to final list
           } else {
               // DAMAGE!
               snakeTookDamage = true;
               events.add(const GameEventSnakeDamaged());
               // Prey bounces/dies (or just stays? Let's kill it for simplicity in MVP)
               continue; 
           }
       } else if (hitBody && !newIsFuryActive) {
           // Body Hit (Damage)
           snakeTookDamage = true;
           events.add(const GameEventSnakeDamaged());
           continue; 
       }
       
       finalPreys.add(prey);
    }
    
    // C. Snake vs Food
    bool eatingFood = false;
    List<GridPoint> nextFood = List.from(state.food);
    if (nextFood.contains(newHead)) {
       eatingFood = true;
       nextFood.remove(newHead);
       scoreDelta += 10; // Food score
       events.add(const GameEventSnakeAteFood());
       
       // Combo Logic
       if (!newIsFuryActive) {
          newComboCount++;
          newComboTimer = 20; // 3 seconds approx @ 6.6 TPS (actually 3*6 = 18)
          newFuryMeter = min(1.0, newFuryMeter + 0.2); // 5 foods to full
          
          if (newFuryMeter >= 1.0) {
             newIsFuryActive = true;
             newFuryTimer = 50; // ~8 seconds
             newFuryMeter = 0.0;
             events.add(const GameEventFuryActivated());
          }
       }
       
       // Respawn Food
       final spawn = _findEmptySpot([newHead, ...state.snakeBody], nextFood, finalPreys);
       if (spawn != null) nextFood.add(spawn);
    }
    
    // D. Self Collision (Snake)
    // Standard snake rules (unless Fury? No, let's keep self-collision fatal)
    List<GridPoint> currentSnakeBody = state.snakeBody;
    if (currentSnakeBody.contains(newHead) && newHead != currentSnakeBody.last) {
       // Only ignore tail if not eating (tail moves away)
       if (eatingFood || newHead != currentSnakeBody.last) {
          events.add(const GameEventSnakeHitSelf());
          events.add(const GameEventGameOver());
          return GameTickResult(state.copyWith(status: GameStatus.gameOver), events);
       }
    }

    // --- 4. STATE UPDATE ---
    
    // Apply Damage (Shrink)
    List<GridPoint> finalSnakeBody = [newHead, ...currentSnakeBody];
    if (!eatingFood) {
       finalSnakeBody.removeLast();
    }
    
    if (snakeTookDamage) {
        // Reset Combo
        newComboCount = 0;
        newFuryMeter = 0.0;
        
        // Shrink (Damage)
        // Remove from tail
        int damage = 1; // Default
        for (int i=0; i<damage; i++) {
           if (finalSnakeBody.length > 1) {
              finalSnakeBody.removeLast();
           } else {
              events.add(const GameEventGameOver());
              return GameTickResult(state.copyWith(status: GameStatus.gameOver), events); // Died
           }
        }
    }

    return GameTickResult(state.copyWith(
      tick: nextTick,
      snakeBody: finalSnakeBody,
      food: nextFood,
      preys: finalPreys,
      score: state.score + scoreDelta,
      currentDirection: nextDirection,
      nextDirection: nextDirection,
      furyMeter: newFuryMeter,
      isFuryActive: newIsFuryActive,
      furyTimer: newFuryTimer,
      comboCount: newComboCount,
      comboTimer: newComboTimer,
    ), events);
  }

  // --- Helpers ---

  GridPoint _resolveDirection(GridPoint current, GridPoint buffer, List<UserIntent> intents) {
    GridPoint next = buffer;
    for (final intent in intents) {
       GridPoint? potential;
       switch (intent) {
         case UserIntent.turnLeft: potential = GridPoint.left; break;
         case UserIntent.turnRight: potential = GridPoint.right; break;
         case UserIntent.turnUp: potential = GridPoint.up; break;
         case UserIntent.turnDown: potential = GridPoint.down; break;
         case UserIntent.none: break;
       }
       if (potential != null && (potential + current) != GridPoint.zero) {
          next = potential;
       }
    }
    return next;
  }

  bool _isValidPos(GridPoint p) {
    return p.x >= 0 && p.x < gridWidth && p.y >= 0 && p.y < gridHeight;
  }
  
  GridPoint? _findEmptySpot(List<GridPoint> snake, List<GridPoint> food, List<PreyEntity> preys) {
     for (int i=0; i<10; i++) {
        final p = GridPoint(_random.nextInt(gridWidth), _random.nextInt(gridHeight));
        bool occupied = snake.contains(p) || food.contains(p) || preys.any((pr) => pr.position == p);
        if (!occupied) return p;
     }
     return null;
  }

  /// Find the snake segment closest to the prey position
  GridPoint _findClosestSnakeSegment(GridPoint preyPos, List<GridPoint> snakeBody) {
    GridPoint closest = snakeBody.first;
    int minDist = (preyPos - closest).manhattanDistance;
    for (final segment in snakeBody) {
      int dist = (preyPos - segment).manhattanDistance;
      if (dist < minDist) {
        minDist = dist;
        closest = segment;
      }
    }
    return closest;
  }
}
