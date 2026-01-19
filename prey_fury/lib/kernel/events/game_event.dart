import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class GameEventSnakeHitWall extends GameEvent {
  const GameEventSnakeHitWall();
}

class GameEventSnakeHitSelf extends GameEvent {
  const GameEventSnakeHitSelf();
}

class GameEventSnakeAteFood extends GameEvent {
  const GameEventSnakeAteFood();
}

class GameEventSnakeAtePrey extends GameEvent {
  const GameEventSnakeAtePrey();
}

class GameEventSnakeDamaged extends GameEvent {
  const GameEventSnakeDamaged();
}

class GameEventFuryActivated extends GameEvent {
  const GameEventFuryActivated();
}

class GameEventGameOver extends GameEvent {
  const GameEventGameOver();
}
