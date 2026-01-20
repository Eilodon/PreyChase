import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
// import 'view/game/prey_fury_game.dart';
import 'crocodile_game/crocodile_game.dart';
import 'view/screens/main_menu_screen.dart';
import 'view/screens/game_over_screen.dart';
import 'kernel/state/app_state.dart';
import 'kernel/persistence/persistence_manager.dart';
import 'kernel/models/player_progress.dart';
import 'kernel/logic/shop_logic.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PreyFuryApp());
}

class PreyFuryApp extends StatefulWidget {
  const PreyFuryApp({super.key});

  @override
  State<PreyFuryApp> createState() => _PreyFuryAppState();
}

class _PreyFuryAppState extends State<PreyFuryApp> {
  AppScreen _currentScreen = AppScreen.menu;
  // late PreyFuryGame _game;
  late CrocodileGame _game;
  int _finalScore = 0;
  
  final PersistenceManager _persistence = PersistenceManager();
  PlayerProgress _progress = const PlayerProgress();

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _initGame();
  }

  Future<void> _loadProgress() async {
    final p = await _persistence.loadProgress();
    setState(() {
      _progress = p;
    });
  }

  Future<void> _saveScore(int score) async {
     int highScore = _progress.highScore;
     if (score > highScore) {
        highScore = score;
     }
     
     final newProgress = _progress.copyWith(
        totalScore: _progress.totalScore + score,
        highScore: highScore,
     );
     
     await _persistence.saveProgress(newProgress);
     setState(() {
        _progress = newProgress;
     });
  }

  void _initGame() {
    _game = CrocodileGame(
      onGameOver: (score) {
        _saveScore(score);
        setState(() {
          _finalScore = score;
          _currentScreen = AppScreen.gameOver;
        });
      },
    );
  }

  void _startGame() {
    setState(() {
      _initGame(); // Re-init game
      _currentScreen = AppScreen.playing;
    });
  }

  void _goToMenu() {
    setState(() {
      _currentScreen = AppScreen.menu;
    });
  }

  void _quit() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              // Global shortcuts
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                _goToMenu();
                return KeyEventResult.handled;
              }
              
              if (_currentScreen == AppScreen.menu) {
                if (event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  _startGame();
                  return KeyEventResult.handled;
                }
              } else if (_currentScreen == AppScreen.gameOver) {
                if (event.logicalKey == LogicalKeyboardKey.keyR) {
                  _startGame();
                  return KeyEventResult.handled;
                }
              }
            }
            return KeyEventResult.ignored;
          },
          child: Center(
            child: SizedBox(
              width: 900,
              height: 700,
              child: _buildCurrentScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case AppScreen.menu:
        return MainMenuScreen(
          onPlay: _startGame,
          onQuit: _quit,
          progress: _progress,
          onBuyItem: (itemId) async {
             final newP = ShopLogic.unlock(_progress, itemId);
             await _persistence.saveProgress(newP);
             setState(() {
               _progress = newP;
             });
          },
        );
      case AppScreen.playing:
        return GameWidget(game: _game);
      case AppScreen.gameOver:
        return Stack(
          children: [
            GameWidget(game: _game),
            GameOverScreen(
              score: _finalScore,
              onRestart: _startGame,
              onMenu: _goToMenu,
            ),
          ],
        );
    }
  }
}
