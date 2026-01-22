/// Critter Component - Flame rendering component for Vạn Cổ Chi Vương
///
/// Visual representation of a Critter entity with:
/// - Size-based scaling
/// - Faction-specific appearance
/// - Tier evolution visuals
/// - Status indicators (health, size comparison)

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../kernel/models/critter.dart';
import '../../kernel/models/ngu_hanh_faction.dart';
import '../../kernel/systems/size_manager.dart';

/// Visual emotion state for critters
enum CritterEmotion {
  neutral,   // Normal state
  hunting,   // Chasing prey (aggressive eyes)
  fleeing,   // Running from predator (scared eyes)
  combat,    // Fighting similar size (angry eyes)
  eating,    // Just ate something (happy)
  hurt,      // Just took damage (pain)
}

/// Critter Component - Flame PositionComponent
class CritterComponent extends PositionComponent {
  // === CRITTER DATA ===
  Critter _critter;
  Critter get critter => _critter;

  // === VISUAL STATE ===
  CritterEmotion emotion = CritterEmotion.neutral;
  double _animTime = 0;
  double _damageFlash = 0;
  double _eatPulse = 0;
  bool _isInvisible = false;

  // === MOVEMENT ===
  Vector2 velocity = Vector2.zero();
  Vector2 targetPosition = Vector2.zero();
  double _facingAngle = 0;

  // === CALLBACKS ===
  void Function(CritterComponent eaten)? onEatCritter;
  void Function(double damage)? onTakeDamage;
  void Function()? onDeath;
  void Function(SizeTier newTier)? onTierUp;

  // === CACHED PAINTS ===
  late Paint _bodyPaint;
  late Paint _accentPaint;
  late Paint _eyeWhitePaint;
  late Paint _eyePupilPaint;
  final Paint _damagePaint = Paint()..color = Colors.red.withOpacity(0.5);
  final Paint _shadowPaint = Paint()..color = Colors.black.withOpacity(0.2);

  // === BASE DIMENSIONS ===
  static const double baseWidth = 32.0;
  static const double baseHeight = 32.0;

  CritterComponent({
    required Critter critter,
    Vector2? position,
  }) : _critter = critter,
       super(
         position: position ?? Vector2(critter.x, critter.y),
         anchor: Anchor.center,
       ) {
    _initPaints();
    _updateSize();
  }

  void _initPaints() {
    final factionData = NguHanhRegistry.get(_critter.faction);
    _bodyPaint = Paint()..color = factionData.primaryColor;
    _accentPaint = Paint()..color = factionData.secondaryColor;
    _eyeWhitePaint = Paint()..color = Colors.white;
    _eyePupilPaint = Paint()..color = Colors.black;
  }

  void _updateSize() {
    final scale = SizeManager.getVisualScale(_critter.size);
    size = Vector2(baseWidth * scale, baseHeight * scale);
  }

  // === UPDATE CRITTER DATA ===

  void updateCritter(Critter newCritter) {
    final oldTier = _critter.tier;
    final oldSize = _critter.size;

    _critter = newCritter;
    _updateSize();

    // Check tier change
    if (newCritter.tier != oldTier) {
      onTierUp?.call(newCritter.tier);
      _playTierUpEffect();
    }

    // Check size increase (eating)
    if (newCritter.size > oldSize) {
      _eatPulse = 0.3;
    }
  }

  void _playTierUpEffect() {
    // Scale pulse effect
    add(ScaleEffect.by(
      Vector2.all(1.3),
      EffectController(duration: 0.2, reverseDuration: 0.2),
    ));
  }

  // === GAME ACTIONS ===

  /// Called when this critter eats another
  void eat(CritterComponent prey) {
    final newCritter = _critter.eat(prey.critter);
    updateCritter(newCritter);
    emotion = CritterEmotion.eating;
    onEatCritter?.call(prey);
  }

  /// Called when this critter takes damage
  void takeDamage(double damage) {
    final newCritter = _critter.takeDamage(damage);
    updateCritter(newCritter);
    _damageFlash = 0.3;
    emotion = CritterEmotion.hurt;
    onTakeDamage?.call(damage);

    if (newCritter.isDead) {
      onDeath?.call();
    }
  }

  /// Called when this critter heals
  void heal(double amount) {
    final newCritter = _critter.heal(amount);
    updateCritter(newCritter);
  }

  /// Called when eating food pellet
  void eatFood() {
    final newCritter = _critter.eatFood();
    updateCritter(newCritter);
    _eatPulse = 0.15;
  }

  /// Set invisibility state (Tàng Hình mutation)
  void setInvisible(bool invisible) {
    _isInvisible = invisible;
  }

  // === SIZE COMPARISON ===

