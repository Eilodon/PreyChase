import 'package:test/test.dart';
import 'package:prey_fury/kernel/state/game_state.dart';
import 'package:prey_fury/kernel/logic/game_ticker.dart';
import 'package:prey_fury/kernel/models/grid_point.dart';
import 'package:prey_fury/kernel/models/prey.dart';

void main() {
  late GameTicker ticker;
  late GameState initialState;

  setUp(() {
    ticker = GameTicker(gridWidth: 20, gridHeight: 20);
    initialState = GameState.initial(gridWidth: 20, gridHeight: 20);
  });

  group('Emotional AI', () {
    test('Prey becomes Terrified when Fury activates', () {
      var state = initialState.copyWith(
        preys: [
          PreyEntity(id: 'p1', type: PreyType.angryApple, position: const GridPoint(5, 5), spawnTick: 0),
        ],
        isFuryActive: false,
      );

      // Force Fury activation
      var furyState = state.copyWith(isFuryActive: true, furyTimer: 100);
      
      final result = ticker.tick(furyState, []);
      expect(result.state.preys.first.emotion, PreyEmotion.terrified);
    });

    test('Terrified Prey runs AWAY from snake', () {
      // Snake head at (10, 10)
      // Prey at (10, 9) (Above head)
      // Should move UP to (10, 8), further from head
      var state = initialState.copyWith(
        snakeBody: [const GridPoint(10, 10)],
        preys: [
          PreyEntity(id: 'p1', type: PreyType.angryApple, position: const GridPoint(10, 9), spawnTick: 0, emotion: PreyEmotion.terrified),
        ],
        isFuryActive: true,
        furyTimer: 100,
        tick: 4, // Next tick 5 triggers move (interval 5)
      );

      final result = ticker.tick(state, []);
      final prey = result.state.preys.first;
      
      expect(prey.position, const GridPoint(10, 8), reason: "Prey should move away from (10,10) to (10,8)");
    });
  });

  group('Fury Types', () {
    test('Lightning Fury pulls nearby prey to head (Kill)', () {
      // Snake at (10, 10). Prey at (12, 10) (Distance 2, within 3)
      var state = initialState.copyWith(
        snakeBody: [const GridPoint(10, 10)],
        preys: [
          PreyEntity(id: 'p1', type: PreyType.angryApple, position: const GridPoint(12, 10), spawnTick: 0),
        ],
        isFuryActive: true,
        furyTimer: 100,
        activeFuryType: FuryType.lightning,
      );

      final result = ticker.tick(state, []);
      // Should be eaten or moved to head
      // In our logic, we move them to snakeHead (collision happens next tick or same tick depending on order)
      // Actually Logic A.3 in GameTicker checks collision AFTER movement.
      // And `_applyFuryEffects` happens BEFORE collision check.
      // So prey should be collided and removed/eaten in the same tick if moved to head.
      
      // Let's check if prey is gone (eaten)
      expect(result.state.preys, isEmpty);
      expect(result.events.where((e) => e.toString().contains('GameEventSnakeAtePrey')), isNotEmpty); // Check event if possible, or score
      expect(result.state.score, greaterThan(initialState.score));
    });

    test('Void Fury pulls ALL prey closer', () {
      // Snake at (10, 10). Prey at (15, 10) (Far away)
      var state = initialState.copyWith(
        snakeBody: [const GridPoint(10, 10)],
        preys: [
          PreyEntity(id: 'p1', type: PreyType.angryApple, position: const GridPoint(15, 10), spawnTick: 0),
        ],
        isFuryActive: true,
        furyTimer: 100,
        activeFuryType: FuryType.voidFury,
      );

      // Void effect happens every tick
      final result = ticker.tick(state, []);
      final prey = result.state.preys.first;
      
      // Should move from 15 to 14 (towards 10)
      expect(prey.position, const GridPoint(14, 10));
    });
  });
  
  group('Style System', () {
    test('Combo count produces correct Style Rating', () {
       var s = initialState.copyWith(comboCount: 4);
       expect(s.comboRating, 'D');
       
       s = initialState.copyWith(comboCount: 12);
       expect(s.comboRating, 'B');
       
       s = initialState.copyWith(comboCount: 55);
       expect(s.comboRating, 'SSS');
    });
  });
}
