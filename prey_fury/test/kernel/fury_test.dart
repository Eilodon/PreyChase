import 'package:flutter_test/flutter_test.dart';
import 'package:prey_fury/kernel/actions/user_intent.dart';
import 'package:prey_fury/kernel/logic/game_ticker.dart';
import 'package:prey_fury/kernel/models/grid_point.dart';
import 'package:prey_fury/kernel/models/prey.dart';
import 'package:prey_fury/kernel/state/game_state.dart';

void main() {
  group('Kernel: Phase 2 Logic', () {
    late GameTicker ticker;
    late GameState initialState;

    setUp(() {
      ticker = GameTicker(gridWidth: 20, gridHeight: 20, seed: 12345);
      initialState = GameState.initial(gridWidth: 20, gridHeight: 20, startLength: 5);
    });

    test('Prey should spawn periodically', () {
      var state = initialState;
      // Start at tick 49 so next tick is 50 -> Spawn
      state = state.copyWith(tick: 49);
      
      state = ticker.tick(state, []).state;
      
      // Should have 1 prey
      expect(state.preys.length, 1);
      expect(state.tick, 50);
    });

    test('Prey moves towards snake', () {
       // Snake at (10, 10). Prey at (10, 5). Prey should move down.
       var state = initialState.copyWith(
          snakeBody: [const GridPoint(10, 10)],
          preys: [
             const PreyEntity(
                id: 'test', 
                type: PreyType.angryApple, 
                position: GridPoint(10, 5), 
                spawnTick: 0
             )
          ],
          tick: 0,
       );
       
       // Force tick to match moveInterval (5 for Apple)
       // We need to advance state.tick to 5.
       // Current logic checks `nextTick % interval == 0`.
       // So if state.tick is 4, next is 5.
       state = state.copyWith(tick: 4);
       
       final result = ticker.tick(state, []);
      final next = result.state;
       // Prey should be at (10, 6)
       expect(next.preys.first.position, const GridPoint(10, 6));
    });

    test('Prey chases CLOSEST snake segment (not just head)', () {
       // Snake: Head at (10, 5), body extends DOWN to (10, 10)
       // Prey at (12, 10) - closest segment is (10, 10), not head (10, 5)
       var state = initialState.copyWith(
          snakeBody: [
            const GridPoint(10, 5),  // Head
            const GridPoint(10, 6),
            const GridPoint(10, 7),
            const GridPoint(10, 8),
            const GridPoint(10, 9),
            const GridPoint(10, 10), // Tail - closest to prey
          ],
          preys: [
             const PreyEntity(
                id: 'test', 
                type: PreyType.angryApple, 
                position: GridPoint(12, 10), // Right of tail (dist=2)
                spawnTick: 0
             )
          ],
          tick: 4, // Next tick (5) triggers move
       );
       
       final result = ticker.tick(state, []);
       final next = result.state;
       
       // Prey should move LEFT toward (10, 10), not UP toward head (10, 5)
       // From (12, 10) -> (11, 10)
       expect(next.preys.first.position.x, 11);
       expect(next.preys.first.position.y, 10);
    });

    test('Tension: Prey hitting Snake damages it', () {
       // Snake Head (10, 10) moving UP. Prey at (10, 9).
       // Next tick: Snake -> (10, 9). Collision!
       var state = initialState.copyWith(
          snakeBody: [const GridPoint(10, 10), const GridPoint(10, 11), const GridPoint(10, 12)],
          currentDirection: GridPoint.up,
          nextDirection: GridPoint.up,
          preys: [
             const PreyEntity(
                id: 'test', 
                type: PreyType.angryApple, 
                position: GridPoint(10, 9), 
                spawnTick: 0
             )
          ],
          isFuryActive: false,
       );
       
      final result = ticker.tick(state, []);
      final next = result.state;
       
       // Snake length should decrease (Damage)
       // Start length 3. Damage 1. End length 2.
       expect(next.snakeBody.length, 2);
       // Prey is removed on collision (bounce/die)
       expect(next.preys.isEmpty, true); 
    });

    test('Release: Snake eats prey in Fury Mode', () {
       // Snake Head (10, 10) moving UP. Prey at (10, 9).
       var state = initialState.copyWith(
          snakeBody: [const GridPoint(10, 10)],
          currentDirection: GridPoint.up,
          nextDirection: GridPoint.up,
          preys: [
             const PreyEntity(
                id: 'test', 
                type: PreyType.angryApple, 
                position: GridPoint(10, 9), 
                spawnTick: 0
             )
          ],
          isFuryActive: true, // FURY ON
          furyTimer: 10,
          score: 0,
       );
       
      final result = ticker.tick(state, []);
      final next = result.state;
       
       // Snake NOT damaged
       expect(next.snakeBody.length, 1); 
       // Prey Eaten (Gone)
       expect(next.preys.isEmpty, true);
       // Score increase
       expect(next.score, 10);
       // Fury Extended
       expect(next.furyTimer, greaterThan(10));
    });
    
    test('Combo Meter Fills and Activates Fury', () {
       // Need 5 foods to activate. 0.2 per food.
       var state = initialState.copyWith(furyMeter: 0.8, isFuryActive: false);
       // Place food in front
       state = state.copyWith(
         snakeBody: [const GridPoint(10, 10)],
         currentDirection: GridPoint.up,
         nextDirection: GridPoint.up,
         food: [const GridPoint(10, 9)],
       );
       
      final result = ticker.tick(state, []);
      final next = result.state;
       
       // Should eat, fill meter to 1.0, and activate Fury
       expect(next.isFuryActive, true);
       expect(next.furyMeter, 0.0); // Reset
       expect(next.furyTimer, 50);
    });
  });
}
