/// Announcer & Screen Effects System
/// Part of PREY CHAOS - Juice/WOW Moments

import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Announcement types with different visual styles
enum AnnouncementType {
  combo,        // "COMBO x20!"
  style,        // "PERFECT!", "GODLIKE!"
  wave,         // "WAVE 5 INCOMING"
  event,        // "PREY RUSH!" 
  boss,         // "BOSS INCOMING!"
  achievement,  // "ACHIEVEMENT UNLOCKED"
  mutation,     // "MUTATION ACQUIRED"
}

/// Screen effect types
enum ScreenEffectType {
  shake,
  flash,
  slowMo,
  zoomPulse,
  shockwave,
  vignette,
  chromatic,
}

/// Single announcement data
class Announcement {
  final String text;
  final AnnouncementType type;
  final Color color;
  final double fontSize;
  final double duration;
  final double? value; // For combos, multipliers
  
  const Announcement({
    required this.text,
    required this.type,
    this.color = Colors.white,
    this.fontSize = 48.0,
    this.duration = 1.5,
    this.value,
  });
}

/// Style rating thresholds
class StyleMeter {
  static const Map<String, int> thresholds = {
    'D': 0,
    'C': 5,
    'B': 10,
    'A': 15,
    'S': 20,
    'SS': 30,
    'SSS': 50,
  };
  
  static const Map<String, Color> colors = {
    'D': Color(0xFF757575),
    'C': Color(0xFF4CAF50),
    'B': Color(0xFF2196F3),
    'A': Color(0xFF9C27B0),
    'S': Color(0xFFFF9800),
    'SS': Color(0xFFFF5722),
    'SSS': Color(0xFFFFD700),
  };
  
  static const Map<String, String> titles = {
    'D': 'DULL',
    'C': 'COOL',
    'B': 'BRUTAL',
    'A': 'AWESOME',
    'S': 'STYLISH',
    'SS': 'SICK SKILLS',
    'SSS': 'SENSATIONAL!',
  };
  
  static String getRating(int comboCount) {
    if (comboCount >= 50) return 'SSS';
    if (comboCount >= 30) return 'SS';
    if (comboCount >= 20) return 'S';
    if (comboCount >= 15) return 'A';
    if (comboCount >= 10) return 'B';
    if (comboCount >= 5) return 'C';
    return 'D';
  }
  
  static Color getColor(String rating) => colors[rating] ?? Colors.grey;
  static String getTitle(String rating) => titles[rating] ?? '';
}

/// Announcer component for displaying text effects
class AnnouncerComponent extends PositionComponent {
  final List<_ActiveAnnouncement> _active = [];
  final Random _random = Random();
  
  void announce(Announcement announcement) {
    _active.add(_ActiveAnnouncement(
      announcement: announcement,
      elapsed: 0.0,
      offsetY: _random.nextDouble() * 20 - 10,
      scale: 0.0,
    ));
  }
  
  void announceCombo(int count) {
    final rating = StyleMeter.getRating(count);
    final color = StyleMeter.getColor(rating);
    
    String text;
    double fontSize;
    
    if (count >= 50) {
      text = '🔥 G O D L I K E 🔥';
      fontSize = 72.0;
    } else if (count >= 30) {
      text = '⚡ UNSTOPPABLE! ⚡';
      fontSize = 64.0;
    } else if (count >= 20) {
      text = '💀 MASSACRE! x$count';
      fontSize = 56.0;
    } else if (count >= 10) {
      text = '🔥 COMBO x$count!';
      fontSize = 48.0;
    } else if (count >= 5) {
      text = 'COMBO x$count';
      fontSize = 40.0;
    } else {
      return; // No announcement for low combos
    }
    
    announce(Announcement(
      text: text,
      type: AnnouncementType.combo,
      color: color,
      fontSize: fontSize,
      duration: 1.5,
      value: count.toDouble(),
    ));
  }
  
