import 'package:test/test.dart';
import 'package:prey_fury/kernel/logic/game_ticker.dart';
import 'package:prey_fury/kernel/state/game_state.dart';
import 'package:prey_fury/kernel/actions/user_intent.dart';
import 'package:prey_fury/kernel/models/prey.dart';
import 'package:prey_fury/kernel/models/grid_point.dart';
import 'package:prey_fury/kernel/events/game_event.dart';

void main() {
  group('Phase 6: Gameplay Depth', () {
    late GameTicker ticker;
    late GameState initialState;

    setUp(() {
      ticker = GameTicker(gridWidth: 20, gridHeight: 20, seed: 123);
      initialState = GameState.initial(gridWidth: 20, gridHeight: 20);
    });

    test('Manual Fury: Does not auto-activate at 100%', () {
      GameState s = initialState.copyWith(furyMeter: 0.9);
      
      // Simulate eating food to reach 100%
      // Hack: force meter to 1.0 via state manipulation (not food, but let's emulate tick result)
      // Actually we need to loop tick until meter is full? 
      // Or just pass a state with 1.0 meter and see if it activates
      
      s = s.copyWith(furyMeter: 1.0, isFuryActive: false);
      final result = ticker.tick(s, []);
      
      expect(result.state.isFuryActive, false, reason: "Fury should wait for manual trigger");
      expect(result.state.furyMeter, 1.0);
    });

    test('Manual Fury: Activates with UserIntent', () {
      GameState s = initialState.copyWith(furyMeter: 1.0, isFuryActive: false);
      final result = ticker.tick(s, [UserIntent.activateFury]);
      
      expect(result.state.isFuryActive, true, reason: "Fury should activate on input");
      expect(result.state.furyMeter, 0.0, reason: "Meter should drain");
      expect(result.events.whereType<GameEventFuryActivated>().isNotEmpty, true);
    });

    test('Boss Milestones: Spawns at 500', () {
      // Score 490 -> 500
      GameState s = initialState.copyWith(score: 500, bossesDefeated: 0);
      final result = ticker.tick(s, []);
      
      final boss = result.state.preys.where((p) => p.type == PreyType.boss).firstOrNull;
      expect(boss, isNotNull, reason: "Boss should spawn at 500");
      expect(result.state.bossesDefeated, 1, reason: "Milestone should be marked passed");
    });
    
    test('Boss Milestones: Does not spawn again immediately', () {
      // Score 500, Boss Active
      GameState s = initialState.copyWith(score: 510, bossesDefeated: 1); 
      // But we need a boss in the list to simulate active boss? 
      // The ticker check is !bossActive.
      // If we manually add boss to list:
      s = s.copyWith(preys: [PreyEntity(id: 'b', type: PreyType.boss, position: GridPoint(0,0), spawnTick: 0)]);
      
      final result = ticker.tick(s, []);
      expect(result.state.preys.length, 1, reason: "Should not double spawn boss");
    });

    test('Boss Milestones: Spawns at 1500 (2nd milestone)', () {
      // Score 1500, Bosses Defeated 1
      GameState s = initialState.copyWith(score: 1500, bossesDefeated: 1);
      final result = ticker.tick(s, []);
      
      final boss = result.state.preys.where((p) => p.type == PreyType.boss).firstOrNull;
      expect(boss, isNotNull, reason: "Boss 2 should spawn at 1500");
      expect(result.state.bossesDefeated, 2);
    });
    
    test('Prey Variants: GoldenCake flees snake', () {
       // Snake at 10,10. Cake at 10,11 (Adjacent)
       // Should move AWAY (e.g. down to 10,12)
       GridPoint snakePos = GridPoint(10, 10);
       GridPoint cakePos = GridPoint(10, 11);
       
       GameState s = initialState.copyWith(
          snakeBody: [snakePos],
          preys: [
             PreyEntity(
               id: 'c', 
               type: PreyType.goldenCake, 
               position: cakePos, 
               spawnTick: 0,
             )
          ]
       );
       
       // GoldenCake interval is 3. Desperate (alone) -> 2.
       // tick 3 -> nextTick 4. 4 % 2 == 0. Should move.
       final result = ticker.tick(s.copyWith(tick: 3), []);
       
       final movedCake = result.state.preys.first;
       expect(movedCake.position, isNot(GridPoint(10, 10)), reason: "Should not move into snake");
       // Should move away
       expect(movedCake.position.y, greaterThan(11), reason: "Should move Down away from snake");
    });
  });
}
