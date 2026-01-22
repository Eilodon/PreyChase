/// Player Controller - Input handling for Vạn Cổ Chi Vương
///
/// Handles:
/// - Mouse-follow movement (like Agar.io)
/// - Split mechanic (Space)
/// - Eject mass mechanic (W)
/// - Touch controls for mobile

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../kernel/systems/size_manager.dart';
import 'critter_component.dart';

/// Player fragment (for split mechanic)
class PlayerFragment {
  final String id;
  CritterComponent component;
  double mergeTimer;
  bool isMain;

  PlayerFragment({
    required this.id,
    required this.component,
    this.mergeTimer = 0,
    this.isMain = false,
  });
}

/// Split state
enum SplitState {
  single,   // Not split
  split,    // Currently split
  merging,  // Merging back
}

/// Player Controller Component
class PlayerController extends Component {
  // === CONFIGURATION ===
  static const double splitDashDistance = 200.0;
  static const double splitDashSpeed = 800.0;
  static const double mergeCooldown = 10.0;
  static const double ejectMassPercent = 0.10; // 10% of size
  static const double ejectSpeed = 600.0;
  static const double minSizeToSplit = SizeManager.minSize * 2;
  static const double minSizeToEject = SizeManager.minSize * 1.5;

  // === STATE ===
  final List<PlayerFragment> fragments = [];
  SplitState splitState = SplitState.single;

  // === INPUT ===
  Vector2 mousePosition = Vector2.zero();
  Vector2 touchPosition = Vector2.zero();
  bool isTouching = false;
  bool useTouch = false;

  // === MUTATIONS ===
  bool canSplitIntoThree = false; // Phân Thân mutation
  double dashRangeBonus = 0.0; // Dash Boost mutation

  // === CALLBACKS ===
  void Function(Vector2 position, double size, Vector2 direction)? onEjectMass;
  void Function()? onSplit;
  void Function()? onMerge;

  PlayerController();

  /// Initialize with main player critter
  void initialize(CritterComponent mainCritter) {
    fragments.clear();
    fragments.add(PlayerFragment(
      id: 'main',
      component: mainCritter,
      isMain: true,
    ));
    splitState = SplitState.single;
  }

  /// Get main (or largest) fragment
  CritterComponent get mainFragment {
    if (fragments.isEmpty) {
      throw StateError('No fragments available');
    }

    // Return the main fragment or largest one
    final main = fragments.where((f) => f.isMain).firstOrNull;
    if (main != null) return main.component;

    fragments.sort((a, b) => b.component.critter.size.compareTo(a.component.critter.size));
    return fragments.first.component;
  }

  /// Get all fragment components
  List<CritterComponent> get allFragments => fragments.map((f) => f.component).toList();

  /// Get total size of all fragments
  double get totalSize => fragments.fold(0.0, (sum, f) => sum + f.component.critter.size);

  /// Get center position of all fragments
  Vector2 get centerPosition {
    if (fragments.isEmpty) return Vector2.zero();

    final center = Vector2.zero();
    for (final f in fragments) {
      center.add(f.component.position);
    }
    return center..scale(1.0 / fragments.length);
  }

  /// Current target position (mouse or touch)
  Vector2 get targetPosition => useTouch ? touchPosition : mousePosition;

  // === UPDATE ===

  @override
  void update(double dt) {
    super.update(dt);

    // Update all fragments
    for (final fragment in fragments) {
      _updateFragmentMovement(fragment, dt);
    }

    // Update merge timers
    if (splitState == SplitState.split) {
      _updateMergeTimers(dt);
    }
  }

  void _updateFragmentMovement(PlayerFragment fragment, double dt) {
    final critter = fragment.component;
    final target = targetPosition;

    // Calculate direction to target
    final direction = target - critter.position;
    final distance = direction.length;

    if (distance > 10) {
      direction.normalize();

      // Speed based on critter stats
      final speed = critter.critter.effectiveSpeed;

      // Apply velocity
      critter.velocity = direction * speed;
      critter.position += critter.velocity * dt;
    } else {
      // Stop when close to target
      critter.velocity.scale(0.9);
      if (critter.velocity.length < 5) {
        critter.velocity.setZero();
      }
    }
  }

