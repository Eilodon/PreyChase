import '../models/player_progress.dart';
import '../state/game_state.dart';

class ShopLogic {
  static const int costLightning = 1000;
  static const int costVoid = 5000;

  static bool canUnlock(PlayerProgress progress, String itemId) {
    if (progress.unlockedFuryTypes.contains(itemId)) return false; // Already owned
    
    if (itemId == 'lightning') return progress.totalScore >= costLightning;
    if (itemId == 'voidFury') return progress.totalScore >= costVoid;
    
    return false;
  }

  static PlayerProgress unlock(PlayerProgress progress, String itemId) {
    if (!canUnlock(progress, itemId)) return progress;

    int cost = 0;
    if (itemId == 'lightning') cost = costLightning;
    if (itemId == 'voidFury') cost = costVoid;

    final newUnlocks = List<String>.from(progress.unlockedFuryTypes)..add(itemId);
    
    return progress.copyWith(
      totalScore: progress.totalScore - cost, // Deduct currency? Or just Achievement unlock? Plan said "Cost 1000 points". Use Score as Currency.
      unlockedFuryTypes: newUnlocks,
    );
  }
}
