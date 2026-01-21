import 'dart:math';
import 'package:flame/components.dart';

/// High-performance spatial hash grid for neighbor queries
/// Reduces prey separation from O(N²) to O(N)
///
/// Implementation based on:
/// - Spatial Hashing (Teschner et al., 2003)
/// - Used by Unity, Unreal, Godot for physics optimization
class SpatialGrid<T extends PositionComponent> {
  final double cellSize;
  final Map<String, List<T>> _grid = {};

  // Performance metrics
  int _queryCount = 0;
  int _totalChecks = 0;

  /// Creates spatial grid with given cell size
  ///
  /// Cell size should be ~2x the query radius for optimal performance
  /// Example: For 40-unit radius queries, use cellSize = 80
  SpatialGrid({required this.cellSize});

  /// Clears grid and rebuilds from list of components
  /// Call this once per frame before queries
  void rebuild(List<T> components) {
    _grid.clear();
    for (final component in components) {
      final key = _getCellKey(component.position);
      (_grid[key] ??= []).add(component);
    }
  }

  /// Gets all neighbors within radius of position
  /// Much faster than checking all entities (O(N) vs O(N²))
  List<T> getNeighborsInRadius(Vector2 position, double radius) {
    _queryCount++;

    final neighbors = <T>[];
    final radiusSq = radius * radius;

    // Check all cells that could contain neighbors
    final cellsToCheck = _getCellsInRadius(position, radius);

    for (final cellKey in cellsToCheck) {
      final cellEntities = _grid[cellKey];
      if (cellEntities == null) continue;

      for (final entity in cellEntities) {
        _totalChecks++;

        // Fast squared distance check (avoids sqrt)
        final distSq = position.distanceToSquared(entity.position);
        if (distSq <= radiusSq) {
          neighbors.add(entity);
        }
      }
    }

    return neighbors;
  }

  /// Gets cell key for a position
  String _getCellKey(Vector2 position) {
    final x = (position.x / cellSize).floor();
    final y = (position.y / cellSize).floor();
    return '$x,$y';
  }

  /// Gets all cells that could contain entities within radius
  List<String> _getCellsInRadius(Vector2 position, double radius) {
    final cells = <String>[];

    // Calculate cell range
    final minX = ((position.x - radius) / cellSize).floor();
    final maxX = ((position.x + radius) / cellSize).floor();
    final minY = ((position.y - radius) / cellSize).floor();
    final maxY = ((position.y + radius) / cellSize).floor();

    // Iterate over cell grid
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells.add('$x,$y');
      }
    }

    return cells;
  }

  /// Gets performance statistics
  SpatialGridStats getStats() {
    final avgChecksPerQuery = _queryCount > 0
        ? (_totalChecks / _queryCount).round()
        : 0;

    return SpatialGridStats(
      totalCells: _grid.length,
      totalEntities: _grid.values.fold(0, (sum, list) => sum + list.length),
      avgEntitiesPerCell: _grid.isNotEmpty
          ? (_grid.values.fold(0, (sum, list) => sum + list.length) / _grid.length).round()
          : 0,
      queriesThisFrame: _queryCount,
      avgChecksPerQuery: avgChecksPerQuery,
    );
  }

  /// Resets performance counters (call once per frame)
  void resetStats() {
    _queryCount = 0;
    _totalChecks = 0;
  }
}

/// Performance statistics for spatial grid
class SpatialGridStats {
  final int totalCells;
  final int totalEntities;
  final int avgEntitiesPerCell;
  final int queriesThisFrame;
  final int avgChecksPerQuery;

  const SpatialGridStats({
    required this.totalCells,
    required this.totalEntities,
    required this.avgEntitiesPerCell,
    required this.queriesThisFrame,
    required this.avgChecksPerQuery,
  });

  @override
  String toString() {
    return 'SpatialGrid: $totalEntities entities in $totalCells cells '
           '(avg ${avgEntitiesPerCell}/cell), '
           '$queriesThisFrame queries (avg $avgChecksPerQuery checks/query)';
  }
}
