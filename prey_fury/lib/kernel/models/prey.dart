import 'package:equatable/equatable.dart';
import 'grid_point.dart';

enum PreyType {
  angryApple,
  zombieBurger,
  ninjaSushi,
  ghostPizza,
  goldenCake,
  boss, // 👹 BOSS
}

enum PreyStatus {
  active,
  eaten,
  despawned,
}

enum PreyEmotion {
  angry,      // 😠 Default chase
  terrified,  // 😱 Run away (khi snake Fury)
  desperate,  // 😰 Speed up (last alive)
  confused,   // 😵 Random move
}

class PreyEntity extends Equatable {
  final String id;
  final PreyType type;
  final GridPoint position;
  final PreyStatus status;
  final PreyEmotion emotion;
  final int spawnTick;
  final int health; // Current HP
  final int maxHealth; // Max HP

  const PreyEntity({
    required this.id,
    required this.type,
    required this.position,
    this.status = PreyStatus.active,
    this.emotion = PreyEmotion.angry,
    required this.spawnTick,
    this.health = 1,
    this.maxHealth = 1,
  });

  bool get isBoss => type == PreyType.boss;

  PreyEntity copyWith({
    GridPoint? position,
    PreyStatus? status,
    PreyEmotion? emotion,
    int? health,
  }) {
    return PreyEntity(
      id: id,
      type: type,
      position: position ?? this.position,
      status: status ?? this.status,
      emotion: emotion ?? this.emotion,
      spawnTick: spawnTick,
      health: health ?? this.health,
      maxHealth: maxHealth,
    );
  }

  // Stats could be static maps or methods
  int get damage => type == PreyType.boss ? 5 : (type == PreyType.zombieBurger ? 3 : 1);
  int get scoreValue => type == PreyType.boss ? 500 : (type == PreyType.goldenCake ? 100 : 10);
  
  // Movement speed (ticks per move). Lower is faster.
  int get moveInterval {
     switch (type) {
       case PreyType.boss: return 6; // Slower but deadly
       case PreyType.ninjaSushi: return 3; // Fast
       case PreyType.zombieBurger: return 8; // Slow
       default: return 5;
     }
  }

  @override
  List<Object?> get props => [id, type, position, status, emotion, spawnTick, health];
}
