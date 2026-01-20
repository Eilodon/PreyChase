import 'dart:math';
import 'package:flame/components.dart';
import '../../kernel/models/prey.dart';
import 'crocodile_player.dart';
import 'input_controller.dart';
import 'prey_component.dart';
import 'prey_component.dart';
import 'obstacle_component.dart';
import 'spawn_manager.dart';

class FuryWorld extends World {
  late CrocodilePlayer player;
  late InputController input;
  final Random _rnd = Random();

  @override
  Future<void> onLoad() async {
    player = CrocodilePlayer(position: Vector2(0, 0));
    add(player);
    
    input = InputController(player: player);
    add(input);
    
    // Spawn Ecosystem
    _spawnObstacles(20);
    // _spawnPrey(10); // Legacy
    add(SpawnManager()); // New Manager handles waves
  }
  
  @override
  void update(double dt) {
     super.update(dt);
     _checkCollisions();
  }
  
  void _checkCollisions() {
     // Naive O(N) check (fine for small N)
     
     // 1. Prey Collision (Eat)
     final preys = children.whereType<PreyComponent>().toList(); // Improve by caching list?
     for (final prey in preys) {
        if (prey.distance(player) < (player.size.x/2 + prey.size.x/2 - 5)) {
           // EAT
           player.grow(0.5); // Grow by 0.5 per prey
           prey.removeFromParent();
           // Particle Effect?
           // Audio?
        }
     }
     
     // 2. Obstacle Collision (Bounce)
     final obstacles = children.whereType<ObstacleComponent>();
     for (final obs in obstacles) {
        if (obs.distance(player) < (player.size.x/2 + obs.size.x/2)) {
           // BOUNCE
           Vector2 normal = (player.position - obs.position).normalized();
           if (normal.isZero()) normal = Vector2(1, 0); // specific case
           
           player.velocity = normal * 300; // Knockback
           player.grow(-0.2); // Lose some fat on hit? Or just bounce? Let's lose fat.
        }
     }
  }

  void _spawnObstacles(int count) {
     for (int i=0; i<count; i++) {
        final pos = _randomPos();
        final type = ObstacleType.values[_rnd.nextInt(ObstacleType.values.length)];
        add(ObstacleComponent(type: type, position: pos));
     }
  }
  
  /* Legacy Spawner
  void _spawnPrey(int count) {
     for (int i=0; i<count; i++) {
        final pos = _randomPos();
        // Weighted Random?
        PreyType type = PreyType.angryApple;
        double r = _rnd.nextDouble();
        if (r < 0.1) type = PreyType.goldenCake;
        else if (r < 0.3) type = PreyType.ninjaSushi;
        else if (r < 0.6) type = PreyType.zombieBurger;
        
        add(PreyComponent(type: type, player: player, position: pos));
     }
  }
  */
  
  Vector2 _randomPos() {
     // Spawn in a 2000x2000 arena centered on 0,0
     return Vector2(
       (_rnd.nextDouble() * 2000) - 1000,
       (_rnd.nextDouble() * 2000) - 1000
     );
  }
}
