import 'package:equatable/equatable.dart';

class GridPoint extends Equatable {
  final int x;
  final int y;

  const GridPoint(this.x, this.y);

  GridPoint operator +(GridPoint other) => GridPoint(x + other.x, y + other.y);
  GridPoint operator -(GridPoint other) => GridPoint(x - other.x, y - other.y);
  
  GridPoint operator *(int scalar) => GridPoint(x * scalar, y * scalar);

  /// Manhattan distance (|x| + |y|) - used for pathfinding
  int get manhattanDistance => x.abs() + y.abs();

  static const zero = GridPoint(0, 0);
  static const up = GridPoint(0, -1);
  static const down = GridPoint(0, 1);
  static const left = GridPoint(-1, 0);
  static const right = GridPoint(1, 0);

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => '($x, $y)';
}
