/// Lightning System - Thiên Kiếp Hazard for Vạn Cổ Chi Vương
///
/// The signature hazard that:
/// - Targets larger critters more often (size-weighted)
/// - Has clear telegraph (1.2s warning)
/// - Deals % max HP damage
/// - Can be dodged with skill

import 'dart:math';
import 'package:flutter/material.dart';

/// Lightning strike state
enum LightningState {
  /// No active lightning
  idle,

  /// Warning phase - red circle showing where lightning will hit
  warning,

  /// Strike phase - lightning hits the target area
  striking,

  /// Aftermath - brief visual effect after strike
  aftermath,
}

/// Single lightning strike data
class LightningStrike {
  final String id;
  final double x;
  final double y;
  final double radius;
  final double damage;
  final LightningState state;
  final double stateTimer;
  final String? targetId; // Optional: tracked target

  const LightningStrike({
    required this.id,
    required this.x,
    required this.y,
    this.radius = 80.0,
    this.damage = 0.4, // 40% max HP
    this.state = LightningState.warning,
    this.stateTimer = 0,
    this.targetId,
  });

  LightningStrike copyWith({
    String? id,
    double? x,
    double? y,
    double? radius,
    double? damage,
    LightningState? state,
    double? stateTimer,
    String? targetId,
  }) {
    return LightningStrike(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius ?? this.radius,
      damage: damage ?? this.damage,
      state: state ?? this.state,
      stateTimer: stateTimer ?? this.stateTimer,
      targetId: targetId ?? this.targetId,
    );
  }

  /// Is this strike still active?
  bool get isActive => state != LightningState.idle;

  /// Is in warning phase?
  bool get isWarning => state == LightningState.warning;

  /// Is currently striking?
  bool get isStriking => state == LightningState.striking;
}

/// Target data for weighted selection
class LightningTarget {
  final String id;
  final double x;
  final double y;
  final double size;
  final double weight; // Calculated selection weight

  const LightningTarget({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    this.weight = 1.0,
  });
}

/// Lightning System - Pure game logic
class LightningSystem {
  // === CONSTANTS ===

  /// Warning duration before strike (seconds)
  static const double warningDuration = 1.2;

  /// Strike duration (visual effect)
  static const double strikeDuration = 0.15;

  /// Aftermath duration (lingering effect)
  static const double aftermathDuration = 0.3;

  /// Base strike radius
  static const double baseRadius = 80.0;

  /// Base damage (% of max HP)
  static const double baseDamage = 0.40; // 40%

  /// Damage inside safe zone (reduced)
  static const double inZoneDamage = 0.20; // 20%

  /// Damage in sudden death
  static const double suddenDeathDamage = 0.30; // 30%

  /// Minimum weight for selection
  static const double minWeight = 0.1;

  /// I-frames after being hit
  static const double iFramesDuration = 1.0;

  // === STATE ===

  final Random _random = Random();
  final List<LightningStrike> _activeStrikes = [];
  double _timeSinceLastStrike = 0;
  int _strikeCounter = 0;

  List<LightningStrike> get activeStrikes => List.unmodifiable(_activeStrikes);

  // === CALLBACKS ===

  void Function(LightningStrike strike)? onWarningStart;
  void Function(LightningStrike strike)? onStrike;
  void Function(LightningStrike strike, String targetId)? onHit;
  void Function(LightningStrike strike)? onStrikeEnd;

  // === UPDATE LOOP ===

  void update(double dt, {required double strikeInterval}) {
    // Update timer
    _timeSinceLastStrike += dt;

    // Update active strikes
    _updateStrikes(dt);

    // Check if should spawn new strike
    if (strikeInterval > 0 && _timeSinceLastStrike >= strikeInterval) {
      _timeSinceLastStrike = 0;
      // Note: Actual strike creation needs target data from game
    }
  }

  void _updateStrikes(double dt) {
    final toRemove = <LightningStrike>[];

    for (int i = 0; i < _activeStrikes.length; i++) {
      final strike = _activeStrikes[i];
      final newTimer = strike.stateTimer + dt;

      switch (strike.state) {
        case LightningState.warning:
          if (newTimer >= warningDuration) {
            // Transition to strike
            _activeStrikes[i] = strike.copyWith(
              state: LightningState.striking,
              stateTimer: 0,
            );
            onStrike?.call(_activeStrikes[i]);
          } else {
            _activeStrikes[i] = strike.copyWith(stateTimer: newTimer);
          }
          break;

        case LightningState.striking:
          if (newTimer >= strikeDuration) {
            // Transition to aftermath
            _activeStrikes[i] = strike.copyWith(
              state: LightningState.aftermath,
              stateTimer: 0,
            );
          } else {
            _activeStrikes[i] = strike.copyWith(stateTimer: newTimer);
          }
          break;

        case LightningState.aftermath:
          if (newTimer >= aftermathDuration) {
            // Strike complete
            toRemove.add(strike);
            onStrikeEnd?.call(strike);
          } else {
            _activeStrikes[i] = strike.copyWith(stateTimer: newTimer);
          }
          break;

        case LightningState.idle:
          toRemove.add(strike);
          break;
      }
    }

    // Remove completed strikes
    for (final strike in toRemove) {
      _activeStrikes.remove(strike);
    }
  }

  // === STRIKE CREATION ===

