/// Faction AI - Real AI combat between prey factions
/// Part of PREY CHAOS redesign

import 'dart:math';
import '../models/faction.dart';
import '../models/prey.dart';
import '../models/grid_point.dart';

/// AI decision types
enum FactionAIDecision {
  chasePlayer,
  attackRival,
  supportAlly,
  flee,
  patrol,
}

/// Target selection result
class TargetSelection {
  final FactionAIDecision decision;
  final String? targetId;
  final GridPoint? targetPosition;
  final double priority;
  
  const TargetSelection({
    required this.decision,
    this.targetId,
    this.targetPosition,
    required this.priority,
  });
}

/// Combat action result
class FactionCombatResult {
  final List<String> damagedPreyIds;
  final Map<String, int> damageDealt;
  final List<String> killedPreyIds;
  final List<String> buffedPreyIds;
  final List<String> healedPreyIds;
  
  const FactionCombatResult({
    this.damagedPreyIds = const [],
    this.damageDealt = const {},
    this.killedPreyIds = const [],
    this.buffedPreyIds = const [],
    this.healedPreyIds = const [],
  });
  
  FactionCombatResult merge(FactionCombatResult other) {
    return FactionCombatResult(
      damagedPreyIds: [...damagedPreyIds, ...other.damagedPreyIds],
      damageDealt: {...damageDealt, ...other.damageDealt},
      killedPreyIds: [...killedPreyIds, ...other.killedPreyIds],
      buffedPreyIds: [...buffedPreyIds, ...other.buffedPreyIds],
      healedPreyIds: [...healedPreyIds, ...other.healedPreyIds],
    );
  }
}

/// Core Faction AI Logic
class FactionAI {
  final Random _random;
  
  // Combat ranges
  static const double attackRange = 2.0; // Grid cells
  static const double supportRange = 4.0;
  static const double aggroRange = 8.0;
  
  // Combat stats
  static const int preyVsPreyDamage = 2;
  static const int healAmount = 3;
  static const double speedBuffMultiplier = 1.5;
  
  FactionAI({Random? random}) : _random = random ?? Random();
  
  /// Select target for a prey based on faction behavior
  TargetSelection selectTarget({
    required PreyEntity prey,
    required GridPoint playerPosition,
    required List<PreyEntity> allPrey,
    required FactionWarState factionState,
    required bool playerInFury,
  }) {
    final faction = FactionRegistry.getFactionFor(prey.type);
    if (faction == null) {
      // No faction - always chase player
      return TargetSelection(
        decision: FactionAIDecision.chasePlayer,
        targetPosition: playerPosition,
        priority: 1.0,
      );
    }
    
    final factionData = FactionRegistry.get(faction);
    final distToPlayer = _distance(prey.position, playerPosition);
    
    // === PRIORITY 1: Flee from Fury mode player ===
    if (playerInFury && distToPlayer < aggroRange) {
      return TargetSelection(
        decision: FactionAIDecision.flee,
        targetPosition: _getFleePosition(prey.position, playerPosition),
        priority: 10.0,
      );
    }
    
    // === PRIORITY 2: Support allies (Dessert Cult) ===
    if (factionData.behavior == FactionBehavior.support) {
      final woundedAlly = _findWoundedAlly(prey, allPrey, faction);
      if (woundedAlly != null) {
        return TargetSelection(
          decision: FactionAIDecision.supportAlly,
          targetId: woundedAlly.id,
          targetPosition: woundedAlly.position,
          priority: 8.0,
        );
      }
    }
    
    // === PRIORITY 3: Attack rival faction ===
    final rivalFaction = factionData.rivalFaction;
    final nearbyRival = _findNearestRival(prey, allPrey, rivalFaction);
    
    if (nearbyRival != null) {
      final distToRival = _distance(prey.position, nearbyRival.position);
      
      // Check if should attack rival vs player
      final rivalPriority = factionData.aggressionToRival;
      final playerPriority = factionData.aggressionToPlayer;
      
      // Compare distances and aggression levels
      if (distToRival < aggroRange && 
          (distToRival < distToPlayer || rivalPriority > playerPriority)) {
        return TargetSelection(
          decision: FactionAIDecision.attackRival,
          targetId: nearbyRival.id,
          targetPosition: nearbyRival.position,
          priority: rivalPriority * (aggroRange - distToRival),
        );
      }
    }
    
    // === PRIORITY 4: Chase player ===
    if (distToPlayer < aggroRange * 1.5) {
      return TargetSelection(
        decision: FactionAIDecision.chasePlayer,
        targetPosition: playerPosition,
        priority: factionData.aggressionToPlayer * (aggroRange - distToPlayer),
      );
    }
    
    // === DEFAULT: Patrol ===
    return TargetSelection(
      decision: FactionAIDecision.patrol,
      targetPosition: _getPatrolPosition(prey.position),
      priority: 0.1,
    );
  }
  
