import 'package:test/test.dart';
import 'package:prey_fury/kernel/models/player_progress.dart';
import 'package:prey_fury/kernel/logic/shop_logic.dart';

void main() {
  group('PlayerProgress', () {
    test('Json Serialization works', () {
      final p = PlayerProgress(
        totalScore: 100,
        highScore: 200,
        unlockedFuryTypes: ['classic', 'lightning'],
        preyKills: {'angryApple': 10},
      );
      
      final jsonStr = p.toJsonString();
      final p2 = PlayerProgress.fromJsonString(jsonStr);
      
      expect(p2.totalScore, 100);
      expect(p2.highScore, 200);
      expect(p2.unlockedFuryTypes, contains('lightning'));
    });
  });

  group('ShopLogic', () {
    test('Cannot unlock if already owned', () {
      final p = PlayerProgress(unlockedFuryTypes: ['lightning'], totalScore: 5000);
      expect(ShopLogic.canUnlock(p, 'lightning'), false);
    });

    test('Cannot unlock if insufficient funds', () {
      final p = PlayerProgress(unlockedFuryTypes: ['classic'], totalScore: 10);
      expect(ShopLogic.canUnlock(p, 'lightning'), false);
    });

    test('Unlock deducts points and adds item', () {
      final p = PlayerProgress(unlockedFuryTypes: ['classic'], totalScore: 2000);
      final newItem = ShopLogic.unlock(p, 'lightning');
      
      expect(newItem.unlockedFuryTypes, contains('lightning'));
      expect(newItem.totalScore, 1000); // 2000 - 1000 cost
    });
  });
}
