// import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  bool isEnabled = true;

  Future<void> init() async {
    // Preload assets when available
    // await FlameAudio.audioCache.loadAll(['eat.wav', 'damage.wav', 'fury.mp3']);
  }

  void playSfx(String name) {
    if (!isEnabled) return;
    try {
      // FlameAudio.play('$name.wav');
      print('🔊 SFX: $name'); // Debug placeholder
    } catch (e) {
      print('Audio Error: $e');
    }
  }

  void playBgm(String name) {
    if (!isEnabled) return;
    try {
      // FlameAudio.bgm.play('$name.mp3');
      print('🎵 BGM: $name'); // Debug placeholder
    } catch (e) {
      print('Audio Error: $e');
    }
  }
}
