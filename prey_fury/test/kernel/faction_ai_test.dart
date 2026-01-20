import 'package:test/test.dart';
import 'package:prey_fury/kernel/models/faction.dart';
import 'package:prey_fury/kernel/models/prey.dart';
import 'package:prey_fury/kernel/models/grid_point.dart';
import 'package:prey_fury/kernel/logic/faction_ai.dart';

void main() {
  group('Faction Registry', () {
    test('All 4 factions have data', () {
      for (final faction in PreyFaction.values) {
        final data = FactionRegistry.get(faction);
        expect(data, isNotNull);
        expect(data.name.isNotEmpty, true);
      }
    });
    
    test('Factions have correct rivalries', () {
      // Fruit Gang vs Junk Food Mafia
      expect(
        FactionRegistry.areRivals(PreyFaction.fruitGang, PreyFaction.junkFoodMafia),
        true
      );
      
      // Ninja Clan vs Dessert Cult
      expect(
        FactionRegistry.areRivals(PreyFaction.ninjaClan, PreyFaction.dessertCult),
        true
      );
      
      // Non-rivals
      expect(
        FactionRegistry.areRivals(PreyFaction.fruitGang, PreyFaction.ninjaClan),
        false
      );
    });
    
    test('Prey type maps to correct faction', () {
      expect(
        FactionRegistry.getFactionFor(PreyType.angryApple),
        PreyFaction.fruitGang
      );
      expect(
        FactionRegistry.getFactionFor(PreyType.zombieBurger),
        PreyFaction.junkFoodMafia
      );
    });
  });
  
  group('Faction War State', () {
    test('Initial state has equal faction strength', () {
      const state = FactionWarState();
      
      for (final faction in PreyFaction.values) {
        expect(state.factionStrength[faction], 1.0);
      }
    });
    
    test('Leader death weakens faction', () {
      const state = FactionWarState();
      final newState = state.onLeaderDeath(PreyFaction.fruitGang);
      
      expect(newState.factionStrength[PreyFaction.fruitGang], 0.5);
      expect(newState.leaderAlive[PreyFaction.fruitGang], 0);
    });
    
    test('Dominant faction calculated correctly', () {
      const state = FactionWarState(
        factionStrength: {
          PreyFaction.fruitGang: 1.0,
          PreyFaction.junkFoodMafia: 0.3,
          PreyFaction.ninjaClan: 0.4,
          PreyFaction.dessertCult: 0.3,
        },
      );
      
      expect(state.calculateDominant(), PreyFaction.fruitGang);
    });
    
    test('No dominant when strengths are close', () {
      const state = FactionWarState(
        factionStrength: {
          PreyFaction.fruitGang: 0.8,
          PreyFaction.junkFoodMafia: 0.7,
          PreyFaction.ninjaClan: 0.6,
          PreyFaction.dessertCult: 0.5,
        },
      );
      
      // No faction is 0.4 ahead
      expect(state.calculateDominant(), isNull);
    });
  });
  
  group('Faction AI', () {
    late FactionAI ai;
    
    setUp(() {
      ai = FactionAI();
    });
    
    test('Prey flees during Fury mode', () {
      final prey = PreyEntity(
        id: 'p1',
        type: PreyType.angryApple,
        position: const GridPoint(10, 10),
        spawnTick: 0,
      );
      
      final target = ai.selectTarget(
        prey: prey,
        playerPosition: const GridPoint(11, 10), // Close
        allPrey: [prey],
        factionState: const FactionWarState(),
        playerInFury: true, // Fury active!
      );
      
      expect(target.decision, FactionAIDecision.flee);
    });
    
    test('Prey attacks rival faction', () {
      final fruitPrey = PreyEntity(
        id: 'fruit1',
        type: PreyType.angryApple,
        position: const GridPoint(10, 10),
        spawnTick: 0,
      );
      
      final junkPrey = PreyEntity(
        id: 'junk1',
        type: PreyType.zombieBurger, // Rival faction
        position: const GridPoint(12, 10), // Nearby
        spawnTick: 0,
      );
      
      final target = ai.selectTarget(
        prey: fruitPrey,
        playerPosition: const GridPoint(20, 20), // Far away
        allPrey: [fruitPrey, junkPrey],
        factionState: const FactionWarState(),
        playerInFury: false,
      );
      
      expect(target.decision, FactionAIDecision.attackRival);
      expect(target.targetId, 'junk1');
    });
    
    test('Dessert Cult supports wounded allies', () {
      final healerPrey = PreyEntity(
        id: 'healer1',
        type: PreyType.goldenCake, // Dessert Cult = support
        position: const GridPoint(10, 10),
        spawnTick: 0,
      );
      
      final woundedAlly = PreyEntity(
        id: 'wounded1',
        type: PreyType.goldenCake,
        position: const GridPoint(12, 10),
        spawnTick: 0,
        health: 1,
        maxHealth: 5, // Low HP
      );
      
      final target = ai.selectTarget(
        prey: healerPrey,
        playerPosition: const GridPoint(20, 20),
        allPrey: [healerPrey, woundedAlly],
        factionState: const FactionWarState(),
        playerInFury: false,
      );
      
      expect(target.decision, FactionAIDecision.supportAlly);
    });
    
    test('Combat damages enemy prey', () {
      final attacker = PreyEntity(
        id: 'attacker',
        type: PreyType.angryApple, // Fruit Gang
        position: const GridPoint(10, 10),
        spawnTick: 0,
      );
      
      final target = PreyEntity(
        id: 'target',
        type: PreyType.zombieBurger, // Rival: Junk Food Mafia
        position: const GridPoint(11, 10), // Within attack range (2.0)
        spawnTick: 0,
        health: 5,
      );
      
      final result = ai.processCombat(
        allPrey: [attacker, target],
        dt: 1.0,
      );
      
      expect(result.damagedPreyIds, contains('target'));
    });
    
    test('Combat applies damage correctly', () {
      final preys = [
        PreyEntity(
          id: 'target',
          type: PreyType.zombieBurger,
          position: const GridPoint(10, 10),
          spawnTick: 0,
          health: 5,
          maxHealth: 5,
        ),
      ];
      
      final result = FactionCombatResult(
        damagedPreyIds: ['target'],
        damageDealt: {'target': 3},
      );
      
      final updatedPreys = ai.applyCombatResults(
        preys: preys,
        result: result,
      );
      
      expect(updatedPreys.first.health, 2); // 5 - 3 = 2
    });
  });
}