  void announceStyle(String styleType) {
    final styles = {
      'perfect': ('⚡ PERFECT! ⚡', const Color(0xFFFFD700)),
      'close_call': ('😱 CLOSE CALL!', const Color(0xFFFF5722)),
      'chain': ('⛓️ CHAIN KILL!', const Color(0xFF9C27B0)),
      'fury_finish': ('🔥 FURY FINISH!', const Color(0xFFFF9800)),
    };
    
    final data = styles[styleType];
    if (data == null) return;
    
    announce(Announcement(
      text: data.$1,
      type: AnnouncementType.style,
      color: data.$2,
      fontSize: 52.0,
    ));
  }
  
  void announceWave(int wave) {
    announce(Announcement(
      text: '═══ WAVE $wave ═══',
      type: AnnouncementType.wave,
      color: const Color(0xFF4CAF50),
      fontSize: 56.0,
      duration: 2.0,
    ));
  }
  
  void announceEvent(String eventName, Color color) {
    announce(Announcement(
      text: eventName,
      type: AnnouncementType.event,
      color: color,
      fontSize: 48.0,
      duration: 2.5,
    ));
  }
  
  void announceBoss(String bossName) {
    announce(Announcement(
      text: '⚠️ $bossName ⚠️',
      type: AnnouncementType.boss,
      color: const Color(0xFFD50000),
      fontSize: 64.0,
      duration: 3.0,
    ));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    for (final a in _active) {
      a.elapsed += dt;
      
      // Scale animation
      if (a.elapsed < 0.15) {
        a.scale = (a.elapsed / 0.15) * 1.2; // Overshoot
      } else if (a.elapsed < 0.25) {
        a.scale = 1.2 - ((a.elapsed - 0.15) / 0.1) * 0.2; // Settle
      } else {
        a.scale = 1.0;
      }
      
      // Fade out
      final remaining = a.announcement.duration - a.elapsed;
      if (remaining < 0.5) {
        a.opacity = remaining / 0.5;
      } else {
        a.opacity = 1.0;
      }
    }
    
    // Remove expired
    _active.removeWhere((a) => a.elapsed >= a.announcement.duration);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final screenCenter = size / 2;
    double yOffset = screenCenter.y * 0.3; // Start near top-center
    
    for (final a in _active) {
      _renderAnnouncement(canvas, a, screenCenter.x, yOffset);
      yOffset += 80 * a.scale;
    }
  }
  
  void _renderAnnouncement(
    Canvas canvas, 
    _ActiveAnnouncement a, 
    double centerX, 
    double y,
  ) {
    final text = a.announcement.text;
    final color = a.announcement.color.withOpacity(a.opacity);
    final fontSize = a.announcement.fontSize * a.scale;
    
    // Text style
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.7 * a.opacity),
              offset: const Offset(3, 3),
              blurRadius: 6,
            ),
            Shadow(
              color: color.withOpacity(0.5 * a.opacity),
              blurRadius: 20,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final x = centerX - textPainter.width / 2;
    final adjustedY = y + a.offsetY;
    
    textPainter.paint(canvas, Offset(x, adjustedY));
  }
}

class _ActiveAnnouncement {
  final Announcement announcement;
  double elapsed;
  double offsetY;
  double scale;
  double opacity;
  
  _ActiveAnnouncement({
    required this.announcement,
    required this.elapsed,
    required this.offsetY,
    required this.scale,
    this.opacity = 1.0,
  });
}

/// Screen effects manager
class ScreenEffectsManager {
  // Active effects
  double _shakeIntensity = 0.0;
  double _shakeTimer = 0.0;
  Color _flashColor = Colors.transparent;
  double _flashTimer = 0.0;
  double _slowMoScale = 1.0;
  double _slowMoTimer = 0.0;
  double _zoomScale = 1.0;
  double _zoomTimer = 0.0;
  double _vignetteIntensity = 0.0;
  double _chromaticIntensity = 0.0;
  
  final Random _random = Random();
  
