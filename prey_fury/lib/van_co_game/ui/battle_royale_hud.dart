/// Battle Royale HUD - Game UI overlay
///
/// Displays:
/// - Player stats (health, size, mutations)
/// - Game info (time, alive count, phase)
/// - Kill feed
/// - Zone warning
/// - Minimap

import 'package:flutter/material.dart';

import '../../kernel/models/critter.dart';
import '../../kernel/models/ngu_hanh_faction.dart';
import '../../kernel/models/van_co_mutation.dart';
import '../../kernel/systems/battle_royale_manager.dart';
import '../../kernel/systems/size_manager.dart';

/// Battle Royale HUD Widget
class BattleRoyaleHud extends StatelessWidget {
  final Critter playerCritter;
  final BRGameState gameState;
  final List<KillFeedEntry> killFeed;
  final bool showZoneWarning;
  final VoidCallback? onPause;

  const BattleRoyaleHud({
    super.key,
    required this.playerCritter,
    required this.gameState,
    this.killFeed = const [],
    this.showZoneWarning = false,
    this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top Bar (Time, Alive, Phase)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(),
        ),

        // Player Stats (Left side)
        Positioned(
          left: 16,
          bottom: 16,
          child: _buildPlayerStats(),
        ),

        // Minimap (Right side)
        Positioned(
          right: 16,
          bottom: 16,
          child: _buildMinimap(),
        ),

        // Kill Feed (Top right)
        Positioned(
          top: 60,
          right: 16,
          child: _buildKillFeed(),
        ),

        // Zone Warning (Center)
        if (showZoneWarning)
          Center(child: _buildZoneWarning()),

        // Pause Button (Top right)
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.pause, color: Colors.white54),
            onPressed: onPause,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Alive Count
            _buildInfoBox(
              icon: Icons.person,
              value: '${gameState.aliveCount}',
              label: 'ALIVE',
              color: Colors.green,
            ),

            // Center: Time and Phase
            Column(
              children: [
                // Game Time
                Text(
                  gameState.formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),

                // Phase
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPhaseColor().withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getPhaseColor()),
                  ),
                  child: Text(
                    gameState.currentPhase.nameVi,
                    style: TextStyle(
                      color: _getPhaseColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Kills
            _buildInfoBox(
              icon: Icons.dangerous,
              value: '${playerCritter.kills}',
              label: 'KILLS',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPhaseColor() {
    switch (gameState.currentPhase) {
      case BRPhase.spawn:
      case BRPhase.earlyGame:
        return Colors.green;
      case BRPhase.midGame:
        return Colors.yellow;
      case BRPhase.lateGame:
        return Colors.orange;
      case BRPhase.suddenDeath:
        return Colors.red;
      case BRPhase.overtime:
        return Colors.purple;
    }
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStats() {
    final factionData = NguHanhRegistry.get(playerCritter.faction);
    final healthPercent = playerCritter.health / playerCritter.effectiveMaxHealth;
    final sizePercent = playerCritter.sizePercent;
    final tier = playerCritter.tier;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: factionData.primaryColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Faction and Tier
          Row(
            children: [
              Text(factionData.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      factionData.nameVi,
                      style: TextStyle(
                        color: factionData.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tier.name,
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

          const SizedBox(height: 12),

          // Health Bar
          _buildStatBar(
            label: 'HP',
            value: playerCritter.health.toInt(),
            maxValue: playerCritter.effectiveMaxHealth.toInt(),
            percent: healthPercent,
            color: _getHealthColor(healthPercent),
            icon: '❤️',
          ),

          const SizedBox(height: 8),

          // Size Bar
          _buildStatBar(
            label: 'SIZE',
            value: (sizePercent * 100).toInt(),
            maxValue: 100,
            percent: sizePercent,
            color: Colors.cyan,
            icon: '📏',
            suffix: '%',
          ),

          const SizedBox(height: 12),

          // Mutations
          if (playerCritter.mutations.isNotEmpty) ...[
            const Text(
              'MUTATIONS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: playerCritter.mutations.take(6).map((m) {
                return _buildMutationIcon(m);
              }).toList(),
            ),
          ],

          const SizedBox(height: 8),

          // Controls hint
          Text(
            'SPACE: Split | W: Eject',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar({
    required String label,
    required int value,
    required int maxValue,
    required double percent,
    required Color color,
    required String icon,
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$icon $label',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            Text(
              '$value/$maxValue$suffix',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getHealthColor(double percent) {
    if (percent > 0.6) return Colors.green;
    if (percent > 0.3) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMutationIcon(dynamic mutation) {
    // Get mutation data
    // For now, show placeholder
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.purple.withOpacity(0.5)),
      ),
      child: const Center(
        child: Text('✨', style: TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildMinimap() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: MinimapPainter(
            playerPosition: Vector2(playerCritter.x, playerCritter.y),
            zoneRadius: gameState.currentZoneRadius,
            maxRadius: BattleRoyaleManager.mapRadius,
            phaseColor: _getPhaseColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildKillFeed() {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: killFeed.take(5).map((entry) {
          return _buildKillFeedEntry(entry);
        }).toList(),
      ),
    );
  }

  Widget _buildKillFeedEntry(KillFeedEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.killerEmoji,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            entry.isPlayerKill ? ' YOU ' : ' 🔪 ',
            style: TextStyle(
              color: entry.isPlayerKill ? Colors.yellow : Colors.white54,
              fontSize: 12,
            ),
          ),
          Text(
            entry.victimEmoji,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ĐỘC KHÍ ĐANG TỚI!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Di chuyển vào vùng an toàn',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kill feed entry data
class KillFeedEntry {
  final String killerEmoji;
  final String victimEmoji;
  final bool isPlayerKill;
  final DateTime timestamp;

  KillFeedEntry({
    required this.killerEmoji,
    required this.victimEmoji,
    this.isPlayerKill = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Minimap painter
class MinimapPainter extends CustomPainter {
  final Vector2 playerPosition;
  final double zoneRadius;
  final double maxRadius;
  final Color phaseColor;

  MinimapPainter({
    required this.playerPosition,
    required this.zoneRadius,
    required this.maxRadius,
    required this.phaseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 2 / maxRadius;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Zone circle
    final zoneRadiusScaled = zoneRadius * scale;
    canvas.drawCircle(
      center,
      zoneRadiusScaled,
      Paint()
        ..color = phaseColor.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      zoneRadiusScaled,
      Paint()
        ..color = phaseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Player dot
    final playerOffset = Offset(
      center.dx + playerPosition.x * scale,
      center.dy + playerPosition.y * scale,
    );
    canvas.drawCircle(
      playerOffset,
      4,
      Paint()..color = Colors.cyan,
    );

    // Player direction indicator
    canvas.drawCircle(
      playerOffset,
      6,
      Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) {
    return playerPosition != oldDelegate.playerPosition ||
           zoneRadius != oldDelegate.zoneRadius;
  }
}

/// Simple Vector2 for position
class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is Vector2 && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}
