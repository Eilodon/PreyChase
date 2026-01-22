/// Zone Renderer - Visual for shrinking Battle Royale zone
///
/// Renders:
/// - Safe zone boundary (circle)
/// - Poison zone (fog outside safe zone)
/// - Zone shrinking animation
/// - Warning indicators

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../kernel/systems/battle_royale_manager.dart';

/// Zone Renderer Component
class ZoneRenderer extends PositionComponent {
  final BattleRoyaleManager brManager;

  // === VISUAL STATE ===
  double _currentRadius = BattleRoyaleManager.mapRadius;
  double _targetRadius = BattleRoyaleManager.mapRadius;
  double _animTime = 0;
  bool _isWarning = false;
  double _warningPulse = 0;

  // === PAINTS ===
  late Paint _safeBorderPaint;
  late Paint _dangerBorderPaint;
  late Paint _poisonFogPaint;
  late Paint _warningPaint;
  late Paint _gridPaint;

  // === CONFIGURATION ===
  static const double borderWidth = 4.0;
  static const double warningPulseSpeed = 3.0;
  static const double gridSpacing = 100.0;

  ZoneRenderer({required this.brManager}) : super(priority: -10); // Render behind everything

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initPaints();
  }

  void _initPaints() {
    _safeBorderPaint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    _dangerBorderPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    _poisonFogPaint = Paint()
      ..color = const Color(0x4000FF00) // Green fog
      ..style = PaintingStyle.fill;

    _warningPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    _gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animTime += dt;

    // Update radius from BR manager
    final state = brManager.state;
    _currentRadius = state.currentZoneRadius;
    _targetRadius = state.targetZoneRadius;

    // Update warning state
    _isWarning = _targetRadius < _currentRadius;

    if (_isWarning) {
      _warningPulse = (sin(_animTime * warningPulseSpeed) + 1) / 2;
    }

    // Update paint colors based on phase
    _updatePaintColors();
  }

  void _updatePaintColors() {
    final state = brManager.state;

    // Border color changes with phase
    switch (state.currentPhase) {
      case BRPhase.spawn:
      case BRPhase.earlyGame:
        _safeBorderPaint.color = Colors.green.withOpacity(0.6);
        _poisonFogPaint.color = const Color(0x2000FF00);
        break;
      case BRPhase.midGame:
        _safeBorderPaint.color = Colors.yellow.withOpacity(0.7);
        _poisonFogPaint.color = const Color(0x40FFFF00);
        break;
      case BRPhase.lateGame:
        _safeBorderPaint.color = Colors.orange.withOpacity(0.8);
        _poisonFogPaint.color = const Color(0x50FF8800);
        break;
      case BRPhase.suddenDeath:
        _safeBorderPaint.color = Colors.red.withOpacity(0.9);
        _poisonFogPaint.color = const Color(0x60FF4400);
        break;
      case BRPhase.overtime:
        _safeBorderPaint.color = Colors.purple.withOpacity(1.0);
        _poisonFogPaint.color = const Color(0x70FF0044);
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset.zero;

    // Draw grid (for spatial awareness)
    _drawGrid(canvas, center);

    // Draw poison fog (outside safe zone)
    _drawPoisonFog(canvas, center);

    // Draw safe zone border
    _drawSafeZoneBorder(canvas, center);

    // Draw target zone (where it's shrinking to)
    if (_isWarning && _targetRadius < _currentRadius) {
      _drawTargetZone(canvas, center);
    }

    // Draw warning pulse
    if (_isWarning) {
      _drawWarningPulse(canvas, center);
    }

    // Draw minimap markers for zone
    _drawZoneIndicators(canvas, center);
  }

  void _drawGrid(Canvas canvas, Offset center) {
    final maxRadius = BattleRoyaleManager.mapRadius;

    // Horizontal lines
    for (double y = -maxRadius; y <= maxRadius; y += gridSpacing) {
      canvas.drawLine(
        Offset(-maxRadius, y),
        Offset(maxRadius, y),
        _gridPaint,
      );
    }

    // Vertical lines
    for (double x = -maxRadius; x <= maxRadius; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, -maxRadius),
        Offset(x, maxRadius),
        _gridPaint,
      );
    }
  }

  void _drawPoisonFog(Canvas canvas, Offset center) {
    final maxRadius = BattleRoyaleManager.mapRadius;

    // Create path for fog (outer circle minus inner safe zone)
    final fogPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: maxRadius * 1.5))
      ..addOval(Rect.fromCircle(center: center, radius: _currentRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(fogPath, _poisonFogPaint);

    // Add gradient effect at edge
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: _currentRadius / maxRadius,
      colors: [
        Colors.transparent,
        _poisonFogPaint.color.withOpacity(0.5),
      ],
      stops: const [0.95, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: _currentRadius * 1.1);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _currentRadius * 0.1;

    canvas.drawCircle(center, _currentRadius, gradientPaint);
  }

  void _drawSafeZoneBorder(Canvas canvas, Offset center) {
    // Main border
    canvas.drawCircle(center, _currentRadius, _safeBorderPaint);

    // Animated dashes
    final dashPaint = Paint()
      ..color = _safeBorderPaint.color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dashLength = 20.0;
    final dashCount = (2 * pi * _currentRadius / (dashLength * 2)).floor();
    final angleStep = 2 * pi / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep + _animTime * 0.2;
      final endAngle = startAngle + angleStep * 0.5;

      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: _currentRadius - 5),
          startAngle,
          angleStep * 0.5,
        );

      canvas.drawPath(path, dashPaint);
    }
  }

  void _drawTargetZone(Canvas canvas, Offset center) {
    // Dashed circle showing where zone will shrink to
    final targetPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw dashed circle
    final dashLength = 15.0;
    final dashCount = (2 * pi * _targetRadius / (dashLength * 2)).floor();
    final angleStep = 2 * pi / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;

      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: _targetRadius),
          startAngle,
          angleStep * 0.5,
        );

      canvas.drawPath(path, targetPaint);
    }
  }

  void _drawWarningPulse(Canvas canvas, Offset center) {
    // Pulsing ring at current zone edge
    final pulseRadius = _currentRadius + _warningPulse * 30;
    final pulseOpacity = (1.0 - _warningPulse) * 0.5;

    final pulsePaint = Paint()
      ..color = Colors.red.withOpacity(pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  void _drawZoneIndicators(Canvas canvas, Offset center) {
    // Draw compass points
    final directions = [
      (offset: Offset(0, -_currentRadius + 20), label: 'N'),
      (offset: Offset(_currentRadius - 20, 0), label: 'E'),
      (offset: Offset(0, _currentRadius - 20), label: 'S'),
      (offset: Offset(-_currentRadius + 20, 0), label: 'W'),
    ];

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final dir in directions) {
      textPainter.text = TextSpan(
        text: dir.label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        dir.offset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  // === PUBLIC METHODS ===

  /// Trigger warning animation
  void showWarning() {
    _isWarning = true;
  }

  /// Get color for minimap based on current phase
  Color get minimapZoneColor => _safeBorderPaint.color;
}
