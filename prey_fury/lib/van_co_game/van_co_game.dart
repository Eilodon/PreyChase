/// Vạn Cổ Chi Vương - Main Game Widget
///
/// Entry point that connects all game components:
/// - Faction selection → Game → Game over
/// - Manages game lifecycle
/// - Handles audio and visual effects

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../kernel/models/critter.dart';
import '../kernel/models/ngu_hanh_faction.dart';
import '../kernel/systems/battle_royale_manager.dart';
import '../kernel/systems/lightning_system.dart';
import 'components/ai_controller.dart';
import 'components/critter_component.dart';
import 'components/lightning_renderer.dart';
import 'components/player_controller.dart';
import 'components/van_co_world.dart';
import 'components/zone_renderer.dart';
import 'screens/faction_select_screen.dart';
import 'ui/battle_royale_hud.dart';

/// Game state enum
enum VanCoGameState {
  menu,
  factionSelect,
  playing,
  paused,
  gameOver,
}

/// Main Game Widget - Flutter Widget entry point
class VanCoGameWidget extends StatefulWidget {
  const VanCoGameWidget({super.key});

  @override
  State<VanCoGameWidget> createState() => _VanCoGameWidgetState();
}

class _VanCoGameWidgetState extends State<VanCoGameWidget> {
  VanCoGameState _state = VanCoGameState.menu;
  NguHanhFaction? _selectedFaction;
  VanCoFlameGame? _game;

