import 'dart:math';
import 'package:flame/components.dart';
import '../models/power_up.dart';
import 'crocodile_player.dart';

/// Manages player's active power-ups and applies their effects
/// Handles power-up selection, stat modifications, and rarity-based generation
class PowerUpManager extends Component {
  final CrocodilePlayer player;
  final Random _rnd = Random();

  // Active power-ups (id -> PowerUp with stacks)
  final Map<String, PowerUp> _activePowerUps = {};

  // Selection state
  bool isSelectingPowerUp = false;
  List<PowerUp> currentOffers = [];
  void Function(List<PowerUp>)? onPowerUpOffered;
  void Function()? onSelectionComplete;

  PowerUpManager({required this.player});

  /// Gets all active power-ups
  List<PowerUp> get activePowerUps => _activePowerUps.values.toList();

  /// Checks if a power-up is active
  bool hasPowerUp(String id) => _activePowerUps.containsKey(id);

  /// Gets stack count for a power-up (0 if not active)
  int getStacks(String id) => _activePowerUps[id]?.stacks ?? 0;

  /// Generates 3 random power-up offers based on rarity weights
  void offerPowerUpSelection() {
    if (isSelectingPowerUp) return; // Already selecting

    // Get available power-ups (exclude maxed non-stackable ones)
    final available = PowerUp.registry.values.where((powerUp) {
      final active = _activePowerUps[powerUp.id];
      if (active == null) return true; // Not acquired yet
      return active.canStack; // Can still stack
    }).toList();

    if (available.isEmpty) {
      // All power-ups maxed out (very rare!)
      return;
    }

    // Generate 3 offers with rarity weights
    currentOffers.clear();
    final selectedIds = <String>{};

    for (int i = 0; i < 3 && available.length > selectedIds.length; i++) {
      final powerUp = _selectWeightedRandom(available, selectedIds);
      if (powerUp != null) {
        currentOffers.add(powerUp.copy());
        selectedIds.add(powerUp.id);
      }
    }

    isSelectingPowerUp = true;
    onPowerUpOffered?.call(currentOffers);
  }

  /// Selects a weighted random power-up based on rarity
  PowerUp? _selectWeightedRandom(List<PowerUp> available, Set<String> exclude) {
    // Filter out already selected
    final candidates = available.where((p) => !exclude.contains(p.id)).toList();
    if (candidates.isEmpty) return null;

    // Lucky Croc increases rare drop rates
    final hasLucky = hasPowerUp('lucky');

    // Rarity weights (with Lucky boost)
    double getWeight(PowerUpRarity rarity) {
      switch (rarity) {
        case PowerUpRarity.common:
          return hasLucky ? 50.0 : 60.0; // 60% -> 50% with lucky
        case PowerUpRarity.rare:
          return hasLucky ? 35.0 : 30.0; // 30% -> 35% with lucky
        case PowerUpRarity.epic:
          return hasLucky ? 12.0 : 9.0; // 9% -> 12% with lucky
        case PowerUpRarity.legendary:
          return hasLucky ? 3.0 : 1.0; // 1% -> 3% with lucky
      }
    }

    // Calculate total weight
    final totalWeight = candidates.fold<double>(
      0.0,
      (sum, p) => sum + getWeight(p.rarity),
    );

    // Random selection
    double random = _rnd.nextDouble() * totalWeight;
    for (final powerUp in candidates) {
      random -= getWeight(powerUp.rarity);
      if (random <= 0) {
        return powerUp;
      }
    }

    return candidates.last; // Fallback
  }

  /// Player selects a power-up from current offers
  void selectPowerUp(int index) {
    if (!isSelectingPowerUp || index < 0 || index >= currentOffers.length) {
      return;
    }

    final selected = currentOffers[index];
    addPowerUp(selected.id);

    // Clear selection state
    isSelectingPowerUp = false;
    currentOffers.clear();
    onSelectionComplete?.call();
  }