  /// Process faction combat for a tick
  FactionCombatResult processCombat({
    required List<PreyEntity> allPrey,
    required double dt,
  }) {
    var result = const FactionCombatResult();
    
    for (final prey in allPrey) {
      if (prey.status != PreyStatus.active) continue;
      
      final faction = FactionRegistry.getFactionFor(prey.type);
      if (faction == null) continue;
      
      final factionData = FactionRegistry.get(faction);
      
      // Check for nearby enemies
      for (final other in allPrey) {
        if (other.id == prey.id) continue;
        if (other.status != PreyStatus.active) continue;
        
        final otherFaction = FactionRegistry.getFactionFor(other.type);
        if (otherFaction == null) continue;
        
        // Check if rivals
        if (FactionRegistry.areRivals(faction, otherFaction)) {
          final dist = _distance(prey.position, other.position);
          
          if (dist <= attackRange) {
            // Attack!
            result = result.merge(FactionCombatResult(
              damagedPreyIds: [other.id],
              damageDealt: {other.id: preyVsPreyDamage},
            ));
          }
        }
        
        // Check for support actions (same faction)
        if (faction == otherFaction && 
            factionData.behavior == FactionBehavior.support) {
          final dist = _distance(prey.position, other.position);
          
          if (dist <= supportRange) {
            // Heal wounded allies
            if (other.health < other.maxHealth) {
              result = result.merge(FactionCombatResult(
                healedPreyIds: [other.id],
              ));
            }
          }
        }
      }
    }
    
    return result;
  }
  
  /// Apply combat results to prey list
  List<PreyEntity> applyCombatResults({
    required List<PreyEntity> preys,
    required FactionCombatResult result,
  }) {
    return preys.map((prey) {
      var updated = prey;
      
      // Apply damage
      if (result.damageDealt.containsKey(prey.id)) {
        final damage = result.damageDealt[prey.id]!;
        final newHealth = prey.health - damage;
        
        if (newHealth <= 0) {
          updated = updated.copyWith(
            status: PreyStatus.eaten, // Killed by faction
            health: 0,
          );
        } else {
          updated = updated.copyWith(health: newHealth);
        }
      }
      
      // Apply healing
      if (result.healedPreyIds.contains(prey.id)) {
        final newHealth = min(prey.health + healAmount, prey.maxHealth);
        updated = updated.copyWith(health: newHealth);
      }
      
      return updated;
    }).toList();
  }
  
  /// Calculate movement for a prey based on AI decision
  GridPoint calculateMovement({
    required PreyEntity prey,
    required TargetSelection target,
    required int currentTick,
  }) {
    // Check move interval
    if (currentTick % prey.moveInterval != 0) {
      return prey.position; // Don't move this tick
    }
    
    final current = prey.position;
    final goalPos = target.targetPosition;
    
    if (goalPos == null) return current;
    
    switch (target.decision) {
      case FactionAIDecision.flee:
        // Move away from target
        return _moveAwayFrom(current, goalPos);
        
      case FactionAIDecision.chasePlayer:
      case FactionAIDecision.attackRival:
      case FactionAIDecision.supportAlly:
        // Move toward target
        return _moveToward(current, goalPos);
        
      case FactionAIDecision.patrol:
        // Random movement
        return _randomStep(current);
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════════════════════
  
  double _distance(GridPoint a, GridPoint b) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    return sqrt(dx * dx + dy * dy);
  }
  
  PreyEntity? _findWoundedAlly(
    PreyEntity prey,
    List<PreyEntity> allPrey,
    PreyFaction faction,
  ) {
    PreyEntity? wounded;
    double lowestHealth = double.infinity;
    
    for (final other in allPrey) {
      if (other.id == prey.id) continue;
      if (other.status != PreyStatus.active) continue;
      
      final otherFaction = FactionRegistry.getFactionFor(other.type);
      if (otherFaction != faction) continue;
      
      final healthPercent = other.health / other.maxHealth;
      if (healthPercent < 1.0 && healthPercent < lowestHealth) {
        lowestHealth = healthPercent;
        wounded = other;
      }
    }
    
    return wounded;
  }
  
  PreyEntity? _findNearestRival(
    PreyEntity prey,
    List<PreyEntity> allPrey,
    PreyFaction rivalFaction,
  ) {
    PreyEntity? nearest;
    double nearestDist = double.infinity;
    
    for (final other in allPrey) {
      if (other.id == prey.id) continue;
      if (other.status != PreyStatus.active) continue;
      
      final otherFaction = FactionRegistry.getFactionFor(other.type);
      if (otherFaction != rivalFaction) continue;
      
      final dist = _distance(prey.position, other.position);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = other;
      }
    }
    
    return nearest;
  }
  
  GridPoint _getFleePosition(GridPoint current, GridPoint threat) {
    // Move in opposite direction
    final dx = current.x - threat.x;
    final dy = current.y - threat.y;
    
    // Normalize and scale
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return GridPoint(current.x + 1, current.y);
    
    return GridPoint(
      current.x + (dx / dist * 3).round(),
      current.y + (dy / dist * 3).round(),
    );
  }
  
  GridPoint _getPatrolPosition(GridPoint current) {
    // Random nearby position
    return GridPoint(
      current.x + _random.nextInt(5) - 2,
      current.y + _random.nextInt(5) - 2,
    );
  }
  
  GridPoint _moveToward(GridPoint current, GridPoint target) {
    final dx = (target.x - current.x).sign;
    final dy = (target.y - current.y).sign;
    return GridPoint(current.x + dx, current.y + dy);
  }
  
  GridPoint _moveAwayFrom(GridPoint current, GridPoint threat) {
    final dx = (current.x - threat.x).sign;
    final dy = (current.y - threat.y).sign;
    return GridPoint(current.x + dx, current.y + dy);
  }
  
  GridPoint _randomStep(GridPoint current) {
    final directions = [
      GridPoint(0, -1), GridPoint(0, 1),
      GridPoint(-1, 0), GridPoint(1, 0),
    ];
    final dir = directions[_random.nextInt(4)];
    return GridPoint(current.x + dir.x, current.y + dir.y);
  }
}
