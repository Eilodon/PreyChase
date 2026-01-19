import 'dart:math';
import 'package:flame/components.dart';

class CameraShake {
  final Random _random = Random();
  double _duration = 0;
  double _intensity = 0;
  double _timer = 0;
  
  // The object to shake (usually the root component or camera wrapper)
  // For simple FlameGame, we can just apply an offset to the canvas via a wrapper,
  // or return an offset to be applied in render.
  
  Vector2 _offset = Vector2.zero();
  Vector2 get offset => _offset;
  
  void shake({double duration = 0.2, double intensity = 5.0}) {
    _duration = duration;
    _intensity = intensity;
    _timer = duration;
  }
  
  void update(double dt) {
    if (_timer > 0) {
       _timer -= dt;
       if (_timer <= 0) {
          _offset = Vector2.zero();
       } else {
          // Dampen intensity over time
          double currentIntensity = _intensity * (_timer / _duration);
          _offset = Vector2(
             (_random.nextDouble() * 2 - 1) * currentIntensity,
             (_random.nextDouble() * 2 - 1) * currentIntensity
          );
       }
    }
  }
}
