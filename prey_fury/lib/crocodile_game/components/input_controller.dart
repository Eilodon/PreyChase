import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'crocodile_player.dart';
import 'fury_world.dart';

/// InputController provides touch/joystick input as fallback.
/// Keyboard input is handled directly by CrocodilePlayer.
class InputController extends Component with HasWorldReference<FuryWorld> {
  // Joystick for Touch
  late JoystickComponent joystick;
  bool isJoystickActive = false;

  @override
  Future<void> onLoad() async {
    final knobPaint = Paint()..color = Colors.white.withOpacity(0.5);
    final backgroundPaint = Paint()..color = Colors.white.withOpacity(0.2);
    
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    
    // Try to add joystick to game viewport
    try {
      // joystick should be added to viewport, not world
      // For now, disable joystick (keyboard only)
      isJoystickActive = false;
    } catch (e) {
      isJoystickActive = false;
    }
  }
  
  @override
  void update(double dt) {
    if (!isJoystickActive) return;
    
    // Joystick input supplements keyboard
    if (!joystick.delta.isZero()) {
      world.player.inputDirection = joystick.relativeDelta;
    }
  }
}
