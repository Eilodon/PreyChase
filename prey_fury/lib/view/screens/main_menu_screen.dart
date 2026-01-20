import 'package:flutter/material.dart';
import '../../kernel/models/player_progress.dart';
import '../../kernel/logic/shop_logic.dart';

class MainMenuScreen extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onQuit;
  final PlayerProgress progress;
  final Function(String) onBuyItem;

  const MainMenuScreen({
    super.key,
    required this.onPlay,
    required this.onQuit,
    this.progress = const PlayerProgress(),
    required this.onBuyItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              'PREY FURY',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 72,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Snake Escape',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 24,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            
            // Stats Panel
            Text(
               "HIGH SCORE: ${progress.highScore}",
               style: const TextStyle(color: Colors.yellowAccent, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
             Text(
               "POINTS: ${progress.totalScore}",
               style: const TextStyle(color: Colors.greenAccent, fontSize: 24),
            ),
            const SizedBox(height: 40),

            // Shop / Unlocks
            Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                  _ShopItem(
                     id: 'lightning', 
                     name: 'Lightning Fury', 
                     cost: ShopLogic.costLightning, 
                     isOwned: progress.unlockedFuryTypes.contains('lightning'),
                     canAfford: progress.totalScore >= ShopLogic.costLightning,
                     onBuy: () => onBuyItem('lightning'),
                  ),
                  const SizedBox(width: 20),
                  _ShopItem(
                     id: 'voidFury', 
                     name: 'Void Fury', 
                     cost: ShopLogic.costVoid, 
                     isOwned: progress.unlockedFuryTypes.contains('voidFury'),
                     canAfford: progress.totalScore >= ShopLogic.costVoid,
                     onBuy: () => onBuyItem('voidFury'),
                  ),
               ],
            ),
            const SizedBox(height: 40),
            
            // Play Button
            _MenuButton(
              text: 'PLAY',
              color: Colors.green,
              onPressed: onPlay,
            ),
            const SizedBox(height: 20),
            
            // How to Play
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    'HOW TO PLAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '↑ ↓ ← → : Move Snake\n'
                    'Eat Food (Red Circles) to fill Fury Meter\n'
                    'Fury Mode: Eat Prey (Enemies)\n'
                    'Normal Mode: Avoid Prey!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Quit Button
            _MenuButton(
              text: 'QUIT',
              color: Colors.red,
              onPressed: onQuit,
            ),
            const SizedBox(height: 20),
            const Text(
              'Press SPACE to Play',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
        textStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      child: Text(text),
    );
  }
}

class _ShopItem extends StatelessWidget {
   final String id;
   final String name;
   final int cost;
   final bool isOwned;
   final bool canAfford;
   final VoidCallback onBuy;

   const _ShopItem({
      required this.id, required this.name, required this.cost, 
      required this.isOwned, required this.canAfford, required this.onBuy
   });

   @override
   Widget build(BuildContext context) {
      Color color = Colors.grey;
      String label = "LOCKED";
      
      if (isOwned) {
         color = Colors.green;
         label = "OWNED";
      } else if (canAfford) {
         color = Colors.orange;
         label = "$cost PTS";
      } else {
         color = Colors.red.shade900;
         label = "$cost PTS";
      }

      return Column(
         children: [
            Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                  border: Border.all(color: color, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: color.withOpacity(0.2),
               ),
               child: Column(
                  children: [
                     Icon(Icons.flash_on, color: color, size: 32),
                     const SizedBox(height: 4),
                     Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  ],
               ),
            ),
            const SizedBox(height: 8),
            isOwned 
            ? const Icon(Icons.check, color: Colors.green)
            : ElevatedButton(
               onPressed: canAfford ? onBuy : null,
               style: ElevatedButton.styleFrom(backgroundColor: color),
               child: Text(label),
            )
         ],
      );
   }
}
