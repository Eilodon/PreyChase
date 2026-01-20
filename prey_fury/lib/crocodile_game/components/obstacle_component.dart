import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum ObstacleType {
  rock,
  log,
  whirlpool,
}

class ObstacleComponent extends PositionComponent {
  final ObstacleType type;
  
  final Paint _paint = Paint();

  ObstacleComponent({
    required this.type,
    required Vector2 position,
  }) : super(position: position, size: Vector2(40, 40), anchor: Anchor.center) {
     switch (type) {
       case ObstacleType.rock:
         _paint.color = Colors.grey.shade700;
         size = Vector2(40, 40);
         break;
       case ObstacleType.log:
         _paint.color = Colors.brown;
         size = Vector2(80, 20); // Wide
         break;
       case ObstacleType.whirlpool:
         _paint.color = Colors.lightBlueAccent.withOpacity(0.6);
         size = Vector2(60, 60);
         break;
     }
  }

  @override
  void render(Canvas canvas) {
    if (type == ObstacleType.rock) {
       // Irregular circle
       canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, _paint);
    } else if (type == ObstacleType.log) {
       // Rounded Rect
       canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10)), _paint);
    } else {
       // Whirlpool spiral
       canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, _paint);
       // Inner
       canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/4, Paint()..color=Colors.white30);
    }
  }
}
