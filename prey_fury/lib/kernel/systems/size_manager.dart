/// Size Manager - Core size-based eating system for Vạn Cổ Chi Vương
///
/// The "Holy Trinity" of size mechanics:
/// - Can eat entities <= 90% of your size
/// - Get eaten by entities >= 110% of your size
/// - Combat zone: 90-110% (damage-based resolution)

import 'dart:math';

/// Relationship between two entities based on size
enum SizeRelation {
  /// Can eat the other entity (target <= 90% our size)
  canEat,

  /// Will be eaten by the other entity (predator >= 110% our size)
  willBeEaten,

  /// Combat zone - neither can instantly eat, damage determines winner
  combat,
}

/// Visual indicator for size comparison (UI feedback)
enum SizeIndicator {
  /// 🟢 Green - Much smaller, easy meal
  safeToEat,

  /// 🟡 Yellow - Similar size, be careful!
  caution,

  /// 🔴 Red - Much larger, RUN!
  danger,
}

/// Size tier for visual evolution (like Pokémon stages)
enum SizeTier {
  /// Tier 1: Ấu Trùng (0-20% max size) - Tiny, cute
  auTrung(
    name: 'Ấu Trùng',
    nameEn: 'Larva',
    minPercent: 0.0,
    maxPercent: 0.2,
    sizeMultiplier: 0.5,
    speedBonus: 0.2, // Small = faster
    damageMultiplier: 0.5,
  ),

  /// Tier 2: Thiếu Niên (20-40%) - Growing, getting dangerous
  thieuNien(
    name: 'Thiếu Niên',
    nameEn: 'Juvenile',
    minPercent: 0.2,
    maxPercent: 0.4,
    sizeMultiplier: 0.75,
    speedBonus: 0.1,
    damageMultiplier: 0.75,
  ),

  /// Tier 3: Trưởng Thành (40-60%) - Adult, intimidating
  truongThanh(
    name: 'Trưởng Thành',
    nameEn: 'Adult',
    minPercent: 0.4,
    maxPercent: 0.6,
    sizeMultiplier: 1.0,
    speedBonus: 0.0,
    damageMultiplier: 1.0,
  ),

  /// Tier 4: Tinh Anh (60-80%) - Elite, dominant
  tinhAnh(
    name: 'Tinh Anh',
    nameEn: 'Elite',
    minPercent: 0.6,
    maxPercent: 0.8,
    sizeMultiplier: 1.25,
    speedBonus: -0.1, // Bigger = slower
    damageMultiplier: 1.25,
  ),

  /// Tier 5: Cổ Vương (80-100%) - KING, terrifying
  coVuong(
    name: 'Cổ Vương',
    nameEn: 'Ancient King',
    minPercent: 0.8,
    maxPercent: 1.0,
    sizeMultiplier: 1.5,
    speedBonus: -0.2,
    damageMultiplier: 1.5,
  );

  final String name;
  final String nameEn;
  final double minPercent;
  final double maxPercent;
  final double sizeMultiplier;
  final double speedBonus; // Positive = faster, negative = slower
  final double damageMultiplier;

  const SizeTier({
    required this.name,
    required this.nameEn,
    required this.minPercent,
    required this.maxPercent,
    required this.sizeMultiplier,
    required this.speedBonus,
    required this.damageMultiplier,
  });

  /// Get tier from size percentage (0.0 to 1.0)
  static SizeTier fromPercent(double percent) {
    final clamped = percent.clamp(0.0, 1.0);
    for (final tier in SizeTier.values) {
      if (clamped >= tier.minPercent && clamped < tier.maxPercent) {
        return tier;
      }
    }
    return SizeTier.coVuong; // Max tier
  }

  /// Check if this tier is higher than another
  bool isHigherThan(SizeTier other) => index > other.index;

  /// Get next tier (or null if max)
  SizeTier? get nextTier {
    final nextIndex = index + 1;
    if (nextIndex >= SizeTier.values.length) return null;
    return SizeTier.values[nextIndex];
  }

  /// Get previous tier (or null if min)
  SizeTier? get previousTier {
    final prevIndex = index - 1;
    if (prevIndex < 0) return null;
    return SizeTier.values[prevIndex];
  }
}

/// Core size management system
class SizeManager {
  // === CONSTANTS ===

  /// Threshold to eat another entity (target must be <= this ratio of our size)
  static const double eatThreshold = 0.9;

  /// Threshold to be eaten (predator must be >= this ratio of our size)
  static const double eatenThreshold = 1.1;

  /// Maximum size value (100% = this value)
  static const double maxSize = 1000.0;

  /// Minimum size value (spawn size)
  static const double minSize = 50.0;

  /// Starting size for new critters
  static const double startingSize = 100.0;

  // === GROWTH RATES ===

  /// Growth from eating a much smaller entity (<50% our size)
  static const double growthFromTinyPrey = 0.03; // +3%

  /// Growth from eating a smaller entity (50-90% our size)
  static const double growthFromSmallPrey = 0.05; // +5%

  /// Growth from winning combat (90-110% size range)
  static const double growthFromCombatWin = 0.15; // +15%

