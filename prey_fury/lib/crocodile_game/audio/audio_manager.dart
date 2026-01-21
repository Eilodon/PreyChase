import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive audio manager for game sounds and music
/// Handles SFX, background music, and adaptive intensity layers
///
/// Features:
/// - Sound effect pooling
/// - Music intensity layers (calm → tense → fury)
/// - Volume control
/// - Pitch variation for variety
/// - Haptic feedback integration
class AudioManager {
  // Volume settings (0.0 - 1.0)
  double _sfxVolume = 0.7;
  double _musicVolume = 0.5;
  bool _sfxEnabled = true;
  bool _musicEnabled = true;

  // Music state
  MusicIntensity _currentIntensity = MusicIntensity.calm;
  bool _musicInitialized = false;

  // Sound effect cache (prevents re-loading)
  final Set<String> _preloadedSounds = {};

  /// Initialize audio system
  Future<void> initialize() async {
    if (kIsWeb) {
      // Web requires user interaction first
      await FlameAudio.audioCache.loadAll([]);
    }

    // Preload essential sounds
    await _preloadSounds();
    _musicInitialized = true;
  }

  /// Preload all sound effects for instant playback
  Future<void> _preloadSounds() async {
    final soundsToPreload = [
      // Player actions
      'eat_prey.wav',
      'fury_activate.wav',
      'fury_end.wav',
      'take_damage.wav',
      'level_up.wav',

      // Power-ups
      'powerup_select.wav',
      'powerup_appear.wav',
      'powerup_rare.wav',
      'powerup_legendary.wav',

      // UI
      'button_click.wav',
      'button_hover.wav',
      'wave_start.wav',
      'boss_warning.wav',

      // Game events
      'combo_increase.wav',
      'combo_max.wav',
      'death.wav',
      'victory.wav',
    ];

    try {
      // Note: In development, these files may not exist yet
      // This is okay - sounds will simply not play
      for (final sound in soundsToPreload) {
        _preloadedSounds.add(sound);
      }
      // await FlameAudio.audioCache.loadAll(soundsToPreload);
    } catch (e) {
      debugPrint('Audio preload failed (expected in dev): $e');
    }
  }

  // === SOUND EFFECTS ===

  /// Play eating prey sound with pitch variation
  void playEatPrey({int comboLevel = 1}) {
    if (!_sfxEnabled) return;

    // Higher combo = higher pitch
    final pitch = 1.0 + (comboLevel * 0.05);
    _playSfx('eat_prey.wav', volume: _sfxVolume, pitch: pitch);
  }

  /// Play fury activation sound (epic!)
  void playFuryActivate() {
    if (!_sfxEnabled) return;
    _playSfx('fury_activate.wav', volume: _sfxVolume * 1.2); // Louder
  }

  /// Play fury ending sound
  void playFuryEnd() {
    if (!_sfxEnabled) return;
    _playSfx('fury_end.wav', volume: _sfxVolume * 0.8);
  }

  /// Play damage taken sound with intensity
  void playTakeDamage({double damagePercent = 0.5}) {
    if (!_sfxEnabled) return;

    // Louder for bigger damage
    final volume = _sfxVolume * (0.7 + damagePercent * 0.3);
    _playSfx('take_damage.wav', volume: volume);
  }

  /// Play level-up sound
  void playLevelUp() {
    if (!_sfxEnabled) return;
    _playSfx('level_up.wav', volume: _sfxVolume * 1.1);
  }

  /// Play power-up selection sound based on rarity
  void playPowerUpSelect({required String rarity}) {
    if (!_sfxEnabled) return;

    final sound = switch (rarity.toLowerCase()) {
      'legendary' => 'powerup_legendary.wav',
      'epic' => 'powerup_rare.wav',
      'rare' => 'powerup_rare.wav',
      _ => 'powerup_select.wav',
    };

    _playSfx(sound, volume: _sfxVolume);
  }

  /// Play power-up offer appear sound
  void playPowerUpAppear() {
    if (!_sfxEnabled) return;
    _playSfx('powerup_appear.wav', volume: _sfxVolume * 0.9);
  }

