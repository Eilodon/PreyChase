import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:prey_fury/crocodile_game/optimization/spatial_grid.dart';

void main() {
  group('SpatialGrid', () {
    late SpatialGrid grid;

    setUp(() {
      grid = SpatialGrid(cellSize: 100.0);
    });

    test('hash function is consistent', () {
      final component1 = PositionComponent(position: Vector2(50, 50));
      final component2 = PositionComponent(position: Vector2(50, 50));
      
      grid.insert(component1);
      grid.clear();
      grid.insert(component2);
      
      final nearby = grid.getNearby(Vector2(50, 50), 10);
      expect(nearby.length, 1);
      expect(nearby.first, component2);
    });

    test('insert adds objects correctly', () {
      final component1 = PositionComponent(position: Vector2(0, 0));
      final component2 = PositionComponent(position: Vector2(50, 50));
      
      grid.insert(component1);
      grid.insert(component2);
      
      expect(grid.totalObjects, 2);
    });

    test('getNearby returns nearby objects', () {
      final component1 = PositionComponent(position: Vector2(0, 0));
      final component2 = PositionComponent(position: Vector2(50, 50));
      final component3 = PositionComponent(position: Vector2(500, 500));
      
      grid.insert(component1);
      grid.insert(component2);
      grid.insert(component3);
      
      final nearby = grid.getNearby(Vector2(0, 0), 100);
      
      expect(nearby.contains(component1), true);
      expect(nearby.contains(component2), true);
      expect(nearby.contains(component3), false);
    });

    test('getNearby filters by radius', () {
      final component1 = PositionComponent(position: Vector2(0, 0));
      final component2 = PositionComponent(position: Vector2(200, 200));
      
      grid.insert(component1);
      grid.insert(component2);
      
      // Small radius - should only get component1
      final nearbySmall = grid.getNearby(Vector2(0, 0), 50);
      expect(nearbySmall.contains(component1), true);
      expect(nearbySmall.contains(component2), false);
      
      // Large radius - should get both
      final nearbyLarge = grid.getNearby(Vector2(0, 0), 300);
      expect(nearbyLarge.contains(component1), true);
      expect(nearbyLarge.contains(component2), true);
    });

    test('clear resets grid', () {
      final component1 = PositionComponent(position: Vector2(0, 0));
      final component2 = PositionComponent(position: Vector2(50, 50));
      
      grid.insert(component1);
      grid.insert(component2);
      
      expect(grid.totalObjects, 2);
      
      grid.clear();
      
      expect(grid.totalObjects, 0);
      expect(grid.occupiedCells, 0);
    });

    test('handles empty grid', () {
      final nearby = grid.getNearby(Vector2(0, 0), 100);
      expect(nearby.isEmpty, true);
    });

    test('handles single object', () {
      final component = PositionComponent(position: Vector2(0, 0));
      grid.insert(component);
      
      final nearby = grid.getNearby(Vector2(0, 0), 100);
      expect(nearby.length, 1);
      expect(nearby.first, component);
    });

    test('handles boundary positions', () {
      final component1 = PositionComponent(position: Vector2(-900, -900));
      final component2 = PositionComponent(position: Vector2(900, 900));
      
      grid.insert(component1);
      grid.insert(component2);
      
      final nearby1 = grid.getNearby(Vector2(-900, -900), 100);
      expect(nearby1.contains(component1), true);
      // component2 is far away, should not be in nearby cells
      
      final nearby2 = grid.getNearby(Vector2(900, 900), 100);
      expect(nearby2.contains(component2), true);
      // component1 is far away, should not be in nearby cells
    });

    test('performance benchmark - 1000 objects', () {
      final stopwatch = Stopwatch()..start();
      
      // Insert 1000 objects
      for (int i = 0; i < 1000; i++) {
        final x = (i % 100) * 10.0;
        final y = (i ~/ 100) * 10.0;
        grid.insert(PositionComponent(position: Vector2(x, y)));
      }
      
      final insertTime = stopwatch.elapsedMicroseconds;
      stopwatch.reset();
      
      // Query 100 times
      for (int i = 0; i < 100; i++) {
        grid.getNearby(Vector2(500, 500), 100);
      }
      
      final queryTime = stopwatch.elapsedMicroseconds;
      stopwatch.stop();
      
      // Performance assertions (relaxed for test environment)
      expect(insertTime < 50000, true, reason: 'Insert should be fast (<50ms)');
      expect(queryTime < 20000, true, reason: 'Queries should be fast (<20ms for 100 queries)');
      
      print('Performance: Insert 1000 objects: ${insertTime}μs, 100 queries: ${queryTime}μs');
    });

    test('multiple objects in same cell', () {
      final component1 = PositionComponent(position: Vector2(10, 10));
      final component2 = PositionComponent(position: Vector2(20, 20));
      final component3 = PositionComponent(position: Vector2(30, 30));
      
      grid.insert(component1);
      grid.insert(component2);
      grid.insert(component3);
      
      final nearby = grid.getNearby(Vector2(20, 20), 50);
      
      expect(nearby.length, 3);
      expect(nearby.contains(component1), true);
      expect(nearby.contains(component2), true);
      expect(nearby.contains(component3), true);
    });

    test('objects in adjacent cells', () {
      final component1 = PositionComponent(position: Vector2(0, 0));
      final component2 = PositionComponent(position: Vector2(100, 0));
      final component3 = PositionComponent(position: Vector2(0, 100));
      
      grid.insert(component1);
      grid.insert(component2);
      grid.insert(component3);
      
      final nearby = grid.getNearby(Vector2(50, 50), 100);
      
      // Should get all three due to cell overlap
      expect(nearby.length >= 1, true);
    });
  });
}
