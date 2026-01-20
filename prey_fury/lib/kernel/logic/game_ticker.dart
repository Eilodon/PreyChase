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
    // Check for Manual Fury
    if (intents.contains(UserIntent.activateFury) && newFuryMeter >= 1.0 && !newIsFuryActive) {
       newIsFuryActive = true;
       newFuryTimer = 50 + (state.bossesDefeated * 10); // Bonus duration for easier bosses? Or harder? Keep it consistent.
       newFuryMeter = 0.0;
       events.add(const GameEventFuryActivated());
    }

    GridPoint nextDirection = _resolveDirection(state.currentDirection, state.nextDirection, intents);
    final currentHead = state.snakeBody.first;
    final newHead = currentHead + nextDirection;

    // --- 2. PREY MANAGEMENT ---
    
    // A. Update Emotions & Spawning
    List<PreyEntity> nextPreys = [];
    bool bossActive = false;
    for (var prey in state.preys) {
       // Check boss
       if (prey.type == PreyType.boss) bossActive = true;
    
       // Update Emotion
       PreyEmotion newEmotion = PreyEmotion.angry;
       
       // Terrified if Fury is active
       if (newIsFuryActive) {
          newEmotion = PreyEmotion.terrified;
       }
       // Desperate if last one alive (and not fury)
       else if (state.preys.length == 1) {
          newEmotion = PreyEmotion.desperate;
       }
       
       nextPreys.add(prey.copyWith(emotion: newEmotion));
    }

    // Spawn Boss (Milestones: 500, 1500, 2500...)
    // Formula: 500 + (bossesDefeated * 1000)
    int nextBossScore = 500 + (state.bossesDefeated * 1000);
    int newBossesDefeated = state.bossesDefeated;
    
    if (state.score >= nextBossScore && !bossActive) {
         final spawnPos = _findEmptySpot(state.snakeBody, state.food, state.preys);
         if (spawnPos != null) {
            nextPreys.add(PreyEntity(
               id: 'boss_$nextTick',
               type: PreyType.boss,
               position: spawnPos,
               spawnTick: nextTick,
               health: 5,
               maxHealth: 5,
            ));
            newBossesDefeated++; // Mark milestone as passed
         }
    }

    // Spawn new prey (Every 50 ticks, max 3)
    if (state.preys.length < 3 && nextTick % 50 == 0) {
       final spawnPos = _findEmptySpot(state.snakeBody, state.food, state.preys);
       if (spawnPos != null) {
          // Select Type based on Score Progression
          PreyType type = PreyType.angryApple;
          final r = _random.nextDouble();
          
          if (state.score >= 800 && r < 0.1) {
             type = PreyType.goldenCake; // 10% rare
          } else if (state.score >= 500 && r < 0.3) {
             type = PreyType.ghostPizza; 
          } else if (state.score >= 300 && r < 0.5) {
             type = PreyType.ninjaSushi;
          } else if (state.score >= 100 && r < 0.7) {
             type = PreyType.zombieBurger;
          }
          
          int hp = (type == PreyType.zombieBurger) ? 3 : 1;

          nextPreys.add(PreyEntity(
             id: 'prey_$nextTick',
             type: type,
             position: spawnPos,
             spawnTick: nextTick,
             health: hp,
             maxHealth: hp,
          ));
       }
    }

    // Move existing prey
    List<PreyEntity> movedPreys = [];
    for (var prey in nextPreys) {
       if (prey.status != PreyStatus.active) continue;
       
       // Calculate effective move interval
       int interval = prey.moveInterval;
       
       // Modifiers
       if (prey.emotion == PreyEmotion.desperate) {
          interval = max(2, (interval * 0.6).round()); // 40% faster
       }
       if (state.activeFuryType == FuryType.frost && state.isFuryActive) {
          interval = (interval * 2); // 50% slower
       }

       // Check if it's time to move
       if (nextTick % interval == 0) {
          GridPoint move = GridPoint.zero;
          final closestSnake = _findClosestSnakeSegment(prey.position, state.snakeBody);
          
          bool isFleeing = prey.emotion == PreyEmotion.terrified || prey.type == PreyType.goldenCake;
          
          if (isFleeing) {
             // RUN AWAY!
             // Move in direction that increases distance to snake head (most dangerous)
             final head = state.snakeBody.first;
             GridPoint delta = prey.position - head; // Vector pointing AWAY
             
             // If delta is zero (on top of snake), random move
             if (delta == GridPoint.zero) {
                delta = GridPoint(_random.nextBool()?1:-1, _random.nextBool()?1:-1);
             }
             
             if (delta.x.abs() > delta.y.abs()) {
                 move = delta.x > 0 ? GridPoint.right : GridPoint.left;
             } else {
                 move = delta.y > 0 ? GridPoint.down : GridPoint.up;
             }
          } else {
              // CHASE (Angry/Desperate/Zombie/Ninja)
              GridPoint delta = closestSnake - prey.position;
              
              if (delta.x.abs() > delta.y.abs()) {
                 move = delta.x > 0 ? GridPoint.right : GridPoint.left;
              } else if (delta.y != 0) {
                 move = delta.y > 0 ? GridPoint.down : GridPoint.up;
              }
              
              // Ninja: Small chance to burst move (double step)
              if (prey.type == PreyType.ninjaSushi && _random.nextDouble() < 0.3) {
                  move = move + move; // Dash 2 cells
              }
          }
          
          // Apply Move & Check Bounds (Ghost wraps)
          GridPoint nextPos = prey.position + move;
          
          if (prey.type == PreyType.ghostPizza) {
             // Wrap around
             nextPos = GridPoint(
               (nextPos.x + gridWidth) % gridWidth,
               (nextPos.y + gridHeight) % gridHeight
             );
             movedPreys.add(prey.copyWith(position: nextPos));
          } else {
             // Use standard wall check
             if (_isValidPos(nextPos)) {
                movedPreys.add(prey.copyWith(position: nextPos));
             } else {
                movedPreys.add(prey); // Stay put
             }
          }
       } else {
          movedPreys.add(prey);
       }
    }



    // Fury specific effects (Void, Lightning)
    if (newIsFuryActive) {
       movedPreys = _applyFuryEffects(state.activeFuryType, movedPreys, newHead);
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
               // Check Health
               int newHp = prey.health - 1;
               if (prey.type == PreyType.boss && state.activeFuryType == FuryType.classic) {
                  // Classic weak vs Boss? No, standard damage.
               }
               
               if (newHp <= 0) {
                   // KILL
                   scoreDelta += prey.scoreValue;
                   events.add(const GameEventSnakeAtePrey());
                   newFuryTimer += 10;
                   // Prey Dies (don't add to list)
               } else {
                   // BOSS HURT
                   finalPreys.add(prey.copyWith(health: newHp));
                   events.add(const GameEventSnakeDamaged()); // Re-use damage sound/effect? Or new one?
                   // Push Boss back?
                   // For now, boss stays at position (collision handled).
                   // Actually, if we hit head, we should bounce snake back? 
                   // Or let snake pass through?
                   // Simplest: Boss teleports away when hurt?
                   // Let's make Boss teleport to random spot when hurt to prevent instant multi-hit kill.
                   // Or invincibility frame?
                   // BOSS TELEPORT:
                   final jumpParams = _findEmptySpot(state.snakeBody, state.food, finalPreys);
                   if (jumpParams != null) {
                       finalPreys.last = finalPreys.last.copyWith(position: jumpParams); // Move the hurt boss
                   }
               }
               continue; 
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
              newFuryMeter = 1.0; // Cap at 100%, wait for manual trigger
              // No auto activate
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
      bossesDefeated: newBossesDefeated,
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
         case UserIntent.activateFury: break; // Not a move
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

  List<PreyEntity> _applyFuryEffects(FuryType type, List<PreyEntity> preys, GridPoint snakeHead) {
     if (type == FuryType.voidFury) {
        // Void Pull: Move all prey 1 step closer to snake head regardless of interval
        // This is a powerful force!
        return preys.map((p) {
           if (p.status != PreyStatus.active) return p;
           GridPoint delta = snakeHead - p.position;
           if (delta == GridPoint.zero) return p;
           
           GridPoint pull = GridPoint.zero;
           if (delta.x.abs() > delta.y.abs()) {
               pull = delta.x > 0 ? GridPoint.right : GridPoint.left;
           } else {
               pull = delta.y > 0 ? GridPoint.down : GridPoint.up;
           }
           GridPoint newPos = p.position + pull;
           if (_isValidPos(newPos)) {
              return p.copyWith(position: newPos);
           }
           return p;
        }).toList();
     }
     
     if (type == FuryType.lightning) {
        // Lightning: Kill prey within range 5 instantly? 
        // Or just damage? Let's say it effectively acts as a ranged "eat"
        // But for simplicity in this tick structure, we'll mark them as killed/eaten 
        // in collision phase? Or move them ONTO the snake head to force collision?
        // Let's move them ONTO snake head if within range 3
        return preys.map((p) {
            if (p.status != PreyStatus.active) return p;
            int dist = (p.position - snakeHead).manhattanDistance;
            if (dist <= 3) {
               return p.copyWith(position: snakeHead); // Force collision/eat next step
            }
            return p;
        }).toList();
     }
     
     return preys;
  }
}
