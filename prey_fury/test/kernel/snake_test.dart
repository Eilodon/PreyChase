import 'package:flutter_test/flutter_test.dart';
import 'package:prey_fury/kernel/actions/user_intent.dart';
import 'package:prey_fury/kernel/logic/game_ticker.dart';
import 'package:prey_fury/kernel/models/grid_point.dart';
import 'package:prey_fury/kernel/state/game_state.dart';

void main() {
  group('Kernel: GameTicker', () {
    late GameTicker ticker;
    late GameState initialState;

    setUp(() {
      ticker = GameTicker(gridWidth: 10, gridHeight: 10, seed: 123);
      initialState = GameState.initial(gridWidth: 10, gridHeight: 10);
    });

    test('Moves straight up by default', () {
      final result = ticker.tick(initialState, []);
      final next = result.state;
      
      // Initial: Head at (5, 5), Body (5,5), (5,6), (5,7)
      // Moving UP: New Head should be (5, 4)
      expect(next.snakeBody.first, const GridPoint(5, 4));
      expect(next.tick, 1);
    });

    test('Responds to Turn Intent', () {
      final result = ticker.tick(initialState, [UserIntent.turnLeft]);
      final next = result.state;
      
      // Moving Left: New Head should be (4, 5)
      expect(next.snakeBody.first, const GridPoint(4, 5));
      expect(next.currentDirection, GridPoint.left);
    });

    test('Ignores 180 degree turn', () {
      // Current is UP. Down is 180.
      final result = ticker.tick(initialState, [UserIntent.turnDown]);
      final next = result.state;
      
      // Should still move UP
      expect(next.snakeBody.first, const GridPoint(5, 4));
      expect(next.currentDirection, GridPoint.up); // Unchanged
    });

    test('Collision with Wall', () {
      // Teleport head to top edge (5, 0) facing UP
      var state = initialState.copyWith(
        snakeBody: [const GridPoint(5, 0), const GridPoint(5, 1)],
        currentDirection: GridPoint.up,
        nextDirection: GridPoint.up
      );

      final result = ticker.tick(state, []);
      final next = result.state;
      expect(next.status, GameStatus.gameOver);
    });
    
    test('Eating Food grows snake', () {
      // Place food at (5, 4) where we will move
      var state = initialState.copyWith(
         food: [const GridPoint(5, 4)]
      );
      
      final result = ticker.tick(state, []);
      final next = result.state;
      
      expect(next.snakeBody.first, const GridPoint(5, 4)); // Moved to food
      expect(next.score, 10);
      expect(next.snakeBody.length, initialState.snakeBody.length + 1); // Grow
    });
  });
}