  void _updateMergeTimers(double dt) {
    bool canMerge = true;

    for (final fragment in fragments) {
      if (!fragment.isMain) {
        fragment.mergeTimer += dt;
        if (fragment.mergeTimer < mergeCooldown) {
          canMerge = false;
        }
      }
    }

    // Check for merge
    if (canMerge && fragments.length > 1) {
      _checkMerge();
    }
  }

  void _checkMerge() {
    // Find fragments close enough to merge
    final toMerge = <PlayerFragment>[];

    for (final fragment in fragments) {
      if (fragment.isMain) continue;

      final distance = fragment.component.position.distanceTo(mainFragment.position);
      final mergeDistance = (fragment.component.size.x + mainFragment.size.x) / 2;

      if (distance < mergeDistance && fragment.mergeTimer >= mergeCooldown) {
        toMerge.add(fragment);
      }
    }

    // Merge fragments
    for (final fragment in toMerge) {
      _mergeFragment(fragment);
    }

    // Update state
    if (fragments.length == 1) {
      splitState = SplitState.single;
      onMerge?.call();
    }
  }

  void _mergeFragment(PlayerFragment fragment) {
    // Add size to main fragment
    final newSize = mainFragment.critter.size + fragment.component.critter.size;

    mainFragment.updateCritter(
      mainFragment.critter.copyWith(size: newSize),
    );

    // Remove merged fragment
    fragment.component.removeFromParent();
    fragments.remove(fragment);
  }

  // === SPLIT MECHANIC ===

  /// Attempt to split (Space key)
  bool trySplit() {
    if (!canSplit) return false;

    final direction = (targetPosition - mainFragment.position).normalized();
    _performSplit(direction);
    return true;
  }

  bool get canSplit {
    // Check minimum size
    if (totalSize < minSizeToSplit) return false;

    // Check max fragments
    final maxFragments = canSplitIntoThree ? 3 : 2;
    if (fragments.length >= maxFragments) return false;

    return true;
  }

  void _performSplit(Vector2 direction) {
    final splitCount = canSplitIntoThree ? 2 : 1; // Split into 2 or 3

    for (int i = 0; i < splitCount && canSplit; i++) {
      _createSplitFragment(direction, i);
    }

    splitState = SplitState.split;
    onSplit?.call();
  }

  void _createSplitFragment(Vector2 baseDirection, int index) {
    // Calculate split size (divide evenly)
    final currentSize = mainFragment.critter.size;
    final splitSize = currentSize / 2;

    // Update main fragment size
    mainFragment.updateCritter(
      mainFragment.critter.copyWith(size: splitSize),
    );

    // Calculate split direction (spread if multiple)
    final spreadAngle = index * 0.3; // ~17 degrees spread
    final direction = Vector2(
      baseDirection.x * cos(spreadAngle) - baseDirection.y * sin(spreadAngle),
      baseDirection.x * sin(spreadAngle) + baseDirection.y * cos(spreadAngle),
    );

    // Create new fragment
    final dashRange = splitDashDistance * (1.0 + dashRangeBonus);
    final newPosition = mainFragment.position + direction * dashRange;

    final newCritter = mainFragment.critter.copyWith(
      id: 'fragment_${fragments.length}',
      size: splitSize,
      x: newPosition.x,
      y: newPosition.y,
    );

    final newComponent = CritterComponent(
      critter: newCritter,
      position: newPosition,
    );

    // Copy callbacks from main
    newComponent.onDeath = mainFragment.onDeath;
    newComponent.onTierUp = mainFragment.onTierUp;

    fragments.add(PlayerFragment(
      id: newCritter.id,
      component: newComponent,
      mergeTimer: 0,
      isMain: false,
    ));

    // Add to parent (world)
    mainFragment.parent?.add(newComponent);

    // Animate dash
    _animateSplitDash(newComponent, mainFragment.position, newPosition);
  }

