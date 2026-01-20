import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'crocodile_game/crocodile_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    GameWidget(
      game: CrocodileGame(),
    ),
  );
}
