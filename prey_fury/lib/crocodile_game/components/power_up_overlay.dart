import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/power_up.dart';

/// Power-up selection overlay UI (Vampire Survivors-style)
/// Shows 3 power-up choices, pauses game until selection
class PowerUpOverlay extends PositionComponent with KeyboardHandler {
  final List<PowerUp> offers;
  final void Function(int index)? onSelected;

  int _hoveredIndex = -1;
  final Paint _bgPaint = Paint()..color = Colors.black.withOpacity(0.85);
  final Paint _cardBgPaint = Paint()..color = const Color(0xFF1a1a2e);

  // Cached text painters
  final Map<String, TextPainter> _textCache = {};

  PowerUpOverlay({
    required this.offers,
    this.onSelected,
  }) : super(
         position: Vector2.zero(),
         size: Vector2(800, 600),
         priority: 999, // Always on top
       );

  @override
  void render(Canvas canvas) {
    // Full screen dark overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _bgPaint,
    );

    // Title
    _drawText(
      canvas,
      '⚡ LEVEL UP! ⚡',
      Offset(size.x / 2 - 100, 50),
      32,
      Colors.yellow,
      FontWeight.bold,
    );

    _drawText(
      canvas,
      'Choose a power-up',
      Offset(size.x / 2 - 85, 90),
      16,
      Colors.white70,
    );

    // Draw 3 power-up cards
    const cardWidth = 220.0;
    const cardHeight = 300.0;
    const spacing = 30.0;
    final startX = (size.x - (cardWidth * 3 + spacing * 2)) / 2;
    final startY = 150.0;

    for (int i = 0; i < offers.length; i++) {
      final x = startX + (cardWidth + spacing) * i;
      final isHovered = _hoveredIndex == i;

      _drawPowerUpCard(
        canvas,
        offers[i],
        Offset(x, startY),
        cardWidth,
        cardHeight,
        i + 1, // Number key
        isHovered,
      );
    }

    // Instructions
    _drawText(
      canvas,
      'Press 1, 2, or 3 to select',
      Offset(size.x / 2 - 95, 520),
      14,
      Colors.white38,
    );
  }

  void _drawPowerUpCard(
    Canvas canvas,
    PowerUp powerUp,
    Offset position,
    double width,
    double height,
    int keyNumber,
    bool isHovered,
  ) {
    final rect = Rect.fromLTWH(position.dx, position.dy, width, height);

    // Card background
    final borderPaint = Paint()
      ..color = isHovered ? Colors.white : PowerUp.getRarityColor(powerUp.rarity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 4 : 2;

    // Glow effect for hovered
    if (isHovered) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(12)),
        Paint()
          ..color = PowerUp.getRarityColor(powerUp.rarity).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Card base
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      _cardBgPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );

    // Rarity label
    final rarityText = powerUp.rarity.name.toUpperCase();
    final rarityColor = PowerUp.getRarityColor(powerUp.rarity);
    _drawText(
      canvas,
      rarityText,
      Offset(position.dx + 10, position.dy + 10),
      10,
      rarityColor,
      FontWeight.bold,
    );

    // Icon (large emoji)
    _drawText(
      canvas,
      powerUp.icon,
      Offset(position.dx + width / 2 - 25, position.dy + 45),
      50,
      Colors.white,
      FontWeight.normal,
    );

    // Power-up name
    _drawText(
      canvas,
      powerUp.name,
      Offset(position.dx + width / 2 - powerUp.name.length * 4.5, position.dy + 120),
      18,
      Colors.white,
      FontWeight.bold,
    );

    // Stack indicator (if already owned)
    if (powerUp.stacks > 0) {
      final stackText = '${powerUp.stacks}/${powerUp.maxStacks}';
      _drawText(
        canvas,
        stackText,
        Offset(position.dx + width - 40, position.dy + 10),
        12,
        Colors.orange,
        FontWeight.bold,
      );
    }

    // Description (wrapped)
    _drawWrappedText(
      canvas,
      powerUp.description,
      Rect.fromLTWH(position.dx + 15, position.dy + 155, width - 30, 100),
      14,
      Colors.white70,
    );

    // Key hint
    _drawText(
      canvas,
      'Press $keyNumber',
      Offset(position.dx + width / 2 - 35, position.dy + height - 35),
      14,
      isHovered ? Colors.cyan : Colors.white38,
      FontWeight.bold,
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
          fontFamily: 'monospace',
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
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

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return false;

    // Number keys for selection
    if (event.logicalKey == LogicalKeyboardKey.digit1 ||
        event.logicalKey == LogicalKeyboardKey.numpad1) {
      onSelected?.call(0);
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
               event.logicalKey == LogicalKeyboardKey.numpad2) {
      onSelected?.call(1);
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
               event.logicalKey == LogicalKeyboardKey.numpad3) {
      onSelected?.call(2);
      return true;
    }

    // TODO: Arrow keys for navigation (optional)

    return false;
  }
}
