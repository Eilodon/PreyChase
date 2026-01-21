import 'package:flame/components.dart';
import 'dart:collection';
import 'dart:math';

/// Spatial Hash Grid - Fast proximity queries
/// 
/// Before: Check all objects (n²)
/// After: Only check nearby cells (k where k << n)
/// 
/// Performance: 20 prey × 30 obstacles = 600 checks
///             → Only ~9 checks per query (3×3 grid)
class SpatialGrid {
  final double cellSize;
  final HashMap<int, List<PositionComponent>> _grid = HashMap();
  
  // Stats for debugging
  int _totalInserts = 0;
  int _totalQueries = 0;
  int _avgCellsChecked = 0;
  
  SpatialGrid({this.cellSize = 100.0});
  
  /// Hash function for grid cell
  /// Uses prime numbers để tránh collision
  int _hash(double x, double y) {
    final cellX = (x / cellSize).floor();
    final cellY = (y / cellSize).floor();
    // XOR với prime numbers
    return cellX * 73856093 ^ cellY * 19349663;
  }
  
  /// Clear grid (call mỗi frame trước khi rebuild)
  void clear() {
    _grid.clear();
    _totalInserts = 0;
    _totalQueries = 0;
  }
  
  /// Insert object vào grid
  void insert(PositionComponent obj) {
    final hash = _hash(obj.position.x, obj.position.y);
    _grid.putIfAbsent(hash, () => []).add(obj);
    _totalInserts++;
  }
  
  /// Query all objects trong radius
  /// Returns only objects in nearby cells
  List<PositionComponent> getNearby(Vector2 position, double radius) {
    final results = <PositionComponent>[];
    final cells = _getCellsInRadius(position, radius);
    
    _avgCellsChecked = cells.length;
    _totalQueries++;
    
    for (final cellHash in cells) {
      final objects = _grid[cellHash];
      if (objects != null) {
        results.addAll(objects);
      }
    }
    
    return results;
  }
  
  /// Get all cell hashes trong radius
  List<int> _getCellsInRadius(Vector2 center, double radius) {
    final cells = <int>{};
    
    // Tính bounds
    final minX = ((center.x - radius) / cellSize).floor();
    final maxX = ((center.x + radius) / cellSize).floor();
    final minY = ((center.y - radius) / cellSize).floor();
    final maxY = ((center.y + radius) / cellSize).floor();
    
    // Add all cells in bounding box
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells.add(x * 73856093 ^ y * 19349663);
      }
    }
    
    return cells.toList();
  }
  
  /// Debug: Print stats
  void printStats() {
    print('=== Spatial Grid Stats ===');
    print('Total Inserts: $_totalInserts');
    print('Total Queries: $_totalQueries');
    print('Avg Cells Checked: $_avgCellsChecked');
    print('Grid Size: ${_grid.length} occupied cells');
  }
  
  /// Get total number of objects in grid
  int get totalObjects => _totalInserts;
  
  /// Get number of occupied cells
  int get occupiedCells => _grid.length;
}
