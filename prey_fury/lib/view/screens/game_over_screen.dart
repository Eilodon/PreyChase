import 'package:flutter/material.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.onRestart,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x88FF0000),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'SCORE: $score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 60),
            
            // Restart Button
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('RESTART'),
            ),
            const SizedBox(height: 20),
            
            // Menu Button
            ElevatedButton(
              onPressed: onMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('MAIN MENU'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Press R to Restart | ESC for Menu',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
