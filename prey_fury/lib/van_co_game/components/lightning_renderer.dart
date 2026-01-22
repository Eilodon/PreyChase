/// Lightning Renderer - Visual for Thiên Kiếp hazard
///
/// Renders:
/// - Warning circles (red pulsing)
/// - Lightning bolt effect
/// - Impact flash
/// - Aftermath smoke

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../kernel/systems/lightning_system.dart';

/// Lightning Renderer Component
class LightningRenderer extends PositionComponent {
  final LightningSystem lightningSystem;
  final Random _random = Random();

  // === VISUAL STATE ===
  final List<LightningBoltVisual> _bolts = [];
  double _animTime = 0;

  LightningRenderer({required this.lightningSystem}) : super(priority: 100); // Render on top

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    // Update bolt visuals
    _bolts.removeWhere((bolt) => bolt.isComplete);
    for (final bolt in _bolts) {
      bolt.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    // Render all active strikes
    for (final strike in lightningSystem.activeStrikes) {
      _renderStrike(canvas, strike);
    }

    // Render bolt visuals
    for (final bolt in _bolts) {
      bolt.render(canvas);
    }
  }

  void _renderStrike(Canvas canvas, LightningStrike strike) {
    final center = Offset(strike.x, strike.y);

    switch (strike.state) {
      case LightningState.warning:
        _renderWarning(canvas, center, strike);
        break;
      case LightningState.striking:
        _renderLightning(canvas, center, strike);
        break;
      case LightningState.aftermath:
        _renderAftermath(canvas, center, strike);
        break;
      case LightningState.idle:
        break;
    }
  }

  void _renderWarning(Canvas canvas, Offset center, LightningStrike strike) {
    final progress = lightningSystem.getWarningProgress(strike);
    final radius = strike.radius;

    // Pulsing red circle
    final pulse = (sin(_animTime * 10) + 1) / 2;
    final opacity = 0.3 + pulse * 0.4;

    // Outer warning ring
    final ringPaint = Paint()
      ..color = Colors.red.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, ringPaint);

    // Inner fill (grows as warning progresses)
    final fillRadius = radius * progress;
    final fillPaint = Paint()
      ..color = Colors.red.withOpacity(0.2 + progress * 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, fillRadius, fillPaint);

    // Crosshair
    final crossPaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..strokeWidth = 2;

    canvas.drawLine(
      center + Offset(-radius * 0.3, 0),
      center + Offset(radius * 0.3, 0),
      crossPaint,
    );
    canvas.drawLine(
      center + Offset(0, -radius * 0.3),
      center + Offset(0, radius * 0.3),
      crossPaint,
    );

    // Warning text
    _drawWarningText(canvas, center, progress);
  }

  void _drawWarningText(Canvas canvas, Offset center, double progress) {
    final remaining = ((1.0 - progress) * LightningSystem.warningDuration * 10).ceil() / 10;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '⚡ ${remaining.toStringAsFixed(1)}s',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, -40),
    );
  }

  void _renderLightning(Canvas canvas, Offset center, LightningStrike strike) {
    // Create bolt visual if not exists
    if (!_bolts.any((b) => b.id == strike.id)) {
      _bolts.add(LightningBoltVisual(
        id: strike.id,
        position: center,
        radius: strike.radius,
        random: _random,
      ));
    }

    // Bright flash
    final flashProgress = strike.stateTimer / LightningSystem.strikeDuration;
    final flashOpacity = 1.0 - flashProgress;

    // Screen flash effect (white overlay)
    final flashPaint = Paint()
      ..color = Colors.white.withOpacity(flashOpacity * 0.3);

    canvas.drawRect(
      Rect.fromLTWH(-2000, -2000, 4000, 4000),
      flashPaint,
    );

    // Impact circle
    final impactPaint = Paint()
      ..color = Colors.yellow.withOpacity(flashOpacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, strike.radius * (1.0 + flashProgress * 0.5), impactPaint);

    // Inner bright core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(flashOpacity * 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, strike.radius * 0.3, corePaint);
  }

  void _renderAftermath(Canvas canvas, Offset center, LightningStrike strike) {
    final progress = strike.stateTimer / LightningSystem.aftermathDuration;
    final opacity = 1.0 - progress;

    // Smoke particles
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * pi + progress * 2;
      final distance = strike.radius * 0.3 * (1 + progress);
      final offset = Offset(cos(angle) * distance, sin(angle) * distance);

      final smokePaint = Paint()
        ..color = Colors.grey.withOpacity(opacity * 0.5);

      canvas.drawCircle(center + offset, 10 + progress * 20, smokePaint);
    }

    // Scorch mark
    final scorchPaint = Paint()
      ..color = Colors.black.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, strike.radius * 0.8, scorchPaint);
  }
}

/// Visual representation of a lightning bolt
class LightningBoltVisual {
  final String id;
  final Offset position;
  final double radius;
  final Random random;

  late List<List<Offset>> boltPaths;
  double lifetime = 0;
  static const double maxLifetime = 0.3;

  LightningBoltVisual({
    required this.id,
    required this.position,
    required this.radius,
    required this.random,
  }) {
    _generateBoltPaths();
  }

  void _generateBoltPaths() {
    boltPaths = [];

    // Generate 3-5 bolt branches
    final branchCount = 3 + random.nextInt(3);

    for (int i = 0; i < branchCount; i++) {
      boltPaths.add(_generateBoltPath());
    }
  }

  List<Offset> _generateBoltPath() {
    final path = <Offset>[];

    // Start from above
    var current = position + Offset(
      (random.nextDouble() - 0.5) * radius * 0.5,
      -radius * 2 - random.nextDouble() * radius,
    );
    path.add(current);

    // Generate jagged path down to impact point
    final segments = 8 + random.nextInt(5);
    final targetOffset = position - current;

    for (int i = 1; i <= segments; i++) {
      final progress = i / segments;

      // Base position along path
      var next = current + targetOffset * (1 / segments);

      // Add jitter (less near end)
      final jitter = (1.0 - progress) * radius * 0.3;
      next = next + Offset(
        (random.nextDouble() - 0.5) * jitter,
        (random.nextDouble() - 0.5) * jitter * 0.3,
      );

      path.add(next);
      current = next;
    }

    // End at impact point
    path.add(position);

    return path;
  }

  void update(double dt) {
    lifetime += dt;
  }

  bool get isComplete => lifetime >= maxLifetime;

  void render(Canvas canvas) {
    if (isComplete) return;

    final opacity = 1.0 - (lifetime / maxLifetime);

    // Draw each bolt branch
    for (final path in boltPaths) {
      _drawBolt(canvas, path, opacity);
    }
  }

  void _drawBolt(Canvas canvas, List<Offset> path, double opacity) {
    if (path.length < 2) return;

    // Glow effect
    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(opacity * 0.3)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    _drawPath(canvas, path, glowPaint);

    // Main bolt
    final boltPaint = Paint()
      ..color = Colors.yellow.withOpacity(opacity)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _drawPath(canvas, path, boltPaint);

    // Bright core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _drawPath(canvas, path, corePaint);
  }

  void _drawPath(Canvas canvas, List<Offset> path, Paint paint) {
    for (int i = 0; i < path.length - 1; i++) {
      canvas.drawLine(path[i], path[i + 1], paint);
    }
  }
}