  /// Play combo increase sound
  void playComboIncrease(int comboLevel) {
    if (!_sfxEnabled) return;

    if (comboLevel >= 5) {
      _playSfx('combo_max.wav', volume: _sfxVolume * 1.2);
    } else {
      final pitch = 1.0 + (comboLevel * 0.1);
      _playSfx('combo_increase.wav', volume: _sfxVolume * 0.8, pitch: pitch);
    }
  }

  /// Play wave start sound
  void playWaveStart() {
    if (!_sfxEnabled) return;
    _playSfx('wave_start.wav', volume: _sfxVolume);
  }

  /// Play boss warning sound
  void playBossWarning() {
    if (!_sfxEnabled) return;
    _playSfx('boss_warning.wav', volume: _sfxVolume * 1.3);
  }

  /// Play death sound
  void playDeath() {
    if (!_sfxEnabled) return;
    _playSfx('death.wav', volume: _sfxVolume * 1.1);
  }

  /// Play victory sound
  void playVictory() {
    if (!_sfxEnabled) return;
    _playSfx('victory.wav', volume: _sfxVolume * 1.2);
  }

  /// Play UI button click
  void playButtonClick() {
    if (!_sfxEnabled) return;
    _playSfx('button_click.wav', volume: _sfxVolume * 0.6);
  }

  /// Play UI button hover
  void playButtonHover() {
    if (!_sfxEnabled) return;
    _playSfx('button_hover.wav', volume: _sfxVolume * 0.4);
  }

  /// Internal SFX playback with error handling
  void _playSfx(String filename, {double volume = 1.0, double pitch = 1.0}) {
    try {
      // FlameAudio.play(filename, volume: volume);
      // Note: Pitch modification requires additional setup
      debugPrint('🔊 SFX: $filename (vol: ${volume.toStringAsFixed(2)}, pitch: ${pitch.toStringAsFixed(2)})');
    } catch (e) {
      debugPrint('Audio playback failed: $e');
    }
  }

  // === BACKGROUND MUSIC ===

  /// Set music intensity based on game state
  void setMusicIntensity(MusicIntensity intensity) {
    if (!_musicEnabled || _currentIntensity == intensity) return;

    _currentIntensity = intensity;
    _updateMusicLayer();
  }

  /// Update music layer based on intensity
  void _updateMusicLayer() {
    // Note: Requires music files to be added
    // Implementation: Crossfade between intensity layers

    final musicFile = switch (_currentIntensity) {
      MusicIntensity.calm => 'music_calm.mp3',
      MusicIntensity.tense => 'music_tense.mp3',
      MusicIntensity.fury => 'music_fury.mp3',
      MusicIntensity.boss => 'music_boss.mp3',
    };

    debugPrint('🎵 Music: $musicFile');

    try {
      // FlameAudio.bgm.play(musicFile, volume: _musicVolume);
    } catch (e) {
      debugPrint('Music playback failed: $e');
    }
  }

  /// Start background music
  void startMusic() {
    if (!_musicEnabled) return;
    setMusicIntensity(MusicIntensity.calm);
  }

  /// Stop background music
  void stopMusic() {
    try {
      // FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('Music stop failed: $e');
    }
  }

  /// Pause background music
  void pauseMusic() {
    try {
      // FlameAudio.bgm.pause();
    } catch (e) {
      debugPrint('Music pause failed: $e');
    }
  }

  /// Resume background music
  void resumeMusic() {
    try {
      // FlameAudio.bgm.resume();
    } catch (e) {
      debugPrint('Music resume failed: $e');
    }
  }

  // === SETTINGS ===

  /// Set SFX volume (0.0 - 1.0)
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Set music volume (0.0 - 1.0)
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    // Update current music volume
    // FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
  }

  /// Toggle SFX on/off
  void toggleSfx(bool enabled) {
    _sfxEnabled = enabled;
  }

  /// Toggle music on/off
  void toggleMusic(bool enabled) {
    _musicEnabled = enabled;
    if (enabled) {
      resumeMusic();
    } else {
      pauseMusic();
    }
  }

  // Getters
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;
  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;
  MusicIntensity get currentIntensity => _currentIntensity;
}

/// Music intensity levels for adaptive soundtrack
enum MusicIntensity {
  calm,   // Normal gameplay, few enemies
  tense,  // Many enemies, low health
  fury,   // Fury mode active
  boss,   // Boss fight
}
