import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'crocodile_player.dart';

class InputController extends Component with HasGameRef, KeyboardHandler {
  final CrocodilePlayer player;
  
  // Joystick for Touch
  late JoystickComponent joystick;
  bool isJoystickActive = false;

  InputController({required this.player});

  @override
  Future<void> onLoad() async {
    // Logic to add Joystick if on mobile? 
    // For now we add a simple onscreen joystick for testing
    final knobPaint = Paint()..color = Colors.white.withOpacity(0.5);
    final backgroundPaint = Paint()..color = Colors.white.withOpacity(0.2);
    
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    
    // We add joystick to the GAME, not this component (needs HUD layer)
    gameRef.add(joystick); 
    isJoystickActive = true;
  }
  
  @override
  void update(double dt) {
    Vector2 input = Vector2.zero();
    
    // 1. Joystick Input
    if (isJoystickActive && !joystick.delta.isZero()) {
       input = joystick.relativeDelta; // Normalized? relativeDelta is -1 to 1
    }
    
    // 2. Keyboard Input override
    // We'll read raw keys from hardwareKeyboard for smooth polling in update loop
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    Vector2 keyInput = Vector2.zero();
    if (keys.contains(LogicalKeyboardKey.arrowUp) || keys.contains(LogicalKeyboardKey.keyW)) keyInput.y -= 1;
    if (keys.contains(LogicalKeyboardKey.arrowDown) || keys.contains(LogicalKeyboardKey.keyS)) keyInput.y += 1;
    if (keys.contains(LogicalKeyboardKey.arrowLeft) || keys.contains(LogicalKeyboardKey.keyA)) keyInput.x -= 1;
    if (keys.contains(LogicalKeyboardKey.arrowRight) || keys.contains(LogicalKeyboardKey.keyD)) keyInput.x += 1;
    
    if (!keyInput.isZero()) {
       input = keyInput.normalized();
    }
    
    // Smooth Decay or Instant Stop?
    // For Action RPG feel: Instant Stop is tighter.
    // For "Crocodile" heavy feel: Inertia.
    // Let's implementation basic velocity setting first.
    
    if (!input.isZero()) {
       player.setVelocity(input * player.maxSpeed);
    } else {
       player.setVelocity(Vector2.zero());
    }
  }
}
