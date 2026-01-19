import 'package:flutter/material.dart';

class MainMenuScreen extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onQuit;

  const MainMenuScreen({
    super.key,
    required this.onPlay,
    required this.onQuit,
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
            const SizedBox(height: 80),
            
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
