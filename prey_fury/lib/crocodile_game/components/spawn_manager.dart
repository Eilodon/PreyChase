import 'dart:math';
import 'package:flame/components.dart';
import '../../kernel/models/prey.dart';
import 'fury_world.dart';
import 'prey_component.dart';
import 'obstacle_component.dart';

class SpawnManager extends Component with HasWorldReference<FuryWorld> {
  final Random _rnd = Random();
  double _timer = 0.0;
  
  // Wave Config
  int waveIndex = 0;
  final List<WaveData> waves = [
     WaveData(duration: 15, maxFood: 20, packInterval: 0, bonusType: null),           // Wave 0: Gentle Start
     WaveData(duration: 30, maxFood: 15, packInterval: 10, bonusType: PreyType.goldenCake), // Wave 1: Forage & Bonus
     WaveData(duration: 60, maxFood: 10, packInterval: 5, bonusType: PreyType.ninjaSushi), // Wave 2: Hunted
  ];
  
  double _packTimer = 0.0;

  @override
  void update(double dt) {
     super.update(dt);
     
     if (waveIndex >= waves.length) return; // Endless or Loop? For now stop.
     
     final wave = waves[waveIndex];
     _timer += dt;
     _packTimer += dt;
     
     // 1. Refill Passive Food (Angry Apple, Zombie Burger)
     // We count loose prey
     final foodCount = world.children.whereType<PreyComponent>().length;
     if (foodCount < wave.maxFood) {
        _spawnRandomPrey();
     }
     
     // 2. Spawn Packs (Aggressive)
     if (wave.packInterval > 0 && _packTimer > wave.packInterval) {
        _packTimer = 0;
        _spawnPack();
     }
     
     // 3. Wave Progression
     if (_timer > wave.duration) {
        waveIndex = (waveIndex + 1) % waves.length; // Loop for now
        _timer = 0;
        // Announcement?
     }
  }
  
  void _spawnRandomPrey() {
     final pos = _randomPos();
     // Mostly Apple/Burger
     final type = _rnd.nextBool() ? PreyType.angryApple : PreyType.zombieBurger;
     world.add(PreyComponent(type: type, player: world.player, position: pos));
  }
  
  void _spawnPack() {
     // Spawn 3-5 Ninjas or Zombies in a cluster near player
     final center = world.player.position + Vector2(400, 400); // Offset
     int count = 3 + _rnd.nextInt(3);
     for (int i=0; i<count; i++) {
        final offset = Vector2(_rnd.nextDouble()*100, _rnd.nextDouble()*100);
        world.add(PreyComponent(
           type: PreyType.ninjaSushi,
           player: world.player,
           position: center + offset
        ));
     }
  }
  
  Vector2 _randomPos() {
     // Spawn near player but not too close?
     // Or just random arena?
     // Arena for now: 2000x2000
    return Vector2(
       (_rnd.nextDouble() * 2000) - 1000,
       (_rnd.nextDouble() * 2000) - 1000
     );
  }
}

class WaveData {
  final double duration;
  final int maxFood;
  final double packInterval; // 0 = disabled
  final PreyType? bonusType;
  
  WaveData({required this.duration, required this.maxFood, required this.packInterval, this.bonusType});
}
