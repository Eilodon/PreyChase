import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'fury_world.dart';
import 'prey_component.dart';

/// Performance monitoring overlay for debug mode
/// Shows FPS, frame time, entity counts, spatial grid stats
///
/// Toggle with `PerformanceOverlay.enabled = true/false`
class PerformanceOverlay extends PositionComponent with HasGameRef {
  static bool enabled = false; // Set to true to show overlay

  // Performance tracking
  final List<double> _frameTimes = [];
  static const int _maxFrames = 60; // Track last 60 frames
  double _timeSinceLastUpdate = 0.0;

  // Cached text painters
  final Map<String, TextPainter> _textCache = {};

  // Display stats
  int _fps = 0;
  double _avgFrameTime = 0.0;
  double _maxFrameTime = 0.0;
  int _preyCount = 0;
  String _spatialGridStats = '';

  PerformanceOverlay() : super(position: Vector2(10, 10), priority: 1000);

  @override
  void update(double dt) {
    super.update(dt);

    if (!enabled) return;

    // Track frame times
    _frameTimes.add(dt * 1000); // Convert to ms
    if (_frameTimes.length > _maxFrames) {
      _frameTimes.removeAt(0);
    }

    // Update display every 0.5 seconds
    _timeSinceLastUpdate += dt;
    if (_timeSinceLastUpdate >= 0.5) {
      _timeSinceLastUpdate = 0.0;
      _updateStats();
    }
  }

  void _updateStats() {
    if (_frameTimes.isEmpty) return;

    // Calculate FPS
    final avgDt = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    _fps = avgDt > 0 ? (1000 / avgDt).round() : 0;
    _avgFrameTime = avgDt;
    _maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);

    // Get entity counts from game
    try {
      final world = gameRef.children.whereType<FuryWorld>().firstOrNull;
      if (world != null) {
        _preyCount = world.children.whereType<PreyComponent>().length;
        _spatialGridStats = world.preyGrid.getStats().toString();
      }
    } catch (e) {
      // Ignore if game not ready
    }

    // Clear text cache to update values
    _textCache.clear();
  }

  @override
  void render(Canvas canvas) {
    if (!enabled) return;

    // Background panel
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 350, 150),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = Colors.black.withOpacity(0.7),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Performance metrics
    double y = 10;

    // FPS (color coded)
    final fpsColor = _fps >= 55
        ? Colors.green
        : _fps >= 30
            ? Colors.yellow
            : Colors.red;
    _drawText(canvas, 'FPS: $_fps', Offset(10, y), 16, fpsColor, FontWeight.bold);
    y += 22;

    // Frame time (color coded)
    final frameColor = _avgFrameTime <= 16.7
        ? Colors.green
        : _avgFrameTime <= 33.3
            ? Colors.yellow
            : Colors.red;
    _drawText(
      canvas,
      'Frame: ${_avgFrameTime.toStringAsFixed(1)}ms '
      '(max: ${_maxFrameTime.toStringAsFixed(1)}ms)',
      Offset(10, y),
      12,
      frameColor,
    );
    y += 18;

    // Target line
    _drawText(
      canvas,
      'Target: 16.7ms (60 FPS)',
      Offset(10, y),
      10,
      Colors.grey,
    );
    y += 18;

    // Entity counts
    _drawText(
      canvas,
      'Prey: $_preyCount',
      Offset(10, y),
      12,
      Colors.white70,
    );
    y += 18;

    // Spatial grid stats (multi-line)
    _drawText(
      canvas,
      'Spatial Grid:',
      Offset(10, y),
      12,
      Colors.cyanAccent,
      FontWeight.bold,
    );
    y += 16;

    // Parse and display spatial grid stats
    if (_spatialGridStats.isNotEmpty) {
      final lines = _spatialGridStats.split(',');
      for (final line in lines) {
        _drawText(
          canvas,
          '  ${line.trim()}',
          Offset(10, y),
          9,
          Colors.white60,
        );
        y += 14;
      }
    }
  }

  TextPainter _getCachedTextPainter(
    String text,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final key = '$text-$fontSize-${color.value}-${weight.index}';
    if (!_textCache.containsKey(key)) {
      _textCache[key] = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            fontFamily: 'monospace',
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _textCache[key]!;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    double fontSize,
    Color color, [
    FontWeight weight = FontWeight.normal,
  ]) {
    final textPainter = _getCachedTextPainter(text, fontSize, color, weight);
    textPainter.paint(canvas, position);
  }

  /// Quick toggle method for debugging
  static void toggle() {
    enabled = !enabled;
    print('PerformanceOverlay: ${enabled ? "ENABLED" : "DISABLED"}');
  }
}
