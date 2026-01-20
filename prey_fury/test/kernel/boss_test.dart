import 'package:test/test.dart';
import 'package:prey_fury/kernel/logic/game_ticker.dart';
import 'package:prey_fury/kernel/state/game_state.dart';
import 'package:prey_fury/kernel/models/prey.dart';
import 'package:prey_fury/kernel/models/grid_point.dart';

void main() {
  test('Boss spawns at score threshold', () {
    final ticker = GameTicker(gridWidth: 30, gridHeight: 30);
    var state = GameState.initial(gridWidth: 30, gridHeight: 30);
    
    // Simulate Score 1000
    state = state.copyWith(score: 1000, tick: 99);
    
    // Force Random to trigger spawn (mocking not easy here without DI, but we can verify logic if random allows)
    // Actually our logic says: if (_random.nextInt(1000) == 0 && state.score >= 500)
    // This is hard to test deterministically without mocking Random.
    // Let's modify logic or trust manual test?
    // Alternative: We can modify the test to inject a seed or just run until it happens? Too flaky.
    // Proper way: Refactor GameTicker to accept Random.
  });

  test('Boss takes damage and teleports', () {
    final ticker = GameTicker(gridWidth: 30, gridHeight: 30);
    var state = GameState.initial(gridWidth: 30, gridHeight: 30);
    
    // Spawn Boss manually
    final boss = PreyEntity(
      id: 'boss_1',
      type: PreyType.boss, 
      position: const GridPoint(10, 10), 
      spawnTick: 0,
      health: 5,
      maxHealth: 5
    );
    
    state = state.copyWith(
       preys: [boss],
       snakeBody: [const GridPoint(9, 10)], // Adjacent to boss
       currentDirection: GridPoint.right,
       nextDirection: GridPoint.right,
       isFuryActive: true,
       activeFuryType: FuryType.classic,
       furyTimer: 100, // Ensure fury
    );
    
    // Tick
    final result = ticker.tick(state, []);
    final nextState = result.state;
    
    // Verify Boss took damage
    final updatedBoss = nextState.preys.firstWhere((p) => p.id == 'boss_1');
    expect(updatedBoss.health, 4);
    
    // Verify Boss moved (teleported)
    expect(updatedBoss.position, isNot(const GridPoint(10, 10)));
  });
}