  // Game results
  int _finalPlacement = 0;
  int _finalKills = 0;
  int _timeSurvived = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_state) {
      case VanCoGameState.menu:
        return _buildMainMenu();
      case VanCoGameState.factionSelect:
        return FactionSelectScreen(
          onFactionSelected: _onFactionSelected,
          onBack: () => setState(() => _state = VanCoGameState.menu),
        );
      case VanCoGameState.playing:
      case VanCoGameState.paused:
        return _buildGameScreen();
      case VanCoGameState.gameOver:
        return _buildGameOverScreen();
    }
  }

  Widget _buildMainMenu() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const Text(
                  '🐛',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF6B35)],
                  ).createShader(bounds),
                  child: const Text(
                    'VẠN CỔ CHI VƯƠNG',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Feeding Frenzy × Agar.io × Battle Royale',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: 60),

                // Play Button
                _buildMenuButton(
                  'BẮT ĐẦU',
                  Icons.play_arrow,
                  const Color(0xFF4CAF50),
                  () => setState(() => _state = VanCoGameState.factionSelect),
                ),

                const SizedBox(height: 16),

                // Settings Button
                _buildMenuButton(
                  'CÀI ĐẶT',
                  Icons.settings,
                  Colors.grey,
                  () {
                    // TODO: Settings screen
                  },
                ),

                const SizedBox(height: 16),

                // How to Play
                _buildMenuButton(
                  'HƯỚNG DẪN',
                  Icons.help_outline,
                  Colors.blue,
                  _showHowToPlay,
                ),

                const SizedBox(height: 40),

                // Version
                Text(
                  'v2.0 - Full Pivot',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'CÁCH CHƠI',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHowToPlayItem('🎯', 'Di chuyển', 'Chuột để di chuyển'),
              _buildHowToPlayItem('⚔️', 'Ăn thịt', 'Ăn con nhỏ hơn 90% size'),
              _buildHowToPlayItem('💀', 'Tránh né', 'Tránh con lớn hơn 110% size'),
              _buildHowToPlayItem('🔀', 'Phân thân', 'SPACE để split'),
              _buildHowToPlayItem('💨', 'Bắn mass', 'W để eject mass'),
              _buildHowToPlayItem('⚡', 'Thiên Kiếp', 'Tránh sét (vòng đỏ)'),
              _buildHowToPlayItem('☠️', 'Độc khí', 'Ở trong vùng an toàn'),
              _buildHowToPlayItem('🏆', 'Chiến thắng', 'Là người sống sót cuối!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HIỂU RỒI'),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayItem(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onFactionSelected(NguHanhFaction faction) {
    setState(() {
      _selectedFaction = faction;
      _state = VanCoGameState.playing;
      _game = VanCoFlameGame(
        playerFaction: faction,
        onGameOver: _onGameOver,
        onPause: _onPause,
      );
    });
  }

  Widget _buildGameScreen() {
    if (_game == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Flame Game
        GameWidget(game: _game!),

        // Pause overlay
        if (_state == VanCoGameState.paused) _buildPauseOverlay(),
      ],
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TẠM DỪNG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildMenuButton(
              'TIẾP TỤC',
              Icons.play_arrow,
              Colors.green,
              () {
                setState(() => _state = VanCoGameState.playing);
                _game?.resumeGame();
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              'THOÁT',
              Icons.exit_to_app,
              Colors.red,
              () {
                setState(() {
                  _state = VanCoGameState.menu;
                  _game = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onPause() {
    setState(() => _state = VanCoGameState.paused);
    _game?.pauseGame();
  }

  void _onGameOver(int placement, int kills, int timeSurvived) {
    setState(() {
      _state = VanCoGameState.gameOver;
      _finalPlacement = placement;
      _finalKills = kills;
      _timeSurvived = timeSurvived;
    });
  }

  Widget _buildGameOverScreen() {
    final isWinner = _finalPlacement == 1;
    final factionData = _selectedFaction != null
        ? NguHanhRegistry.get(_selectedFaction!)
        : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWinner
                ? [const Color(0xFF1A472A), const Color(0xFF0D2818)]
                : [const Color(0xFF4A1A1A), const Color(0xFF2A0D0D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Result emoji
                Text(
                  isWinner ? '👑' : '💀',
                  style: const TextStyle(fontSize: 80),
                ),

                const SizedBox(height: 16),

                // Result text
                Text(
                  isWinner ? 'CỔ VƯƠNG!' : 'BỊ TIÊU DIỆT',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isWinner ? Colors.yellow : Colors.red,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 32),

                // Stats
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow('🏆 Hạng', '#$_finalPlacement/20'),
                      const SizedBox(height: 12),
                      _buildStatRow('⚔️ Kills', '$_finalKills'),
                      const SizedBox(height: 12),
                      _buildStatRow('⏱️ Thời gian', _formatTime(_timeSurvived)),
                      if (factionData != null) ...[
                        const SizedBox(height: 12),
                        _buildStatRow('${factionData.emoji} Tộc', factionData.nameVi),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons
                _buildMenuButton(
                  'CHƠI LẠI',
                  Icons.refresh,
                  Colors.green,
                  () {
                    if (_selectedFaction != null) {
                      _onFactionSelected(_selectedFaction!);
                    }
                  },
                ),

                const SizedBox(height: 16),

                _buildMenuButton(
                  'ĐỔI TỘC',
                  Icons.swap_horiz,
                  Colors.blue,
                  () => setState(() => _state = VanCoGameState.factionSelect),
                ),

                const SizedBox(height: 16),

                _buildMenuButton(
                  'MENU CHÍNH',
                  Icons.home,
                  Colors.grey,
                  () => setState(() {
                    _state = VanCoGameState.menu;
                    _game = null;
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Flame Game class - Main game logic
class VanCoFlameGame extends FlameGame
    with HasKeyboardHandlerComponents, MouseMovementDetector, TapDetector {
  final NguHanhFaction playerFaction;
  final void Function(int placement, int kills, int timeSurvived) onGameOver;
  final VoidCallback onPause;

  // === GAME SYSTEMS ===
  late VanCoWorld gameWorld;
  late ZoneRenderer zoneRenderer;
  late LightningRenderer lightningRenderer;
  late PlayerController playerController;

  // === STATE ===
  bool _isPaused = false;
  bool _isGameOver = false;

  // === HUD DATA ===
  final List<KillFeedEntry> killFeed = [];
  bool showZoneWarning = false;

  VanCoFlameGame({
    required this.playerFaction,
    required this.onGameOver,
    required this.onPause,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create game world
    gameWorld = VanCoWorld(
      playerFaction: playerFaction,
      aiCount: 19,
      difficulty: 5,
    );

    // Setup callbacks
    gameWorld.onGameEvent = _handleGameEvent;
    gameWorld.onGameOver = (placement, kills, time) {
      _isGameOver = true;
      onGameOver(placement, kills, time);
    };

    // Create renderers
    zoneRenderer = ZoneRenderer(brManager: gameWorld._brManager);
    lightningRenderer = LightningRenderer(lightningSystem: gameWorld._lightningSystem);

    // Add to world
    world.add(gameWorld);
    world.add(zoneRenderer);
    world.add(lightningRenderer);

    // Setup camera
    camera.viewfinder.anchor = Anchor.center;
    camera.viewport = MaxViewport();

    // Start game
    gameWorld.startGame();

    // Follow player
    camera.follow(gameWorld.playerCritter);
  }

  @override
  void update(double dt) {
    if (_isPaused || _isGameOver) return;
    super.update(dt);

    // Update zone warning
    final brState = gameWorld.brState;
    showZoneWarning = !gameWorld._brManager.isInsideZone(
      gameWorld.playerCritter.position.x,
      gameWorld.playerCritter.position.y,
    );

    // Update AI zone awareness
    for (final ai in gameWorld.aiCritters) {
      final controller = ai.children.whereType<AIController>().firstOrNull;
      controller?.updateZone(
        Vector2.zero(),
        brState.currentZoneRadius,
      );
    }
  }

  void _handleGameEvent(VanCoGameEvent event, [dynamic data]) {
    switch (event) {
      case VanCoGameEvent.playerAte:
        if (data is Critter) {
          _addKillFeed(playerFaction.emoji, data.faction.emoji, isPlayerKill: true);
        }
        break;
      case VanCoGameEvent.aiDied:
        if (data is Critter) {
          // Find killer (simplified - assume largest nearby)
          _addKillFeed('?', data.faction.emoji);
        }
        break;
      case VanCoGameEvent.zoneShrinking:
        showZoneWarning = true;
        zoneRenderer.showWarning();
        break;
      case VanCoGameEvent.lightningWarning:
        // Lightning renderer handles this automatically
        break;
      default:
        break;
    }
  }

  void _addKillFeed(String killer, String victim, {bool isPlayerKill = false}) {
    killFeed.insert(0, KillFeedEntry(
      killerEmoji: killer,
      victimEmoji: victim,
      isPlayerKill: isPlayerKill,
    ));

    // Limit feed size
    if (killFeed.length > 10) {
      killFeed.removeLast();
    }
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    // Convert screen position to world position
    final worldPos = camera.globalToLocal(info.eventPosition.global);
    gameWorld.onMouseMove(worldPos);
  }

  @override
  void onTapDown(TapDownInfo info) {
    // Mobile touch support
    final worldPos = camera.globalToLocal(info.eventPosition.global);
    gameWorld.onMouseMove(worldPos);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Escape to pause
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (!_isPaused) {
        onPause();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void pauseGame() {
    _isPaused = true;
    pauseEngine();
  }

  void resumeGame() {
    _isPaused = false;
    resumeEngine();
  }

  // === HUD OVERLAY ===
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Game
        super.build(context),

        // HUD Overlay
        if (!_isGameOver)
          Positioned.fill(
            child: IgnorePointer(
              child: BattleRoyaleHud(
                playerCritter: gameWorld.playerCritter.critter,
                gameState: gameWorld.brState,
                killFeed: killFeed,
                showZoneWarning: showZoneWarning,
                onPause: onPause,
              ),
            ),
          ),
      ],
    );
  }
}

/// Extension to access private members (for HUD)
extension VanCoWorldAccess on VanCoWorld {
  BattleRoyaleManager get _brManager => BattleRoyaleManager();
  LightningSystem get _lightningSystem => LightningSystem();
}