  void _animateSplitDash(CritterComponent component, Vector2 from, Vector2 to) {
    // The dash is instant in position, but we can add a trail effect
    // For now, just set the velocity for visual feedback
    final direction = (to - from).normalized();
    component.velocity = direction * splitDashSpeed;
  }

  // === EJECT MASS MECHANIC ===

  /// Attempt to eject mass (W key)
  bool tryEjectMass() {
    if (!canEjectMass) return false;

    final direction = (targetPosition - mainFragment.position).normalized();
    _performEjectMass(direction);
    return true;
  }

  bool get canEjectMass {
    return mainFragment.critter.size >= minSizeToEject;
  }

  void _performEjectMass(Vector2 direction) {
    final currentSize = mainFragment.critter.size;
    final ejectSize = currentSize * ejectMassPercent;

    // Reduce player size
    mainFragment.updateCritter(
      mainFragment.critter.copyWith(size: currentSize - ejectSize),
    );

    // Calculate eject position
    final ejectPos = mainFragment.position + direction * (mainFragment.size.x / 2 + 10);

    // Notify world to create mass pellet
    onEjectMass?.call(ejectPos, ejectSize, direction * ejectSpeed);

    // Apply recoil (Newton's 3rd law)
    mainFragment.velocity -= direction * ejectSpeed * 0.1;
  }

  // === INPUT HANDLERS ===

  void onMouseMove(Vector2 worldPosition) {
    mousePosition = worldPosition;
    useTouch = false;
  }

  void onTouchStart(Vector2 worldPosition) {
    touchPosition = worldPosition;
    isTouching = true;
    useTouch = true;
  }

  void onTouchMove(Vector2 worldPosition) {
    if (isTouching) {
      touchPosition = worldPosition;
    }
  }

  void onTouchEnd() {
    isTouching = false;
  }

  bool onKeyDown(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) {
      return trySplit();
    }

    if (key == LogicalKeyboardKey.keyW) {
      return tryEjectMass();
    }

    return false;
  }

  // === MUTATIONS ===

  void applyMutation(String mutationId) {
    switch (mutationId) {
      case 'phanThan': // Phân Thân - Split into 3
        canSplitIntoThree = true;
        break;
      case 'dashBoost': // Dash Boost - +50% range
        dashRangeBonus = 0.5;
        break;
    }
  }

  // === DAMAGE DISTRIBUTION ===

  /// Distribute damage across all fragments
  void distributeDamage(double damage) {
    // Damage is split evenly across fragments
    final damagePerFragment = damage / fragments.length;

    for (final fragment in fragments) {
      fragment.component.takeDamage(damagePerFragment);
    }
  }

  /// Check if any fragment is dead
  bool get anyFragmentDead => fragments.any((f) => f.component.critter.isDead);

  /// Check if all fragments are dead
  bool get allFragmentsDead => fragments.every((f) => f.component.critter.isDead);
}

/// Ejected Mass Component (can be eaten for growth)
class EjectedMassComponent extends PositionComponent {
  final double massSize;
  Vector2 velocity;
  double lifetime = 30.0; // Despawn after 30s

  EjectedMassComponent({
    required Vector2 position,
    required this.massSize,
    required this.velocity,
  }) : super(
         position: position,
         size: Vector2.all(8 + massSize * 0.02),
         anchor: Anchor.center,
       );

  @override
  void update(double dt) {
    super.update(dt);

    // Move with velocity (decelerating)
    position += velocity * dt;
    velocity.scale(0.95);

    // Lifetime
    lifetime -= dt;
    if (lifetime <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(canvas) {
    final paint = Paint()..color = const Color(0xFF8BC34A);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      paint,
    );
  }
}
