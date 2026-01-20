/// Mutation Logic - Applying mutation effects during gameplay
/// Part of PREY CHAOS redesign

import 'dart:math';
import '../models/mutation_type.dart';

/// Result of mutation effect application
class MutationEffectResult {
  final double damageModifier;
  final double speedModifier;
  final double healAmount;
  final double furyBonus;
  final bool triggerExplosion;
  final double explosionRadius;
  final bool triggerPoison;
  final double poisonDamage;
  final bool triggerPull;
  final double pullRadius;
  final bool triggerSlowMo;
  final bool triggerRevive;
  
  const MutationEffectResult({
    this.damageModifier = 1.0,
    this.speedModifier = 1.0,
    this.healAmount = 0.0,
    this.furyBonus = 0.0,
    this.triggerExplosion = false,
    this.explosionRadius = 0.0,
    this.triggerPoison = false,
    this.poisonDamage = 0.0,
    this.triggerPull = false,
    this.pullRadius = 0.0,
    this.triggerSlowMo = false,
    this.triggerRevive = false,
  });
  
  MutationEffectResult merge(MutationEffectResult other) {
    return MutationEffectResult(
      damageModifier: damageModifier * other.damageModifier,
      speedModifier: speedModifier * other.speedModifier,
      healAmount: healAmount + other.healAmount,
      furyBonus: furyBonus + other.furyBonus,
      triggerExplosion: triggerExplosion || other.triggerExplosion,
      explosionRadius: max(explosionRadius, other.explosionRadius),
      triggerPoison: triggerPoison || other.triggerPoison,
      poisonDamage: poisonDamage + other.poisonDamage,
      triggerPull: triggerPull || other.triggerPull,
      pullRadius: max(pullRadius, other.pullRadius),
      triggerSlowMo: triggerSlowMo || other.triggerSlowMo,
      triggerRevive: triggerRevive || other.triggerRevive,
    );
  }
}

/// Core mutation logic handler
class MutationLogic {
  final Random _random;
  
  MutationLogic({Random? random}) : _random = random ?? Random();
  
  /// Maximum active mutations
  static const int maxActiveMutations = 6;
  
  /// Roll N mutation choices from the pool
  List<MutationType> rollChoices({
    required int count,
    required List<MutationType> alreadyActive,
    required int currentWave,
  }) {
    // Build weighted pool based on tier
    final pool = <MutationType>[];
    
    for (final type in MutationType.values) {
      final data = MutationRegistry.get(type);
      
      // Skip already active
      if (alreadyActive.contains(type)) continue;
      
      // Check anti-synergies
      bool hasAntiSynergy = false;
      for (final active in alreadyActive) {
        if (MutationRegistry.hasAntiSynergy(type, active)) {
          hasAntiSynergy = true;
          break;
        }
      }
      if (hasAntiSynergy) continue;
      
      // Add to pool based on tier weight
      int weight;
      switch (data.tier) {
        case MutationTier.common:
          weight = 60;
          break;
        case MutationTier.rare:
          weight = 30;
          break;
        case MutationTier.legendary:
          // Legendaries only appear after wave 5
          weight = currentWave >= 5 ? 10 : 0;
          break;
      }
      
      for (int i = 0; i < weight; i++) {
        pool.add(type);
      }
    }
    
    // Pick N unique from pool
    final choices = <MutationType>[];
    final poolCopy = List<MutationType>.from(pool);
    
    while (choices.length < count && poolCopy.isNotEmpty) {
      final index = _random.nextInt(poolCopy.length);
      final choice = poolCopy[index];
      
      if (!choices.contains(choice)) {
        choices.add(choice);
      }
      poolCopy.removeAt(index);
    }
    
    return choices;
  }
  
  /// Calculate synergy bonus multiplier for active mutations
  double calculateSynergyBonus(List<MutationType> activeMutations) {
    final synergies = MutationRegistry.getActiveSynergies(activeMutations);
    // +15% per synergy pair, up to +75% max
    return 1.0 + min(synergies.length * 0.15, 0.75);
  }
  
