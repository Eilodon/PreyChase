import 'package:test/test.dart';
import 'package:prey_fury/kernel/models/mutation_type.dart';
import 'package:prey_fury/kernel/logic/mutation_logic.dart';

void main() {
  group('Mutation Registry', () {
    test('All 18 mutations have data', () {
      for (final type in MutationType.values) {
        final data = MutationRegistry.get(type);
        expect(data, isNotNull);
        expect(data.name.isNotEmpty, true);
        expect(data.description.isNotEmpty, true);
      }
    });
    
    test('Synergy detection works correctly', () {
      // venomousFangs synergizes with chainReaction
      expect(
        MutationRegistry.hasSynergy(
          MutationType.venomousFangs, 
          MutationType.chainReaction
        ), 
        true
      );
      
      // armoredScales does NOT synergize with speedDemon
      expect(
        MutationRegistry.hasSynergy(
          MutationType.armoredScales, 
          MutationType.speedDemon
        ), 
        false
      );
    });
    
    test('Anti-synergy detection works', () {
      // berserker anti-synergizes with armoredScales
      expect(
        MutationRegistry.hasAntiSynergy(
          MutationType.berserker, 
          MutationType.armoredScales
        ), 
        true
      );
    });
    
    test('Category filters work', () {
      final offensive = MutationRegistry.byCategory(MutationCategory.offensive);
      expect(offensive.length, greaterThanOrEqualTo(5));
      
      for (final m in offensive) {
        expect(m.category, MutationCategory.offensive);
      }
    });
    
    test('Active synergies calculated correctly', () {
      final mutations = [
        MutationType.venomousFangs,
        MutationType.chainReaction,
        MutationType.criticalBite,
      ];
      
      final synergies = MutationRegistry.getActiveSynergies(mutations);
      
      // venomousFangs + chainReaction = 1 synergy
      // chainReaction + criticalBite = 1 synergy
      expect(synergies.length, 2);
    });
  });
  
  group('Mutation Logic', () {
    late MutationLogic logic;
    
    setUp(() {
      logic = MutationLogic();
    });
    
    test('Roll choices returns 3 unique mutations', () {
      final choices = logic.rollChoices(
        count: 3,
        alreadyActive: [],
        currentWave: 10,
      );
      
      expect(choices.length, 3);
      expect(choices.toSet().length, 3); // All unique
    });
    
    test('Already active mutations not offered again', () {
      final active = [MutationType.venomousFangs, MutationType.armoredScales];
      
      final choices = logic.rollChoices(
        count: 3,
        alreadyActive: active,
        currentWave: 10,
      );
      
      for (final choice in choices) {
        expect(active.contains(choice), false);
      }
    });
    
    test('Anti-synergy mutations not offered', () {
      final active = [MutationType.berserker];
      
      final choices = logic.rollChoices(
        count: 10, // Try to get many
        alreadyActive: active,
        currentWave: 15,
      );
      
      // armoredScales should not be offered (anti-synergy with berserker)
      expect(choices.contains(MutationType.armoredScales), false);
    });
    
    test('Synergy bonus calculated correctly', () {
      // No synergies
      expect(logic.calculateSynergyBonus([]), 1.0);
      
      // venomousFangs + chainReaction = 1 synergy = +15%
      expect(
        logic.calculateSynergyBonus([
          MutationType.venomousFangs, 
          MutationType.chainReaction
        ]),
        1.15,
      );
    });
    
    test('Tick effects apply correctly', () {
      // Speed demon gives +20% speed
      final result = logic.applyTickEffects(
        activeMutations: [MutationType.speedDemon],
        currentHealth: 100,
        maxHealth: 100,
        dt: 1.0,
        inCombat: true,
        killStreak: 0,
      );
      
      expect(result.speedModifier, 1.20);
    });
    
    test('Regeneration heals out of combat', () {
      final result = logic.applyTickEffects(
        activeMutations: [MutationType.regeneration],
        currentHealth: 50,
        maxHealth: 100,
        dt: 1.0,
        inCombat: false, // Out of combat
        killStreak: 0,
      );
      
      expect(result.healAmount, greaterThan(0));
    });
    
    test('Blood Thirst scales with kill streak', () {
      final result = logic.applyTickEffects(
        activeMutations: [MutationType.bloodThirst],
        currentHealth: 100,
        maxHealth: 100,
        dt: 1.0,
        inCombat: true,
        killStreak: 10, // 10 kills = +50% speed (capped)
      );
      
      expect(result.speedModifier, 1.50);
    });
    
    test('Berserker damage scales with low HP', () {
      final result = logic.applyTickEffects(
        activeMutations: [MutationType.berserker],
        currentHealth: 10, // 10% HP
        maxHealth: 100,
        dt: 1.0,
        inCombat: true,
        killStreak: 0,
      );
      
      expect(result.damageModifier, closeTo(1.90, 0.01)); // ~+90% damage
    });
    
    test('Kill effects trigger correctly', () {
      final result = logic.applyKillEffects(
        activeMutations: [MutationType.chainReaction],
        damageDone: 10,
        comboCount: 5,
      );
      
      expect(result.triggerExplosion, true);
      expect(result.explosionRadius, greaterThan(0));
    });
    
    test('Damage reduction applies for armored scales', () {
      final damage = logic.applyDamageReduction(
        activeMutations: [MutationType.armoredScales],
        incomingDamage: 100,
      );
      
      expect(damage, 70); // 30% reduction
    });
    
    test('Combo timer multiplier works', () {
      expect(logic.getComboTimerMultiplier([]), 1.0);
      expect(
        logic.getComboTimerMultiplier([MutationType.comboMaster]), 
        1.5
      );
    });
    
    test('Drop rate multiplier works', () {
      expect(logic.getDropRateMultiplier([]), 1.0);
      expect(
        logic.getDropRateMultiplier([MutationType.treasureHunter]), 
        1.5
      );
    });
  });
}
