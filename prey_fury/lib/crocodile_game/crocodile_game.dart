import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'components/fury_world.dart';
import 'components/crocodile_player.dart';

class CrocodileGame extends FlameGame {
  late FuryWorld _world;
  late CameraComponent cam;

  @override
  Color backgroundColor() => const Color(0xFF0A3D62); // Deep Water

  @override
  Future<void> onLoad() async {
    _world = FuryWorld();
    
    cam = CameraComponent.withFixedResolution(
       width: 800, 
       height: 600,
       world: _world
    );
    cam.viewfinder.anchor = Anchor.center;
    
    addAll([_world, cam]);
  }
  
  @override
  void update(double dt) {
     super.update(dt);
     // Auto-follow player once available
     if (!cam.isMounted) return; // Wait for mount?
     
     if (!cam.viewfinder.children.contains(cam.viewfinder.firstChild)) { 
        // Logic to check if following? 
        // Flame Camera follow is via .follow() method.
     }
     
     // Simple check: if not following, try to follow
     if (_world.isMounted) {
        final players = _world.children.whereType<CrocodilePlayer>();
        if (players.isNotEmpty) {
           cam.follow(players.first);
        }
     }
  }
}
