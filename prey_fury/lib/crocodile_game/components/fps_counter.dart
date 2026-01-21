import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// On-screen FPS counter for performance monitoring
/// Simplified to avoid Skia crashes
class FpsCounter extends PositionComponent {
  double _fps = 0.0;
  final List<double> _frameTimes = [];
  double _updateTimer = 0.0;
  
  final Paint _bgPaint = Paint()..color = Colors.black.withOpacity(0.7);
  final Paint _textPaint = Paint()..color = Colors.green;
  
  FpsCounter() : super(
    position: Vector2(10, 10),
    size: Vector2(100, 40),
    anchor: Anchor.topLeft,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Collect frame times
    _frameTimes.add(dt);
    if (_frameTimes.length > 30) {
      _frameTimes.removeAt(0);
    }
    
    // Update FPS display every 0.5 seconds
    _updateTimer += dt;
    if (_updateTimer >= 0.5) {
      _updateTimer = 0.0;
      
      if (_frameTimes.isNotEmpty) {
        final avgDt = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
        _fps = avgDt > 0 ? 1.0 / avgDt : 0.0;
        
        // Update color
        if (_fps >= 50) {
          _textPaint.color = Colors.green;
        } else if (_fps >= 30) {
          _textPaint.color = Colors.yellow;
        } else {
          _textPaint.color = Colors.red;
        }
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Background
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      _bgPaint,
    );
    
    // FPS text using simple paragraph builder
    final builder = ParagraphBuilder(ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: 16,
    ))
      ..pushStyle(TextStyle(
        color: _textPaint.color,
        fontWeight: FontWeight.bold,
      ).getTextStyle())
      ..addText('FPS: ${_fps.toStringAsFixed(0)}');
    
    final paragraph = builder.build()
      ..layout(ParagraphConstraints(width: size.x));
    
    canvas.drawParagraph(paragraph, const Offset(8, 10));
  }
}