  /// Get size indicator when comparing to another critter
  SizeIndicator getIndicatorFor(CritterComponent other) {
    return SizeManager.getIndicator(_critter.size, other._critter.size);
  }

  /// Can this critter eat another?
  bool canEat(CritterComponent other) {
    return SizeManager.canEat(_critter.size, other._critter.size);
  }

  /// Will this critter be eaten by another?
  bool willBeEatenBy(CritterComponent other) {
    return SizeManager.willBeEatenBy(_critter.size, other._critter.size);
  }

  /// Are we in combat zone with another?
  bool inCombatWith(CritterComponent other) {
    return SizeManager.inCombatZone(_critter.size, other._critter.size);
  }

  // === UPDATE LOOP ===

  @override
  void update(double dt) {
    super.update(dt);

    _animTime += dt;

    // Update damage flash
    if (_damageFlash > 0) {
      _damageFlash = max(0, _damageFlash - dt);
    }

    // Update eat pulse
    if (_eatPulse > 0) {
      _eatPulse = max(0, _eatPulse - dt);
    }

    // Reset emotion after a while
    if (emotion != CritterEmotion.neutral && _animTime > 0.5) {
      emotion = CritterEmotion.neutral;
    }

    // Update facing angle based on velocity
    if (velocity.length > 1) {
      _facingAngle = atan2(velocity.y, velocity.x);
    }
  }

  // === RENDER ===

