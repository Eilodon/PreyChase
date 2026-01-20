import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_progress.dart';

class PersistenceManager {
  static const String _keyProgress = 'prey_fury_progress_v1';

  Future<void> saveProgress(PlayerProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProgress, progress.toJsonString());
  }

  Future<PlayerProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyProgress);
    
    if (jsonString != null) {
      try {
        return PlayerProgress.fromJsonString(jsonString);
      } catch (e) {
        // Return default if corrupt
        return const PlayerProgress();
      }
    }
    return const PlayerProgress();
  }
}
