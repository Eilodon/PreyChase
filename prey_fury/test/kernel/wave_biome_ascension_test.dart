import 'package:test/test.dart';
import 'package:prey_fury/kernel/models/wave_event.dart';
import 'package:prey_fury/kernel/models/biome.dart';
import 'package:prey_fury/kernel/models/ascension.dart';

void main() {
  group('Wave Events', () {
    test('All event types have data', () {
      for (final type in WaveEventType.values) {
        final event = WaveEventRegistry.get(type);
        expect(event, isNotNull);
        expect(event.name.isNotEmpty, true);
        expect(event.announcement.isNotEmpty, true);
      }
    });
    
    test('Category filters work', () {
      final challenges = WaveEventRegistry.challenges;
      expect(challenges.isNotEmpty, true);
      
      for (final e in challenges) {
        expect(e.category, WaveEventCategory.challenge);
      }
    });
    
    test('Active event tracks progress', () {
      final event = ActiveWaveEvent(
        type: WaveEventType.preyRush,
        remainingDuration: 10.0,
        originalDuration: 20.0,
        triggerWave: 5,
      );
      
      expect(event.progress, 0.5); // 50% complete
      expect(event.isExpired, false);
    });
    
    test('Event expires when duration ends', () {
      var event = ActiveWaveEvent(
        type: WaveEventType.goldRush,
        remainingDuration: 1.0,
        originalDuration: 15.0,
        triggerWave: 3,
      );
      
      event = event.tick(1.5); // Tick past duration
      
      expect(event.isExpired, true);
    });
  });
  
  group('Biomes', () {
    test('All biome types have data', () {
      for (final type in BiomeType.values) {
        final data = BiomeRegistry.get(type);
        expect(data, isNotNull);
        expect(data.name.isNotEmpty, true);
      }
    });
    
    test('Biomes unlock at correct waves', () {
      expect(BiomeRegistry.forWave(1).type, BiomeType.swampStart);
      expect(BiomeRegistry.forWave(5).type, BiomeType.lavaField);
      expect(BiomeRegistry.forWave(10).type, BiomeType.iceTundra);
      expect(BiomeRegistry.forWave(15).type, BiomeType.voidRift);
    });
    
    test('Biome modifiers applied', () {
      final lava = BiomeRegistry.get(BiomeType.lavaField);
      expect(lava.damageMultiplier, 1.25); // +25% damage
      
      final ice = BiomeRegistry.get(BiomeType.iceTundra);
      expect(ice.speedMultiplier, 1.3); // +30% speed (slippery)
    });
    
    test('Hazards expire correctly', () {
      var hazard = ActiveHazard(
        id: 'meteor1',
        type: HazardType.meteor,
        x: 100.0,
        y: 100.0,
        radius: 50.0,
        remainingDuration: 2.0,
      );
      
      hazard = hazard.tick(1.0);
      expect(hazard.isExpired, false);
      
      hazard = hazard.tick(1.5);
      expect(hazard.isExpired, true);
    });
  });
  
  group('Ascension', () {
    test('All 20 ascension levels have data', () {
      for (int level = 0; level <= 20; level++) {
        final modifier = AscensionRegistry.getLevel(level);
        expect(modifier, isNotNull);
        expect(modifier.name.isNotEmpty, true);
      }
    });
    
    test('Modifiers accumulate correctly', () {
      final level5Mods = AscensionRegistry.getActiveModifiers(5);
      expect(level5Mods.length, 5); // Levels 0-4 (5 items)
    });
    
    test('Cumulative modifier calculation works', () {
      // Level 1: +10% prey speed
      final preySpeed = AscensionRegistry.getCumulativeModifier(1, 'preySpeed');
      expect(preySpeed, 0.10);
      
      // Level 6 adds +25% prey aggression
      final aggression = AscensionRegistry.getCumulativeModifier(6, 'preyAggression');
      expect(aggression, 0.25);
    });
    
    test('Level 20 IMPOSSIBLE multiplies all modifiers', () {
      // At level 20, all modifiers are multiplied by 1.5
      final preySpeed20 = AscensionRegistry.getCumulativeModifier(20, 'preySpeed');
      // Base 0.10 * 1.5 = 0.15 (using closeTo for floating point)
      expect(preySpeed20, closeTo(0.15, 0.001));
    });
    
    test('Display name formatting', () {
      expect(AscensionRegistry.getDisplayName(0), 'Normal');
      expect(AscensionRegistry.getDisplayName(5), 'Ascension 5');
      expect(AscensionRegistry.getDisplayName(20), 'Ascension 20');
    });
    
    test('Ascension state tracks wins', () {
      var state = const AscensionState(currentLevel: 5);
      state = state.recordWin();
      
      expect(state.highestCompleted, 5);
      expect(state.completionCount[5], 1);
      expect(state.canAscend, true);
    });
    
    test('Can ascend after winning', () {
      var state = const AscensionState(
        currentLevel: 3,
        highestCompleted: 3,
      );
      
      expect(state.canAscend, true);
      
      state = state.ascend();
      expect(state.currentLevel, 4);
    });
    
    test('Cannot ascend past max level', () {
      var state = const AscensionState(
        currentLevel: 20,
        highestCompleted: 20,
      );
      
      expect(state.canAscend, false);
      
      state = state.ascend();
      expect(state.currentLevel, 20); // No change
    });
  });
}