  // Getters
  double get shakeX => _shakeTimer > 0 
      ? (_random.nextDouble() - 0.5) * _shakeIntensity 
      : 0.0;
  double get shakeY => _shakeTimer > 0 
      ? (_random.nextDouble() - 0.5) * _shakeIntensity 
      : 0.0;
  Color get flashColor => _flashColor.withOpacity(
      _flashTimer > 0 ? (_flashTimer * 2).clamp(0.0, 1.0) : 0.0);
  double get timeScale => _slowMoScale;
  double get zoomScale => _zoomScale;
  double get vignetteIntensity => _vignetteIntensity;
  double get chromaticIntensity => _chromaticIntensity;
  
  /// Trigger screen shake
  void shake({double intensity = 10.0, double duration = 0.3}) {
    _shakeIntensity = intensity;
    _shakeTimer = duration;
  }
  
  /// Trigger screen flash
  void flash({Color color = Colors.white, double duration = 0.1}) {
    _flashColor = color;
    _flashTimer = duration;
  }
  
  /// Trigger slow motion
  void slowMo({double scale = 0.3, double duration = 0.5}) {
    _slowMoScale = scale;
    _slowMoTimer = duration;
  }
  
  /// Trigger zoom pulse
  void zoomPulse({double scale = 1.1, double duration = 0.2}) {
    _zoomScale = scale;
    _zoomTimer = duration;
  }
  
  /// Set vignette intensity
  void vignette({double intensity = 0.5, double duration = 1.0}) {
    _vignetteIntensity = intensity;
    // Fade out over duration - handled in update
  }
  
  /// Set chromatic aberration
  void chromatic({double intensity = 0.05, double duration = 0.2}) {
    _chromaticIntensity = intensity;
  }
  
  /// Fury activation effect combo
  void furyActivation() {
    shake(intensity: 20.0, duration: 0.5);
    flash(color: Colors.orange, duration: 0.15);
    slowMo(scale: 0.2, duration: 0.5);
    zoomPulse(scale: 1.15, duration: 0.3);
    vignette(intensity: 0.6);
    chromatic(intensity: 0.08, duration: 0.3);
  }
  
  /// Boss spawn effect combo
  void bossSpawn() {
    shake(intensity: 15.0, duration: 1.0);
    flash(color: Colors.red, duration: 0.1);
    vignette(intensity: 0.7);
  }
  
  /// Kill effect (scaled by combo)
  void killEffect(int comboCount) {
    final intensity = 5.0 + min(comboCount * 0.5, 15.0);
    shake(intensity: intensity, duration: 0.1);
    
    if (comboCount >= 10) {
      zoomPulse(scale: 1.0 + (comboCount * 0.002), duration: 0.1);
    }
    if (comboCount >= 20) {
      chromatic(intensity: 0.03, duration: 0.1);
    }
  }
  
  void update(double dt) {
    // Shake decay
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      if (_shakeTimer <= 0) _shakeIntensity = 0.0;
    }
    
    // Flash decay
    if (_flashTimer > 0) {
      _flashTimer -= dt;
    }
    
    // Slow-mo decay
    if (_slowMoTimer > 0) {
      _slowMoTimer -= dt;
      if (_slowMoTimer <= 0) _slowMoScale = 1.0;
    }
    
    // Zoom decay
    if (_zoomTimer > 0) {
      _zoomTimer -= dt;
      if (_zoomTimer <= 0) {
        _zoomScale = 1.0;
      } else {
        // Lerp back to 1.0
        _zoomScale = lerpDouble(_zoomScale, 1.0, dt * 5)!;
      }
    }
    
    // Vignette decay
    if (_vignetteIntensity > 0) {
      _vignetteIntensity = max(0, _vignetteIntensity - dt * 0.5);
    }
    
    // Chromatic decay
    if (_chromaticIntensity > 0) {
      _chromaticIntensity = max(0, _chromaticIntensity - dt * 0.3);
    }
  }
  
  /// Reset all effects
  void reset() {
    _shakeIntensity = 0.0;
    _shakeTimer = 0.0;
    _flashColor = Colors.transparent;
    _flashTimer = 0.0;
    _slowMoScale = 1.0;
    _slowMoTimer = 0.0;
    _zoomScale = 1.0;
    _zoomTimer = 0.0;
    _vignetteIntensity = 0.0;
    _chromaticIntensity = 0.0;
  }
}
