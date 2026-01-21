import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/fury_world.dart';
import 'components/crocodile_player.dart';
import 'components/spawn_manager.dart';
import 'components/performance_overlay.dart';

class CrocodileGame extends FlameGame with KeyboardEvents {
  late FuryWorld _world;
  late CameraComponent cam;
  late _HudOverlay hud;
  late PerformanceOverlay perfOverlay;

  // === PERFORMANCE FIX: Cache component references ===
  CrocodilePlayer? _cachedPlayer;
  SpawnManager? _cachedSpawnManager;

  // Callbacks
  final void Function(int score)? onGameOver;
  final void Function(int level, int stars)? onLevelComplete;

  CrocodileGame({this.onGameOver, this.onLevelComplete});

  @override
  Color backgroundColor() => const Color(0xFF0A3D62);

  @override
  Future<void> onLoad() async {
    _world = FuryWorld(
      onGameOver: (score) => onGameOver?.call(score),
      onLevelComplete: (level, stars) => onLevelComplete?.call(level, stars),
      onWaveComplete: (wave) => hud.showWaveAnnouncement(wave),
      onBossSpawn: () => hud.showBossWarning(),
      onTimeUp: () => onGameOver?.call(_world.player.score),
    );

    cam = CameraComponent.withFixedResolution(
      width: 800,
      height: 600,
      world: _world,
    );
    cam.viewfinder.anchor = Anchor.center;

    addAll([_world, cam]);

    hud = _HudOverlay();
    cam.viewport.add(hud);

    // Add performance overlay (disabled by default)
    perfOverlay = PerformanceOverlay();
    cam.viewport.add(perfOverlay);

    // === PERFORMANCE FIX: Cache component references after world loads ===
    await Future.delayed(const Duration(milliseconds: 100), () {
      _cachedPlayer = _world.children.whereType<CrocodilePlayer>().firstOrNull;
      _cachedSpawnManager = _world.children.whereType<SpawnManager>().firstOrNull;
    });
  }
  
  @override
  void update(double dt) {
    super.update(dt);

    // === PERFORMANCE FIX: Use cached references instead of whereType() ===
    if (_world.isMounted) {
      // Refresh cache if null (e.g., after level restart)
      _cachedPlayer ??= _world.children.whereType<CrocodilePlayer>().firstOrNull;
      _cachedSpawnManager ??= _world.children.whereType<SpawnManager>().firstOrNull;

      if (_cachedPlayer != null && _cachedPlayer!.isMounted) {
        cam.follow(_cachedPlayer!, maxSpeed: 500);

        if (_cachedSpawnManager != null && _cachedSpawnManager!.isMounted) {
          hud.updateFromGame(_cachedPlayer!, _cachedSpawnManager!, _world.currentWave);
        }
      } else {
        // Player was removed, clear cache
        _cachedPlayer = null;
        _cachedSpawnManager = null;
      }
    }
  }
  
  void restart() {
    _world.restartGame();
    _cachedPlayer = null;
    _cachedSpawnManager = null;
  }

  void restartLevel() {
    _world.restartLevel();
    _cachedPlayer = null;
    _cachedSpawnManager = null;
  }

  void nextLevel() {
    _world.nextLevel();
    _cachedPlayer = null;
    _cachedSpawnManager = null;
  }

  void loadLevel(int level) {
    _world.loadLevel(level);
    _cachedPlayer = null;
    _cachedSpawnManager = null;
  }
  
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // === DEBUG: Toggle performance overlay with F3 ===
    if (event is KeyDownEvent && keysPressed.contains(LogicalKeyboardKey.f3)) {
      PerformanceOverlay.toggle();
      return KeyEventResult.handled;
    }

    // Forward to player using cached reference
    if (_world.isMounted && _cachedPlayer != null && _cachedPlayer!.isMounted) {
      _cachedPlayer!.onKeyEvent(event, keysPressed);
    }
    return KeyEventResult.handled;
  }
}

/// Enhanced HUD Overlay with Time, Level, Wave info
class _HudOverlay extends PositionComponent with HasGameRef {
  // UI State
  int _score = 0;
  double _health = 100;
  double _maxHealth = 100;
  double _furyMeter = 0;
  bool _canActivateFury = false;
  bool _isFuryActive = false;
  int _combo = 1;
  int _wave = 1;
  int _totalWaves = 5;
  double _remainingTime = -1;
  String _levelName = "Level 1";
  
  // Announcements
  String? _announcement;
  double _announcementTimer = 0;
  
  double _time = 0;
  
  final Paint _healthBgPaint = Paint()..color = Colors.grey.shade800;
  final Paint _furyBgPaint = Paint()..color = Colors.grey.shade800;

  // === PERFORMANCE FIX: Cached Paint objects for health/fury bars ===
  final Paint _healthGreenPaint = Paint()..color = Colors.green;
  final Paint _healthOrangePaint = Paint()..color = Colors.orange;
  final Paint _healthRedPaint = Paint()..color = Colors.red;
  final Paint _furyOrangePaint = Paint()..color = Colors.orange;
  final Paint _furyCyanPaint = Paint()..color = Colors.cyan;
  final Paint _furyDarkOrangePaint = Paint();

  // === PERFORMANCE FIX: Cached TextPainters ===
  final Map<String, TextPainter> _textCache = {};
  int _cacheVersion = 0;

  _HudOverlay() : super(position: Vector2.zero()) {
    _furyDarkOrangePaint.color = Colors.orange.shade700;
  }
  