  /// Create a new lightning strike targeting a position
  LightningStrike createStrike({
    required double x,
    required double y,
    double? radius,
    double? damage,
    String? targetId,
  }) {
    _strikeCounter++;
    final strike = LightningStrike(
      id: 'lightning_$_strikeCounter',
      x: x,
      y: y,
      radius: radius ?? baseRadius,
      damage: damage ?? baseDamage,
      state: LightningState.warning,
      stateTimer: 0,
      targetId: targetId,
    );

    _activeStrikes.add(strike);
    onWarningStart?.call(strike);

    return strike;
  }

  /// Create a strike targeting a specific entity (with weighted selection)
  LightningStrike? createTargetedStrike({
    required List<LightningTarget> targets,
    bool inSafeZone = false,
    bool isSuddenDeath = false,
  }) {
    if (targets.isEmpty) return null;

    // Calculate weights based on size (bigger = more likely to be hit)
    final weights = targets.map((t) {
      // Size squared for stronger weight on large targets
      return max(minWeight, t.size * t.size / 10000);
    }).toList();

    // Weighted random selection
    final totalWeight = weights.reduce((a, b) => a + b);
    var roll = _random.nextDouble() * totalWeight;

    LightningTarget? selected;
    for (int i = 0; i < targets.length; i++) {
      roll -= weights[i];
      if (roll <= 0) {
        selected = targets[i];
        break;
      }
    }

    selected ??= targets.last;

    // Determine damage
    double damage = baseDamage;
    if (isSuddenDeath) {
      damage = suddenDeathDamage;
    } else if (inSafeZone) {
      damage = inZoneDamage;
    }

    return createStrike(
      x: selected.x,
      y: selected.y,
      damage: damage,
      targetId: selected.id,
    );
  }

  /// Create multiple strikes (for Thiên Kiếp mutation)
  List<LightningStrike> createMultiStrike({
    required List<LightningTarget> targets,
    int count = 3,
  }) {
    if (targets.isEmpty) return [];

    final strikes = <LightningStrike>[];
    final sortedByDistance = List<LightningTarget>.from(targets);

    // Sort by proximity to first target (cluster effect)
    if (sortedByDistance.length > 1) {
      final first = sortedByDistance.first;
      sortedByDistance.sort((a, b) {
        final distA = _distance(a.x, a.y, first.x, first.y);
        final distB = _distance(b.x, b.y, first.x, first.y);
        return distA.compareTo(distB);
      });
    }

    for (int i = 0; i < min(count, sortedByDistance.length); i++) {
      final target = sortedByDistance[i];
      strikes.add(createStrike(
        x: target.x,
        y: target.y,
        damage: baseDamage * 0.5, // Reduced damage for multi-strike
        targetId: target.id,
      ));
    }

    return strikes;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
  }

  // === COLLISION CHECKING ===

  /// Check if a position is inside any active strike zone
  bool isInStrikeZone(double x, double y) {
    for (final strike in _activeStrikes) {
      if (strike.isStriking) {
        final dist = _distance(x, y, strike.x, strike.y);
        if (dist <= strike.radius) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get all strikes that hit a position (for damage calculation)
  List<LightningStrike> getStrikesAt(double x, double y) {
    return _activeStrikes.where((strike) {
      if (!strike.isStriking) return false;
      final dist = _distance(x, y, strike.x, strike.y);
      return dist <= strike.radius;
    }).toList();
  }

  /// Check collision and report hit
  void checkCollisions(List<LightningTarget> entities) {
    for (final strike in _activeStrikes) {
      if (!strike.isStriking) continue;

      for (final entity in entities) {
        final dist = _distance(entity.x, entity.y, strike.x, strike.y);
        if (dist <= strike.radius) {
          onHit?.call(strike, entity.id);
        }
      }
    }
  }

  // === RESET ===

  void reset() {
    _activeStrikes.clear();
    _timeSinceLastStrike = 0;
    _strikeCounter = 0;
  }

  // === UI HELPERS ===

  /// Get warning circle color (pulses)
  Color getWarningColor(LightningStrike strike) {
    if (!strike.isWarning) return Colors.transparent;

    // Pulse effect based on timer
    final progress = strike.stateTimer / warningDuration;
    final pulse = 0.5 + 0.5 * sin(progress * pi * 6); // 3 pulses

    return Color.lerp(
      Colors.red.withOpacity(0.3),
      Colors.red.withOpacity(0.8),
      pulse,
    )!;
  }

  /// Get strike effect color
  Color getStrikeColor(LightningStrike strike) {
    if (!strike.isStriking) return Colors.transparent;

    // Bright flash that fades
    final progress = strike.stateTimer / strikeDuration;
    return Colors.yellow.withOpacity(1.0 - progress);
  }

  /// Get aftermath color
  Color getAftermathColor(LightningStrike strike) {
    if (strike.state != LightningState.aftermath) return Colors.transparent;

    final progress = strike.stateTimer / aftermathDuration;
    return Colors.white.withOpacity(0.5 * (1.0 - progress));
  }

  /// Get warning progress (0.0 to 1.0)
  double getWarningProgress(LightningStrike strike) {
    if (!strike.isWarning) return 1.0;
    return (strike.stateTimer / warningDuration).clamp(0.0, 1.0);
  }
}
