import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tutorial manager for first-time player experience
/// Shows step-by-step instructions with visual overlays
///
/// Tutorial flow:
/// 1. Movement (WASD)
/// 2. Survival (avoid prey)
/// 3. Fury meter (eat prey to fill)
/// 4. Fury activation (Space)
/// 5. Power-up selection (first level-up)
///
/// Features:
/// - Step-by-step guidance
/// - Visual highlights
/// - Progress tracking
/// - Can be skipped
/// - Only shows once per install
class TutorialManager extends Component {
  // Tutorial state
  TutorialStep _currentStep = TutorialStep.none;
  bool _tutorialActive = false;
  bool _tutorialCompleted = false;
  double _stepTimer = 0.0;

  // Callbacks
  void Function(TutorialStep step)? onStepChanged;
  void Function()? onTutorialComplete;

  // Step completion tracking
  final Set<TutorialStep> _completedSteps = {};

  /// Initialize tutorial (check if needed)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _tutorialCompleted = prefs.getBool('tutorial_completed') ?? false;

    if (!_tutorialCompleted) {
      // Start tutorial after a brief delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!_tutorialCompleted) {
          startTutorial();
        }
      });
    }
  }

  /// Start tutorial from beginning
  void startTutorial() {
    _tutorialActive = true;
    _currentStep = TutorialStep.welcome;
    _stepTimer = 0.0;
    onStepChanged?.call(_currentStep);
  }

  /// Skip tutorial entirely
  Future<void> skipTutorial() async {
    _tutorialActive = false;
    _tutorialCompleted = true;
    _currentStep = TutorialStep.none;

    // Save skip state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);

    onTutorialComplete?.call();
  }

  /// Complete current step and advance
  void completeStep(TutorialStep step) {
    if (!_tutorialActive) return;
    if (_completedSteps.contains(step)) return;

    _completedSteps.add(step);

    // Advance to next step
    _advanceToNextStep();
  }

  /// Check if a specific step is completed
  bool isStepCompleted(TutorialStep step) {
    return _completedSteps.contains(step);
  }

  /// Advance to next tutorial step
  void _advanceToNextStep() {
    final nextStep = switch (_currentStep) {
      TutorialStep.none => TutorialStep.welcome,
      TutorialStep.welcome => TutorialStep.movement,
      TutorialStep.movement => TutorialStep.survival,
      TutorialStep.survival => TutorialStep.furyMeter,
      TutorialStep.furyMeter => TutorialStep.furyActivation,
      TutorialStep.furyActivation => TutorialStep.eatPrey,
      TutorialStep.eatPrey => TutorialStep.powerUp,
      TutorialStep.powerUp => TutorialStep.complete,
      TutorialStep.complete => TutorialStep.none,
    };

    _currentStep = nextStep;
    _stepTimer = 0.0;

    if (_currentStep == TutorialStep.complete) {
      _completeTutorial();
    } else {
      onStepChanged?.call(_currentStep);
    }
  }

  /// Mark tutorial as complete
  Future<void> _completeTutorial() async {
    _tutorialActive = false;
    _tutorialCompleted = true;

    // Save completion state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);

    onTutorialComplete?.call();
  }

  /// Force show tutorial again (for testing)
  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', false);
    _tutorialCompleted = false;
    _completedSteps.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_tutorialActive) return;

    _stepTimer += dt;

    // Auto-advance welcome screen after 5 seconds
    if (_currentStep == TutorialStep.welcome && _stepTimer >= 5.0) {
      completeStep(TutorialStep.welcome);
    }
  }

  // Getters
  bool get isActive => _tutorialActive;
  bool get isCompleted => _tutorialCompleted;
  TutorialStep get currentStep => _currentStep;
  double get stepTimer => _stepTimer;

  /// Get instruction text for current step
  String getInstructionText() {
    return switch (_currentStep) {
      TutorialStep.none => '',
      TutorialStep.welcome => 'Welcome to PREY FURY!\nYou are a crocodile being hunted by angry food.\nSurvive and turn the tables!',
      TutorialStep.movement => 'Use WASD or Arrow Keys to move\nTry moving around!',
      TutorialStep.survival => 'Avoid the angry prey!\nThey will damage you on contact.',
      TutorialStep.furyMeter => 'Fill your FURY meter by surviving.\nWatch the orange bar in top-right!',
      TutorialStep.furyActivation => 'Press SPACE when Fury is full!\nYou become invincible and can eat prey.',
      TutorialStep.eatPrey => 'Eat as many prey as you can during Fury!\nEach kill gives you points and extends Fury.',
      TutorialStep.powerUp => 'Choose a power-up to upgrade your crocodile!\nPress 1, 2, or 3 to select.',
      TutorialStep.complete => 'Tutorial complete!\nGood luck, crocodile! 🐊',
    };
  }

  /// Get short hint for current step
  String getHintText() {
    return switch (_currentStep) {
      TutorialStep.none => '',
      TutorialStep.welcome => 'Press any key to continue',
      TutorialStep.movement => 'WASD to move',
      TutorialStep.survival => 'Avoid prey (they glow red)',
      TutorialStep.furyMeter => 'Survive to fill Fury meter',
      TutorialStep.furyActivation => 'Press SPACE when ready',
      TutorialStep.eatPrey => 'Touch prey to eat them',
      TutorialStep.powerUp => 'Choose wisely!',
      TutorialStep.complete => 'Have fun!',
    };
  }

  /// Get visual highlight target (for arrow/circle)
  TutorialHighlight? getHighlight() {
    return switch (_currentStep) {
      TutorialStep.movement => TutorialHighlight.player,
      TutorialStep.survival => TutorialHighlight.prey,
      TutorialStep.furyMeter => TutorialHighlight.furyBar,
      TutorialStep.furyActivation => TutorialHighlight.furyBar,
      TutorialStep.eatPrey => TutorialHighlight.prey,
      TutorialStep.powerUp => TutorialHighlight.powerUpCards,
      _ => null,
    };
  }
}

/// Tutorial step enum
enum TutorialStep {
  none,
  welcome,
  movement,
  survival,
  furyMeter,
  furyActivation,
  eatPrey,
  powerUp,
  complete,
}

/// Visual highlight targets
enum TutorialHighlight {
  player,
  prey,
  furyBar,
  powerUpCards,
}