  @override
  void render(Canvas canvas) {
    // Skip if invisible
    if (_isInvisible) {
      _renderInvisibleHint(canvas);
      return;
    }

    final w = size.x;
    final h = size.y;

    // Breathing animation
    final breath = sin(_animTime * 3) * 0.03;

    // Eat pulse
    final pulse = _eatPulse > 0 ? sin(_eatPulse * pi * 10) * 0.1 : 0.0;

    canvas.save();

    // Apply rotation based on facing
    canvas.translate(w / 2, h / 2);
    canvas.rotate(_facingAngle);
    canvas.translate(-w / 2, -h / 2);

    // Apply breathing + pulse scale
    canvas.translate(w / 2, h / 2);
    canvas.scale(1.0 + breath + pulse, 1.0 - breath * 0.5 + pulse);
    canvas.translate(-w / 2, -h / 2);

    // Shadow
    canvas.drawOval(
      Rect.fromLTWH(2, h - 4, w - 4, 8),
      _shadowPaint,
    );

    // Draw based on faction creature type
    _drawCreature(canvas, w, h);

    canvas.restore();

    // Damage flash overlay
    if (_damageFlash > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        _damagePaint..color = Colors.red.withOpacity(_damageFlash),
      );
    }
  }

  void _renderInvisibleHint(Canvas canvas) {
    // Only show faint outline when invisible
    final w = size.x;
    final h = size.y;
    final paint = Paint()
      ..color = _bodyPaint.color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawOval(Rect.fromLTWH(0, 0, w, h), paint);
  }

  void _drawCreature(Canvas canvas, double w, double h) {
    switch (_critter.faction) {
      case NguHanhFaction.kim:
        _drawBee(canvas, w, h);
        break;
      case NguHanhFaction.moc:
        _drawSnake(canvas, w, h);
        break;
      case NguHanhFaction.hoa:
        _drawToad(canvas, w, h);
        break;
      case NguHanhFaction.thuy:
        _drawSilkworm(canvas, w, h);
        break;
      case NguHanhFaction.tho:
        _drawScorpion(canvas, w, h);
        break;
    }
  }

  // === CREATURE DRAWINGS ===

  /// 🐝 Kim - Ong Vàng (Golden Bee)
  void _drawBee(Canvas canvas, double w, double h) {
    // Body (oval with stripes)
    final bodyRect = Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.6);
    canvas.drawOval(bodyRect, _bodyPaint);

    // Stripes
    final stripePaint = Paint()..color = Colors.black;
    for (int i = 0; i < 3; i++) {
      final y = h * 0.3 + i * h * 0.15;
      canvas.drawRect(
        Rect.fromLTWH(w * 0.15, y, w * 0.7, h * 0.05),
        stripePaint,
      );
    }

    // Wings
    final wingPaint = Paint()..color = Colors.white.withOpacity(0.6);
    canvas.drawOval(Rect.fromLTWH(w * 0.2, h * 0.05, w * 0.25, h * 0.2), wingPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.55, h * 0.05, w * 0.25, h * 0.2), wingPaint);

    // Stinger
    final stingerPath = Path()
      ..moveTo(w * 0.9, h * 0.5)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.9, h * 0.45)
      ..close();
    canvas.drawPath(stingerPath, stripePaint);

    // Eyes
    _drawEyes(canvas, w * 0.3, h * 0.35, w * 0.12);
    _drawEyes(canvas, w * 0.58, h * 0.35, w * 0.12);
  }

  /// 🐍 Mộc - Rắn Lục (Green Snake)
  void _drawSnake(Canvas canvas, double w, double h) {
    // Body (elongated S shape)
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.1, h * 0.5);
    bodyPath.quadraticBezierTo(w * 0.3, h * 0.2, w * 0.5, h * 0.4);
    bodyPath.quadraticBezierTo(w * 0.7, h * 0.6, w * 0.9, h * 0.5);
    bodyPath.quadraticBezierTo(w * 0.7, h * 0.8, w * 0.5, h * 0.6);
    bodyPath.quadraticBezierTo(w * 0.3, h * 0.4, w * 0.1, h * 0.5);
    bodyPath.close();

    canvas.drawPath(bodyPath, _bodyPaint);

    // Scales pattern
    final scalePaint = Paint()..color = _accentPaint.color.withOpacity(0.5);
    for (double x = 0.2; x < 0.8; x += 0.15) {
      canvas.drawCircle(Offset(w * x, h * 0.5), w * 0.04, scalePaint);
    }

    // Head
    canvas.drawOval(
      Rect.fromLTWH(w * 0.0, h * 0.35, w * 0.25, h * 0.3),
      _bodyPaint,
    );

    // Eyes (red for snake)
    _eyePupilPaint.color = Colors.red.shade800;
    _drawEyes(canvas, w * 0.08, h * 0.42, w * 0.08);
    _eyePupilPaint.color = Colors.black;

    // Tongue
    final tonguePaint = Paint()..color = Colors.red;
    canvas.drawLine(
      Offset(0, h * 0.5),
      Offset(-w * 0.1, h * 0.45),
      tonguePaint..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(0, h * 0.5),
      Offset(-w * 0.1, h * 0.55),
      tonguePaint,
    );
  }

  /// 🐸 Hỏa - Cóc Đỏ (Red Toad)
  void _drawToad(Canvas canvas, double w, double h) {
    // Body (round, bumpy)
    canvas.drawOval(
      Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.8, h * 0.6),
      _bodyPaint,
    );

    // Belly (lighter)
    canvas.drawOval(
      Rect.fromLTWH(w * 0.2, h * 0.5, w * 0.6, h * 0.35),
      _accentPaint,
    );

    // Bumps/warts
    final bumpPaint = Paint()..color = _bodyPaint.color.darken(0.2);
    canvas.drawCircle(Offset(w * 0.25, h * 0.4), w * 0.05, bumpPaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.45), w * 0.04, bumpPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.03, bumpPaint);

    // Big eyes on top
    canvas.drawCircle(Offset(w * 0.3, h * 0.25), w * 0.12, _eyeWhitePaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.25), w * 0.12, _eyeWhitePaint);
    canvas.drawCircle(Offset(w * 0.3, h * 0.25), w * 0.06, _eyePupilPaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.25), w * 0.06, _eyePupilPaint);

    // Mouth (wide)
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.25, h * 0.6, w * 0.5, h * 0.2),
      0,
      pi,
      false,
      mouthPaint,
    );

    // Legs
    _drawToadLeg(canvas, w * 0.1, h * 0.7, -0.3);
    _drawToadLeg(canvas, w * 0.8, h * 0.7, 0.3);
  }

  void _drawToadLeg(Canvas canvas, double x, double y, double angle) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    canvas.drawOval(Rect.fromLTWH(-5, 0, 15, 10), _bodyPaint);
    canvas.restore();
  }

  /// 🐛 Thủy - Tằm Xanh (Blue Silkworm)
  void _drawSilkworm(Canvas canvas, double w, double h) {
    // Body segments
    final segmentCount = 5;
    for (int i = segmentCount - 1; i >= 0; i--) {
      final x = w * 0.15 + i * w * 0.14;
      final segmentH = h * (0.4 + (segmentCount - i) * 0.05);
      final y = h * 0.5 - segmentH / 2;

      canvas.drawOval(
        Rect.fromLTWH(x, y, w * 0.2, segmentH),
        i == 0 ? _bodyPaint : _accentPaint,
      );
    }

    // Head (first segment)
    canvas.drawOval(
      Rect.fromLTWH(w * 0.05, h * 0.3, w * 0.25, h * 0.4),
      _bodyPaint,
    );

    // Eyes
    _drawEyes(canvas, w * 0.12, h * 0.4, w * 0.08);
    _drawEyes(canvas, w * 0.22, h * 0.4, w * 0.08);

    // Antenna
    final antennaPaint = Paint()
      ..color = _bodyPaint.color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.1, h * 0.3), Offset(w * 0.05, h * 0.15), antennaPaint);
    canvas.drawLine(Offset(w * 0.2, h * 0.3), Offset(w * 0.25, h * 0.15), antennaPaint);

    // Silk trail hint
    if (velocity.length > 50) {
      final silkPaint = Paint()..color = Colors.white.withOpacity(0.3);
      canvas.drawLine(
        Offset(w * 0.9, h * 0.5),
        Offset(w * 1.2, h * 0.5),
        silkPaint..strokeWidth = 3,
      );
    }
  }

  /// 🦂 Thổ - Bò Cạp Nâu (Brown Scorpion)
  void _drawScorpion(Canvas canvas, double w, double h) {
    // Body
    canvas.drawOval(
      Rect.fromLTWH(w * 0.2, h * 0.4, w * 0.5, h * 0.4),
      _bodyPaint,
    );

    // Head
    canvas.drawOval(
      Rect.fromLTWH(w * 0.05, h * 0.4, w * 0.25, h * 0.3),
      _bodyPaint,
    );

    // Claws
    _drawScorpionClaw(canvas, w * 0.0, h * 0.35, true);
    _drawScorpionClaw(canvas, w * 0.0, h * 0.55, false);

    // Tail (curved up)
    final tailPath = Path();
    tailPath.moveTo(w * 0.7, h * 0.5);
    tailPath.quadraticBezierTo(w * 0.85, h * 0.6, w * 0.9, h * 0.4);
    tailPath.quadraticBezierTo(w * 0.95, h * 0.2, w * 0.85, h * 0.1);
    tailPath.lineTo(w * 0.9, h * 0.15);
    tailPath.quadraticBezierTo(w * 1.0, h * 0.25, w * 0.95, h * 0.45);
    tailPath.quadraticBezierTo(w * 0.9, h * 0.65, w * 0.7, h * 0.55);
    tailPath.close();

    canvas.drawPath(tailPath, _bodyPaint);

    // Stinger
    final stingerPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(w * 0.87, h * 0.08), w * 0.04, stingerPaint);

    // Eyes (small)
    _drawEyes(canvas, w * 0.12, h * 0.48, w * 0.06);
    _drawEyes(canvas, w * 0.22, h * 0.48, w * 0.06);

    // Legs (6 total)
    final legPaint = Paint()..color = _bodyPaint.color.darken(0.1);
    for (int i = 0; i < 3; i++) {
      final x = w * 0.3 + i * w * 0.15;
      canvas.drawLine(Offset(x, h * 0.4), Offset(x - 5, h * 0.25), legPaint..strokeWidth = 3);
      canvas.drawLine(Offset(x, h * 0.8), Offset(x - 5, h * 0.95), legPaint);
    }
  }

  void _drawScorpionClaw(Canvas canvas, double x, double y, bool top) {
    final clawPath = Path();
    clawPath.moveTo(x + 15, y);
    clawPath.lineTo(x, y + (top ? -8 : 8));
    clawPath.lineTo(x - 5, y + (top ? -5 : 5));
    clawPath.lineTo(x + 5, y);
    clawPath.lineTo(x - 5, y + (top ? 5 : -5));
    clawPath.lineTo(x, y + (top ? 8 : -8));
    clawPath.close();

    canvas.drawPath(clawPath, _bodyPaint);
  }

  // === HELPER METHODS ===

  void _drawEyes(Canvas canvas, double x, double y, double radius) {
    // White
    canvas.drawCircle(Offset(x, y), radius, _eyeWhitePaint);

    // Pupil (based on emotion)
    double pupilOffsetX = 0;
    double pupilOffsetY = 0;

    switch (emotion) {
      case CritterEmotion.hunting:
        pupilOffsetX = radius * 0.3;
        break;
      case CritterEmotion.fleeing:
        pupilOffsetX = -radius * 0.3;
        break;
      case CritterEmotion.combat:
        pupilOffsetY = -radius * 0.2;
        break;
      case CritterEmotion.eating:
        // Happy squint - smaller pupil
        canvas.drawCircle(Offset(x + pupilOffsetX, y + pupilOffsetY), radius * 0.3, _eyePupilPaint);
        return;
      case CritterEmotion.hurt:
        // X eyes
        final xPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x - radius * 0.5, y - radius * 0.5), Offset(x + radius * 0.5, y + radius * 0.5), xPaint);
        canvas.drawLine(Offset(x + radius * 0.5, y - radius * 0.5), Offset(x - radius * 0.5, y + radius * 0.5), xPaint);
        return;
      default:
        break;
    }

    canvas.drawCircle(Offset(x + pupilOffsetX, y + pupilOffsetY), radius * 0.5, _eyePupilPaint);
  }
}

/// Extension for color manipulation
extension ColorExt on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Color lighten(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}