  /// Adds or stacks a power-up
  void addPowerUp(String id) {
    final powerUp = PowerUp.registry[id];
    if (powerUp == null) return;

    if (_activePowerUps.containsKey(id)) {
      // Stack existing
      final active = _activePowerUps[id]!;
      if (active.canStack) {
        active.stacks++;
        _applyPowerUpEffect(id, active.stacks);
      }
    } else {
      // Add new
      final newPowerUp = powerUp.copy();
      newPowerUp.stacks = 1;
      _activePowerUps[id] = newPowerUp;
      _applyPowerUpEffect(id, 1);
    }
  }

  /// Applies power-up effects to player stats
  void _applyPowerUpEffect(String id, int stacks) {
    switch (id) {
      // === OFFENSIVE ===
      case 'fury_duration':
        player.furyDuration = 5.0 + (stacks * 2.0); // Base 5s + 2s per stack
        break;

      case 'fury_damage':
        player.furyDamageMultiplier = 1.0 + (stacks * 0.5); // +50% per stack
        break;

      case 'magnetic_range':
        player.magneticRange = 50.0 + (stacks * 25.0); // Base 50 + 25 per stack
        break;

      case 'chain_fury':
        player.furyChainEnabled = true;
        break;

      case 'rage_mode':
        player.autoFuryEnabled = true;
        player.autoFuryThreshold = 30.0; // Activate at 30% HP
        break;

      // === DEFENSIVE ===
      case 'max_health':
        player.maxHealth = 100.0 + (stacks * 20.0); // +20 HP per stack
        player.health = player.maxHealth; // Heal to max
        break;

      case 'health_regen':
        player.healthRegenRate = stacks * 2.0; // +2 HP/s per stack
        break;

      case 'armor':
        player.damageReduction = stacks * 0.1; // 10% per stack
        break;

      case 'second_chance':
        player.hasSecondChance = true;
        break;

      case 'invincibility_frames':
        player.invincibilityEnabled = true;
        player.invincibilityDuration = 1.0;
        break;

      // === MOBILITY ===
      case 'move_speed':
        player.speedMultiplier = 1.0 + (stacks * 0.15); // +15% per stack
        break;

      case 'dash_ability':
        player.dashEnabled = true;
        break;

      case 'dash_cooldown':
        player.dashCooldownMultiplier = 1.0 - (stacks * 0.2); // -20% per stack
        break;

      case 'teleport':
        player.teleportEnabled = true;
        break;

      case 'time_slow':
        player.timeWarpEnabled = true;
        break;

      // === UTILITY ===
      case 'score_multiplier':
        player.scoreMultiplier = 1.0 + (stacks * 0.25); // +25% per stack
        break;

      case 'fury_gain':
        player.furyGainMultiplier = 1.0 + (stacks * 0.25); // +25% per stack
        break;

      case 'xp_boost':
        player.xpMultiplier = 1.0 + (stacks * 0.5); // +50% per stack
        break;

      case 'magnet':
        player.itemMagnetEnabled = true;
        player.itemMagnetRange = 150.0;
        break;

      case 'lucky':
        // Lucky is handled in _selectWeightedRandom
        break;
    }
  }

  /// Resets all power-ups (for new run)
  void reset() {
    _activePowerUps.clear();
    isSelectingPowerUp = false;
    currentOffers.clear();

    // Reset player stats to defaults
    player.furyDuration = 5.0;
    player.furyDamageMultiplier = 1.0;
    player.magneticRange = 50.0;
    player.furyChainEnabled = false;
    player.autoFuryEnabled = false;
    player.maxHealth = 100.0;
    player.healthRegenRate = 0.0;
    player.damageReduction = 0.0;
    player.hasSecondChance = false;
    player.invincibilityEnabled = false;
    player.speedMultiplier = 1.0;
    player.dashEnabled = false;
    player.dashCooldownMultiplier = 1.0;
    player.teleportEnabled = false;
    player.timeWarpEnabled = false;
    player.scoreMultiplier = 1.0;
    player.furyGainMultiplier = 1.0;
    player.xpMultiplier = 1.0;
    player.itemMagnetEnabled = false;
  }

  /// Debug: Print all active power-ups
  void printActivePowerUps() {
    print('=== ACTIVE POWER-UPS ===');
    for (final powerUp in _activePowerUps.values) {
      print('${powerUp.icon} ${powerUp.name} (${powerUp.stacks}x)');
    }
    print('========================');
  }
}