  void updateFromGame(CrocodilePlayer player, SpawnManager spawn, int currentWave) {
    _score = player.score;
    _health = player.health;
    _maxHealth = player.maxHealth;
    _furyMeter = player.furyMeter;
    _canActivateFury = player.canActivateFury;
    _isFuryActive = player.isFuryActive;
    _combo = player.comboMultiplier;
    _wave = spawn.currentWaveIndex + 1;
    _totalWaves = spawn.totalWaves;
    _remainingTime = spawn.remainingTime;
    _levelName = spawn.levelConfig.name;
  }
  
  void showWaveAnnouncement(int wave) {
    _announcement = "WAVE $wave";
    _announcementTimer = 2.0;
  }
  
  void showBossWarning() {
    _announcement = "⚠️ BOSS INCOMING! ⚠️";
    _announcementTimer = 3.0;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    
    if (_announcementTimer > 0) {
      _announcementTimer -= dt;
      if (_announcementTimer <= 0) {
        _announcement = null;
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    const double margin = 10;
    const double barHeight = 14;
    const double barWidth = 180;
    
    // === TOP LEFT: Level, Wave, Score ===
    _drawText(canvas, _levelName, Offset(margin, margin), 16, Colors.cyan);
    _drawText(canvas, 'Wave $_wave/$_totalWaves', Offset(margin, margin + 20), 14, Colors.white70);
    _drawText(canvas, 'SCORE: $_score', Offset(margin, margin + 40), 22, Colors.white);
    
    // Combo indicator
    if (_combo > 1) {
      final comboColor = _combo >= 5 ? Colors.yellow : (_combo >= 3 ? Colors.orange : Colors.white);
      _drawText(canvas, 'x$_combo COMBO!', Offset(margin, margin + 65), 16, comboColor);
    }
    
    // === TOP CENTER: Time (if applicable) ===
    if (_remainingTime >= 0) {
      final timeColor = _remainingTime < 10 ? Colors.red : Colors.white;
      final timeText = '⏱ ${_remainingTime.toInt()}s';
      _drawText(canvas, timeText, Offset(380, margin), 24, timeColor);
    }
    
    // === TOP RIGHT: Health & Fury ===
    final double rightX = 800 - barWidth - margin;
    
    // Health Bar
    _drawText(canvas, 'HP', Offset(rightX, margin), 12, Colors.white70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rightX + 25, margin, barWidth - 25, barHeight), const Radius.circular(4)),
      _healthBgPaint,
    );
    final healthPct = (_health / _maxHealth).clamp(0.0, 1.0);
    final healthPaint = healthPct > 0.5 ? _healthGreenPaint : (healthPct > 0.25 ? _healthOrangePaint : _healthRedPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rightX + 25, margin, (barWidth - 25) * healthPct, barHeight), const Radius.circular(4)),
      healthPaint,
    );
    _drawText(canvas, '${_health.toInt()}', Offset(rightX + barWidth / 2, margin + 1), 10, Colors.white);
    
    // Fury Bar
    final furyY = margin + 22;
    _drawText(canvas, 'FURY', Offset(rightX, furyY), 12, Colors.white70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rightX + 35, furyY, barWidth - 35, barHeight), const Radius.circular(4)),
      _furyBgPaint,
    );
    final furyPaint = _isFuryActive ? _furyOrangePaint : (_canActivateFury ? _furyCyanPaint : _furyDarkOrangePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rightX + 35, furyY, (barWidth - 35) * _furyMeter, barHeight), const Radius.circular(4)),
      furyPaint,
    );
    
    // Fury status
    if (_isFuryActive) {
      _drawText(canvas, '🔥 FURY!', Offset(rightX + 45, furyY + 1), 10, Colors.orange);
    } else if (_canActivateFury) {
      final flash = sin(_time * 10) > 0;
      if (flash) _drawText(canvas, '⚡ SPACE!', Offset(rightX + 45, furyY + 1), 10, Colors.cyan);
    }
    
    // === CENTER: Announcement ===
    if (_announcement != null) {
      // Use cached announcement text with larger size and distinct style
      final announcePaint = _getAnnouncementTextPainter(_announcement!);
      announcePaint.paint(canvas, Offset(400 - announcePaint.width / 2, 250));
    }
    
    // === BOTTOM: Controls ===
    _drawText(canvas, 'WASD: Move | SPACE: Fury | Eat prey in Fury mode!', Offset(180, 580), 11, Colors.white38);
  }
  
  TextPainter _getCachedTextPainter(String text, double fontSize, Color color) {
    final key = '$text-$fontSize-${color.value}';
    if (!_textCache.containsKey(key)) {
      _textCache[key] = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Limit cache size to prevent memory growth
      if (_textCache.length > 50) {
        _textCache.clear();
        _cacheVersion++;
      }
    }
    return _textCache[key]!;
  }

  TextPainter _getAnnouncementTextPainter(String text) {
    final key = 'announcement-$text';
    if (!_textCache.containsKey(key)) {
      _textCache[key] = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 8, offset: const Offset(2, 2)),
              Shadow(color: Colors.orange, blurRadius: 15),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Limit cache size
      if (_textCache.length > 50) {
        _textCache.clear();
        _cacheVersion++;
      }
    }
    return _textCache[key]!;
  }

  void _drawText(Canvas canvas, String text, Offset position, double fontSize, Color color) {
    final textPainter = _getCachedTextPainter(text, fontSize, color);
    textPainter.paint(canvas, position);
  }
}