  /// Apply on-tick effects (passive mutations)
  MutationEffectResult applyTickEffects({
    required List<MutationType> activeMutations,
    required double currentHealth,
    required double maxHealth,
    required double dt,
    required bool inCombat,
    required int killStreak,
  }) {
    var result = const MutationEffectResult();
    
    for (final mutation in activeMutations) {
      switch (mutation) {
        // DEFENSIVE - Passive effects
        case MutationType.armoredScales:
          // Damage reduction handled in damage calculation
          break;
          
        case MutationType.regeneration:
          if (!inCombat) {
            result = result.merge(MutationEffectResult(
              healAmount: 1.0 * dt, // 1 HP per second
            ));
          }
          break;
          
        case MutationType.thornAura:
          // Handled in collision detection
          break;
          
        // UTILITY - Passive effects
        case MutationType.speedDemon:
          result = result.merge(const MutationEffectResult(
            speedModifier: 1.20, // +20% speed
          ));
          break;
          
        case MutationType.timeWarp:
          if (currentHealth / maxHealth < 0.25) {
            result = result.merge(const MutationEffectResult(
              triggerSlowMo: true,
            ));
          }
          break;
          
        // LEGENDARY - Passive effects
        case MutationType.bloodThirst:
          // +5% speed per kill, max 50%
          final bonus = min(killStreak * 0.05, 0.50);
          result = result.merge(MutationEffectResult(
            speedModifier: 1.0 + bonus,
          ));
          break;
          
        case MutationType.berserker:
          // +damage at low HP
          final healthPercent = currentHealth / maxHealth;
          final damageBonus = (1.0 - healthPercent); // Up to +100% at 1 HP
          result = result.merge(MutationEffectResult(
            damageModifier: 1.0 + damageBonus,
          ));
          break;
          
        default:
          break;
      }
    }
    
    return result;
  }
  
  /// Apply on-kill effects
  MutationEffectResult applyKillEffects({
    required List<MutationType> activeMutations,
    required double damageDone,
    required int comboCount,
  }) {
    var result = const MutationEffectResult();
    
    for (final mutation in activeMutations) {
      switch (mutation) {
        case MutationType.venomousFangs:
          result = result.merge(const MutationEffectResult(
            triggerPoison: true,
            poisonDamage: 5.0,
          ));
          break;
          
        case MutationType.chainReaction:
          result = result.merge(MutationEffectResult(
            triggerExplosion: true,
            explosionRadius: 30.0 + (comboCount * 5), // Bigger with combo
          ));
          break;
          
        case MutationType.lifeSteal:
          result = result.merge(MutationEffectResult(
            healAmount: damageDone * 0.10, // 10% lifesteal
          ));
          break;
          
        case MutationType.hungerFrenzy:
          result = result.merge(const MutationEffectResult(
            speedModifier: 1.25, // Temporary speed buff (handle duration elsewhere)
          ));
          break;
          
        default:
          break;
      }
    }
    
    return result;
  }
  
  /// Apply attack modifiers
  MutationEffectResult applyAttackEffects({
    required List<MutationType> activeMutations,
    required double baseDamage,
  }) {
    var result = MutationEffectResult(damageModifier: 1.0);
    
    for (final mutation in activeMutations) {
      switch (mutation) {
        case MutationType.criticalBite:
          // 25% chance for 3x damage
          if (_random.nextDouble() < 0.25) {
            result = result.merge(const MutationEffectResult(
              damageModifier: 3.0,
            ));
          }
          break;
          
        case MutationType.razorTeeth:
          result = result.merge(MutationEffectResult(
            poisonDamage: baseDamage * 0.5, // 50% damage as bleed
            triggerPoison: true,
          ));
          break;
          
        case MutationType.magneticJaw:
          result = result.merge(const MutationEffectResult(
            triggerPull: true,
            pullRadius: 100.0,
          ));
          break;
          
        default:
          break;
      }
    }
    
    return result;
  }
  
  /// Apply damage reduction modifiers
  double applyDamageReduction({
    required List<MutationType> activeMutations,
    required double incomingDamage,
  }) {
    double reduction = 1.0;
    
    for (final mutation in activeMutations) {
      switch (mutation) {
        case MutationType.armoredScales:
          reduction *= 0.70; // -30% damage
          break;
          
        default:
          break;
      }
    }
    
    return incomingDamage * reduction;
  }
  
  /// Check if Second Chance should trigger
  bool checkSecondChance({
    required List<MutationType> activeMutations,
    required bool alreadyUsed,
  }) {
    if (alreadyUsed) return false;
    return activeMutations.contains(MutationType.secondChance);
  }
  
  /// Check if Ghost Phase i-frames are active
  bool checkGhostPhase({
    required List<MutationType> activeMutations,
    required double iFrameTimer,
  }) {
    if (!activeMutations.contains(MutationType.ghostPhase)) return false;
    return iFrameTimer > 0;
  }
  
  /// Get combo timer multiplier
  double getComboTimerMultiplier(List<MutationType> activeMutations) {
    if (activeMutations.contains(MutationType.comboMaster)) {
      return 1.5; // +50% combo duration
    }
    return 1.0;
  }
  
  /// Get drop rate multiplier
  double getDropRateMultiplier(List<MutationType> activeMutations) {
    if (activeMutations.contains(MutationType.treasureHunter)) {
      return 1.5; // +50% drops
    }
    return 1.0;
  }
}
