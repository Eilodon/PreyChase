import 'package:flame/components.dart';

/// Manages "game juice" - visual/temporal effects that make the game feel amazing
/// Inspired by: Celeste (freeze frames), Devil May Cry (hit stop), Vampire Survivors
class JuiceManager extends Component {
  // === FREEZE FRAME (Celeste-style) ===
  double _freezeTimer = 0.0;
  bool get isFrozen => _freezeTimer > 0;

  // === HIT STOP (Fighting game-style) ===
  double _hitStopTimer = 0.0;
  double _hitStopIntensity = 0.0;

  // === TIME SCALE ===
  double get timeScale {
    if (_freezeTimer > 0) return 0.0; // Complete stop
    if (_hitStopTimer > 0) return 0.1; // Slow motion
    return 1.0; // Normal speed
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update timers (use real dt, not scaled)
    if (_freezeTimer > 0) {
      _freezeTimer -= dt;
    }

    if (_hitStopTimer > 0) {
      _hitStopTimer -= dt;
    }
  }

  /// Triggers a freeze frame effect (complete time stop)
  /// Used for: Big hits, combo milestones, boss defeats
  ///
  /// Duration examples:
  /// - 0.05s: Quick impact (eating prey)
  /// - 0.1s: Strong impact (fury activation)
  /// - 0.2s: Massive impact (boss kill)
  void freezeFrame(double duration) {
    _freezeTimer = duration;
  }

  /// Triggers hit stop effect (slow motion)
  /// Used for: Combat impacts, damage taken
  ///
  /// Duration: 0.1-0.3 seconds
  /// Intensity: 0.0-1.0 (affects visual shake)
  void hitStop(double duration, double intensity) {
    _hitStopTimer = duration;
    _hitStopIntensity = intensity;
  }

  /// Quick freeze for eating prey (50ms)
  void freezePreyEat() {
    freezeFrame(0.05);
  }

  /// Medium freeze for fury activation (100ms)
  void freezeFuryActivation() {
    freezeFrame(0.1);
  }

  /// Large freeze for boss kill (200ms)
  void freezeBossKill() {
    freezeFrame(0.2);
  }

  /// Small hit stop for taking damage
  void hitStopDamage() {
    hitStop(0.15, 0.5);
  }

  /// Large hit stop for critical events
  void hitStopCritical() {
    hitStop(0.25, 1.0);
  }

  /// Resets all juice effects (for level restart)
  void reset() {
    _freezeTimer = 0.0;
    _hitStopTimer = 0.0;
    _hitStopIntensity = 0.0;
  }
}
