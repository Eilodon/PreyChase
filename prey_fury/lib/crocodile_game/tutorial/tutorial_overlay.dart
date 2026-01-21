import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tutorial_manager.dart';

/// Tutorial overlay UI component
/// Shows instructions, hints, and visual highlights
class TutorialOverlay extends PositionComponent {
  final TutorialManager tutorialManager;

  final Paint _dimPaint = Paint()..color = Colors.black.withOpacity(0.5);
  final Paint _panelPaint = Paint()..color = const Color(0xFF1a1a2e);
  final Paint _highlightPaint = Paint()
    ..color = Colors.yellow.withOpacity(0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  final Map<String, TextPainter> _textCache = {};
  double _animationTime = 0.0;

  TutorialOverlay({required this.tutorialManager})
      : super(position: Vector2.zero(), size: Vector2(800, 600), priority: 998);

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!tutorialManager.isActive) return;

    final step = tutorialManager.currentStep;
    if (step == TutorialStep.none) return;

    // Welcome screen (full overlay)
    if (step == TutorialStep.welcome) {
      _drawWelcomeScreen(canvas);
      return;
    }

    // Completion screen
    if (step == TutorialStep.complete) {
      _drawCompletionScreen(canvas);
      return;
    }

    // Regular tutorial step (dim background + instruction panel)
    _drawDimBackground(canvas);
    _drawInstructionPanel(canvas);
    _drawHighlight(canvas);
    _drawSkipButton(canvas);
  }

  void _drawWelcomeScreen(Canvas canvas) {
    // Full dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF0a0a1a),
    );

    // Title
    _drawText(
      canvas,
      '🐊 PREY FURY 🐊',
      Offset(size.x / 2 - 150, 150),
      48,
      Colors.cyan,
      FontWeight.bold,
    );

    // Instructions (wrapped)
    final instructions = tutorialManager.getInstructionText();
    _drawWrappedText(
      canvas,
      instructions,
      Rect.fromLTWH(200, 250, 400, 150),
      20,
      Colors.white,
    );

    // Continue hint (pulsing)
    final pulseOpacity = 0.5 + (0.5 * (1 + (1.5 * _animationTime).floor() % 2));
    _drawText(
      canvas,
      'Press any key to continue...',
      Offset(size.x / 2 - 110, 450),
      14,
      Colors.white.withOpacity(pulseOpacity),
    );

    // Skip button
    _drawSkipButton(canvas);
  }

  void _drawCompletionScreen(Canvas canvas) {
    // Semi-transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black.withOpacity(0.7),
    );

    // Completion message
    _drawText(
      canvas,
      '✅ Tutorial Complete! ✅',
      Offset(size.x / 2 - 160, 200),
      36,
      Colors.green,
      FontWeight.bold,
    );

    _drawWrappedText(
      canvas,
      'You\'re ready to hunt!\nGood luck, crocodile! 🐊🔥',
      Rect.fromLTWH(250, 280, 300, 100),
      18,
      Colors.white,
    );

    // Auto-dismiss in 3 seconds
    final remaining = 3 - tutorialManager.stepTimer.toInt();
    if (remaining > 0) {
      _drawText(
        canvas,
        'Starting in $remaining...',
        Offset(size.x / 2 - 70, 400),
        14,
        Colors.white70,
      );
    }
  }

  void _drawDimBackground(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _dimPaint,
    );
  }

  void _drawInstructionPanel(Canvas canvas) {
    // Panel background (bottom center)
    final panelWidth = 600.0;
    final panelHeight = 120.0;
    final panelX = (size.x - panelWidth) / 2;
    final panelY = size.y - panelHeight - 40;

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(panelX, panelY, panelWidth, panelHeight),
      const Radius.circular(12),
    );

    // Background
    canvas.drawRRect(panelRect, _panelPaint);

    // Border
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Step indicator
    final stepNumber = tutorialManager.currentStep.index;
    _drawText(
      canvas,
      'Step $stepNumber/7',
      Offset(panelX + 20, panelY + 15),
      12,
      Colors.cyan,
    );

    // Main instruction
    final instruction = tutorialManager.getInstructionText();
    _drawWrappedText(
      canvas,
      instruction,
      Rect.fromLTWH(panelX + 20, panelY + 40, panelWidth - 40, 50),
      16,
      Colors.white,
    );

    // Hint (bottom)
    final hint = tutorialManager.getHintText();
    _drawText(
      canvas,
      hint,
      Offset(panelX + panelWidth / 2 - hint.length * 3, panelY + panelHeight - 25),
      12,
      Colors.yellow,
      FontWeight.bold,
    );
  }

  void _drawHighlight(Canvas canvas) {
    final highlight = tutorialManager.getHighlight();
    if (highlight == null) return;

    // Pulsing animation
    final pulse = 0.8 + (0.2 * ((_animationTime * 2).floor() % 2));

    switch (highlight) {
      case TutorialHighlight.player:
        // Circle around player (center)
        _drawPulsingCircle(canvas, Offset(size.x / 2, size.y / 2), 50, pulse);
        break;

      case TutorialHighlight.prey:
        // Not implemented (would need prey positions)
        break;

      case TutorialHighlight.furyBar:
        // Rectangle around fury bar (top right)
        final rect = Rect.fromLTWH(590, 32, 190, 16);
        canvas.drawRect(
          rect.inflate(5),
          _highlightPaint..color = Colors.cyan.withOpacity(0.5 * pulse),
        );
        break;

      case TutorialHighlight.powerUpCards:
        // Not needed (power-up overlay is obvious)
        break;
    }
  }

  void _drawPulsingCircle(Canvas canvas, Offset center, double radius, double pulse) {
    canvas.drawCircle(
      center,
      radius * pulse,
      _highlightPaint..color = Colors.yellow.withOpacity(0.4 * pulse),
    );

    // Arrow pointing down
    _drawArrow(canvas, center + Offset(0, radius * pulse + 20));
  }

  void _drawArrow(Canvas canvas, Offset tip) {
    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(tip.dx - 10, tip.dy - 15);
    path.lineTo(tip.dx + 10, tip.dy - 15);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.yellow,
    );
  }

  void _drawSkipButton(Canvas canvas) {
    final buttonX = size.x - 120.0;
    final buttonY = 20.0;

    // Button background
    final buttonRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(buttonX, buttonY, 100, 30),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      buttonRect,
      Paint()..color = Colors.grey.shade800,
    );

    canvas.drawRRect(
      buttonRect,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Button text
    _drawText(
      canvas,
      'Skip (ESC)',
      Offset(buttonX + 15, buttonY + 8),
      12,
      Colors.white70,
    );
  }

  void _drawWrappedText(
    Canvas canvas,
    String text,
    Rect bounds,
    double fontSize,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 5,
    );

    textPainter.layout(maxWidth: bounds.width);
    textPainter.paint(canvas, bounds.topLeft);
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
}