  /// Growth from eating food pellets
  static const double growthFromFood = 0.01; // +1%

  // === CORE METHODS ===

  /// Get the relationship between two entities based on size
  static SizeRelation getRelation(double mySize, double theirSize) {
    if (theirSize <= 0) return SizeRelation.canEat;
    if (mySize <= 0) return SizeRelation.willBeEaten;

    final ratio = mySize / theirSize;

    if (ratio >= eatenThreshold) {
      // I'm >= 110% their size -> I can eat them
      return SizeRelation.canEat;
    } else if (ratio <= eatThreshold) {
      // I'm <= 90% their size -> They can eat me
      return SizeRelation.willBeEaten;
    } else {
      // 90% < ratio < 110% -> Combat zone
      return SizeRelation.combat;
    }
  }

  /// Check if entity A can eat entity B
  static bool canEat(double predatorSize, double preySize) {
    return getRelation(predatorSize, preySize) == SizeRelation.canEat;
  }

  /// Check if entity A will be eaten by entity B
  static bool willBeEatenBy(double mySize, double predatorSize) {
    return getRelation(mySize, predatorSize) == SizeRelation.willBeEaten;
  }

  /// Check if two entities are in combat zone
  static bool inCombatZone(double sizeA, double sizeB) {
    return getRelation(sizeA, sizeB) == SizeRelation.combat;
  }

  /// Get visual indicator for UI (color coding)
  static SizeIndicator getIndicator(double mySize, double theirSize) {
    final relation = getRelation(mySize, theirSize);

    switch (relation) {
      case SizeRelation.canEat:
        return SizeIndicator.safeToEat;
      case SizeRelation.willBeEaten:
        return SizeIndicator.danger;
      case SizeRelation.combat:
        return SizeIndicator.caution;
    }
  }

  /// Calculate growth amount when eating another entity
  static double calculateGrowth(double mySize, double preySize) {
    final ratio = preySize / mySize;

    if (ratio < 0.5) {
      // Tiny prey
      return mySize * growthFromTinyPrey;
    } else if (ratio < eatThreshold) {
      // Small prey
      return mySize * growthFromSmallPrey;
    } else {
      // Combat win (similar size)
      return mySize * growthFromCombatWin;
    }
  }

  /// Calculate new size after eating
  static double sizeAfterEating(double mySize, double preySize) {
    final growth = calculateGrowth(mySize, preySize);
    return min(mySize + growth, maxSize);
  }

  /// Calculate size loss when taking damage
  static double sizeAfterDamage(double mySize, double damagePercent) {
    final loss = mySize * damagePercent;
    return max(mySize - loss, minSize);
  }

  /// Get current tier from absolute size
  static SizeTier getTier(double size) {
    final percent = (size - minSize) / (maxSize - minSize);
    return SizeTier.fromPercent(percent);
  }

  /// Get size percentage (0.0 to 1.0)
  static double getPercent(double size) {
    return ((size - minSize) / (maxSize - minSize)).clamp(0.0, 1.0);
  }

  /// Convert percentage to absolute size
  static double percentToSize(double percent) {
    return minSize + (percent.clamp(0.0, 1.0) * (maxSize - minSize));
  }

  /// Calculate combat damage based on size difference
  /// Returns damage as percentage (0.0 to 1.0)
  static double calculateCombatDamage(double attackerSize, double defenderSize, double baseDamage) {
    // Size advantage gives damage bonus
    final sizeRatio = attackerSize / defenderSize;
    final sizeBonus = (sizeRatio - 1.0).clamp(-0.3, 0.3); // -30% to +30%

    return baseDamage * (1.0 + sizeBonus);
  }

  /// Check if size changed tier (for evolution events)
  static bool tierChanged(double oldSize, double newSize) {
    return getTier(oldSize) != getTier(newSize);
  }

  /// Get visual scale multiplier for rendering
  static double getVisualScale(double size) {
    final tier = getTier(size);
    final percentInTier = (getPercent(size) - tier.minPercent) /
                          (tier.maxPercent - tier.minPercent);

    // Smooth interpolation within tier
    final baseScale = tier.sizeMultiplier;
    final nextScale = tier.nextTier?.sizeMultiplier ?? (baseScale * 1.2);

    return baseScale + (nextScale - baseScale) * percentInTier * 0.5;
  }

  /// Get speed modifier based on size (bigger = slower)
  static double getSpeedModifier(double size) {
    final tier = getTier(size);
    return 1.0 + tier.speedBonus;
  }

  /// Get damage modifier based on size (bigger = stronger)
  static double getDamageModifier(double size) {
    final tier = getTier(size);
    return tier.damageMultiplier;
  }
}

/// Extension for easier size comparisons
extension SizeComparison on double {
  SizeRelation relationTo(double other) => SizeManager.getRelation(this, other);
  SizeIndicator indicatorFor(double other) => SizeManager.getIndicator(this, other);
  SizeTier get tier => SizeManager.getTier(this);
  double get sizePercent => SizeManager.getPercent(this);
}
