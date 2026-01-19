import 'package:equatable/equatable.dart';
import 'grid_point.dart';

enum PreyType {
  angryApple,
  zombieBurger,
  ninjaSushi,
  ghostPizza,
  goldenCake,
}

enum PreyStatus {
  active,
  eaten,
  despawned,
}

class PreyEntity extends Equatable {
  final String id;
  final PreyType type;
  final GridPoint position;
  final PreyStatus status;
  final int spawnTick;

  const PreyEntity({
    required this.id,
    required this.type,
    required this.position,
    this.status = PreyStatus.active,
    required this.spawnTick,
  });

  PreyEntity copyWith({
    GridPoint? position,
    PreyStatus? status,
  }) {
    return PreyEntity(
      id: id,
      type: type,
      position: position ?? this.position,
      status: status ?? this.status,
      spawnTick: spawnTick,
    );
  }

  // Stats could be static maps or methods
  int get damage => type == PreyType.zombieBurger ? 3 : 1;
  int get scoreValue => type == PreyType.goldenCake ? 100 : 10;
  
  // Movement speed (ticks per move). Lower is faster.
  int get moveInterval {
     switch (type) {
       case PreyType.ninjaSushi: return 3; // Fast
       case PreyType.zombieBurger: return 8; // Slow
       default: return 5;
     }
  }

  @override
  List<Object?> get props => [id, type, position, status, spawnTick];
}
