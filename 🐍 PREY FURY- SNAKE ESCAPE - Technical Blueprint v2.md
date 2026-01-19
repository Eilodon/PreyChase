# **🐍 PREY FURY: SNAKE ESCAPE \- Technical Blueprint v2.0**

## **📋 Tổng quan dự án**

**Game**: Prey Fury: Snake Escape (Mồi Điên: Rắn Chạy)  
 **Genre**: Hybrid-Casual, Reverse Snake, Survival  
 **Platform**: Android Native \+ Web (iOS ready)  
 **Tech Stack**: Flutter 3.24+ \+ Flame 1.18+  
 **Target**: 60 FPS, \<25MB APK, \<5MB web build  
 **Timeline**: 8-10 tuần MVP  
 **Unique Hook**: Player điều khiển rắn bị "angry food monsters" đuổi, phải dụ chúng vào miệng để ăn ngược lại \+ Fury Mode comeback mechanic

---

## **🎮 Core Concept & Market Fit**

### **Why This Game Will Win 2026**

**Market Gap Identified:**

* Snake/.io genre: 10M+ monthly installs (Worms Zone, Snake.io top charts Q3 2025\)  
* Reverse snake games: Niche, thiếu empowerment feeling  
* **Our twist**: Rắn bị đuổi NHƯNG có thể counter-attack \+ Fury comeback → chưa có game nào làm

**Success Formula:**

Tense Survival (chạy trốn)   
\+ Strategic Baiting (dụ ăn ngược)  
\+ Fury Mode (comeback satisfying)  
\+ Cute Angry Food (viral meme)  
\+ Hybrid Meta (retention 2-3x)  
\= Top Hypercasual 2026

**Reference Games:**

* Worms Zone .io: Cute visuals, retention D7 \~18%  
* Snake Clash: Battle royale tension  
* Archero: Power-up progression feel  
* **Our advantage**: Unique reverse mechanic chưa ai làm

---

## **🏗️ Architecture Overview**

┌─────────────────────────────────────────────────────────┐  
│                   PRESENTATION LAYER                    │  
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  │  
│  │  Game UI    │  │ Menu Screens │  │   HUD/Fury   │  │  
│  │  \+ Effects  │  │  \+ Shop      │  │   Meter      │  │  
│  └─────────────┘  └──────────────┘  └──────────────┘  │  
└─────────────────────────────────────────────────────────┘  
                            │  
┌─────────────────────────────────────────────────────────┐  
│                    GAME LOGIC LAYER                     │  
│  ┌──────────────────────────────────────────────────┐  │  
│  │           FlameGame (Core Game Loop)             │  │  
│  ├──────────────────────────────────────────────────┤  │  
│  │  • Snake System      • Prey AI System            │  │  
│  │  • Fury System 🔥    • PowerUp System            │  │  
│  │  • Collision System  • Combo/Score System        │  │  
│  │  • Spawn Manager     • Level Manager             │  │  
│  │  • Collection System • Daily Challenge System    │  │  
│  └──────────────────────────────────────────────────┘  │  
└─────────────────────────────────────────────────────────┘  
                            │  
┌─────────────────────────────────────────────────────────┐  
│                   DATA/STATE LAYER                      │  
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  │  
│  │  Riverpod   │  │ Shared Pref  │  │  Collection  │  │  
│  │  Providers  │  │  \+ Hive DB   │  │   Database   │  │  
│  └─────────────┘  └──────────────┘  └──────────────┘  │  
└─────────────────────────────────────────────────────────┘  
                            │  
┌─────────────────────────────────────────────────────────┐  
│                SERVICES & INTEGRATIONS                  │  
│  • Audio Service  • Analytics (Firebase)               │  
│  • Ads (AdMob)    • Leaderboard (local → cloud)        │  
│  • IAP Service    • Notification (daily rewards)       │  
└─────────────────────────────────────────────────────────┘

---

## **🎨 Visual Theme: Angry Food Monsters**

### **Art Direction**

**Style**: Cute meets creepy, vibrant neon colors, exaggerated expressions

**Characters:**

* **Snake (Player)**: Baby rắn dễ thương, rainbow trail, big eyes  
* **Prey (Enemies)**: Thức ăn quái vật với mặt giận dữ:  
  * 😠🍎 **Angry Apple** (Dumb AI, basic)  
  * 🧟🍔 **Zombie Burger** (Tank, slow but high damage)  
  * 🥷🍣 **Ninja Sushi** (Fast, smart pathfinding)  
  * 👻🍕 **Ghost Pizza** (Phasing, đi xuyên tường ngắn)  
  * ✨🍰 **Golden Cake** (Rare, huge bonus)

**Visuals Inspiration:**

* Worms Zone: Cute worms, satisfying particle effects  
* Among Us: Simple shapes, expressive faces  
* Neon aesthetic: Glow trails, vibrant backgrounds

**Example Mood:**

Map: Dark background với neon grid lines  
Snake: Rainbow gradient body \+ glow aura (Fury Mode: red/orange fire)  
Prey: Cute food với angry eyes, khi đuổi có "\!\!\!" effect  
Effects: Explosion particles khi ăn, screen shake khi va

---

## **🎮 Core Game Systems (Updated)**

### **1\. Snake System (`SnakeComponent`)**

**Responsibility**: Quản lý rắn player với Fury mechanics

class SnakeComponent extends PositionComponent   
    with HasGameRef, CollisionCallbacks {  
  // Core attributes  
  List\<Vector2\> segments;  
  Direction currentDirection;  
  double baseSpeed \= 8.0;           // tiles/second  
  double currentSpeed;              // Modified by Fury  
  int currentLength;  
  int maxLength \= 100;  
    
  // Fury Mode attributes 🔥  
  bool isFuryActive \= false;  
  double furyTimer \= 0.0;  
  double furyDuration \= 8.0;  
  double magnetRange \= 0.0;         // 0 when not Fury, 100 when active  
    
  // Visual states  
  Color baseColor \= Colors.green;  
  Color furyColor \= Colors.orange;  
  ParticleEffect trailEffect;  
  GlowEffect currentGlow;  
    
  @override  
  void update(double dt) {  
    super.update(dt);  
      
    // Movement  
    if (\!isPaused) {  
      moveSnake(dt);  
    }  
      
    // Fury timer  
    if (isFuryActive) {  
      furyTimer \-= dt;  
      if (furyTimer \<= 0\) {  
        deactivateFury();  
      }  
    }  
      
    // Magnet pull (when Fury)  
    if (isFuryActive && magnetRange \> 0\) {  
      pullNearbyPrey();  
    }  
  }  
    
  void move() {  
    // Grid-based movement with smooth interpolation  
  }  
    
  void grow(int amount) {  
    currentLength \+= amount;  
    playGrowAnimation();  
  }  
    
  void shrink(int amount) {  
    currentLength \= max(3, currentLength \- amount);  
    playHurtAnimation();  
  }  
    
  void activateFury() {  
    isFuryActive \= true;  
    furyTimer \= furyDuration;  
    currentSpeed \= baseSpeed \* 1.5;    // \+50% speed  
    magnetRange \= 100.0;  
      
    // Visual feedback  
    addGlowEffect(furyColor);  
    spawnFuryParticles();  
    playFurySound();  
    gameRef.slowMotion(0.7, 1.0);      // Slow-mo entry  
  }  
    
  void deactivateFury() {  
    isFuryActive \= false;  
    currentSpeed \= baseSpeed;  
    magnetRange \= 0;  
    removeGlowEffect();  
  }  
    
  void pullNearbyPrey() {  
    // Pull prey within magnetRange toward mouth  
    final nearbyPrey \= gameRef.preyInRange(headPosition, magnetRange);  
    for (var prey in nearbyPrey) {  
      final direction \= (headPosition \- prey.position).normalized();  
      prey.applyPull(direction \* 50); // Pull force  
    }  
  }  
}

---

### **2\. Fury System (`FuryModeSystem`) 🔥**

**Responsibility**: Quản lý combo và kích hoạt Fury Mode

class FuryModeSystem extends Component with HasGameRef {  
  int currentCombo \= 0;  
  int comboThreshold \= 5;           // 5 prey liên tiếp  
  double comboTimer \= 0.0;  
  double comboTimeout \= 3.0;        // Reset sau 3s không ăn  
    
  // UI feedback  
  ComboDisplayComponent comboDisplay;  
  FuryMeterComponent furyMeter;  
    
  @override  
  void update(double dt) {  
    super.update(dt);  
      
    // Combo timeout  
    if (currentCombo \> 0\) {  
      comboTimer \+= dt;  
      if (comboTimer \>= comboTimeout) {  
        resetCombo();  
      }  
    }  
      
    // Update UI  
    furyMeter.progress \= currentCombo / comboThreshold;  
  }  
    
  void onPreyEaten(PreyComponent prey) {  
    currentCombo++;  
    comboTimer \= 0.0;  
      
    // Visual feedback  
    comboDisplay.showCombo(currentCombo);  
    playComboSound(currentCombo);  
      
    // Trigger Fury  
    if (currentCombo \>= comboThreshold && \!snake.isFuryActive) {  
      triggerFury();  
    }  
      
    // Extend Fury if already active  
    if (snake.isFuryActive) {  
      snake.furyTimer \= min(snake.furyTimer \+ 1.0, snake.furyDuration);  
    }  
  }  
    
  void onSnakeHit() {  
    resetCombo();  
    comboDisplay.showBreak();  
    playComboBreakSound();  
  }  
    
  void triggerFury() {  
    snake.activateFury();  
    showFuryActivationUI();  
    spawnScreenEffect("FURY MODE\!");  
      
    // Haptic feedback  
    HapticFeedback.heavyImpact();  
  }  
    
  void resetCombo() {  
    currentCombo \= 0;  
    comboTimer \= 0.0;  
  }  
}

**UI Components:**

// Combo display (top center)  
class ComboDisplayComponent extends TextComponent {  
  void showCombo(int combo) {  
    text \= 'x$combo COMBO\!';  
    scale \= Vector2.all(1.5); // Pop animation  
    Tween scale back to 1.0  
  }  
}

// Fury meter (circular, around snake head or bottom bar)  
class FuryMeterComponent extends Component {  
  double progress \= 0.0; // 0.0 to 1.0  
    
  @override  
  void render(Canvas canvas) {  
    // Draw circular progress bar  
    // Fill color: yellow → orange → red as progress increases  
  }  
}

---

### **3\. Prey AI System (Angry Food Monsters)**

**5 Prey Types với personalities riêng biệt:**

enum PreyType {  
  angryApple,    // 😠🍎 Basic, dumb chase  
  zombieBurger,  // 🧟🍔 Tank, slow, high damage  
  ninjaSushi,    // 🥷🍣 Fast, smart A\*  
  ghostPizza,    // 👻🍕 Phase through walls  
  goldenCake,    // ✨🍰 Rare, huge reward  
}

class PreyComponent extends SpriteAnimationComponent   
    with CollisionCallbacks {  
  PreyType type;  
  PreyStats stats;  
  PreyAI ai;  
  PreyState state \= PreyState.idle;  
    
  // Attributes  
  double speed;  
  int damageAmount;      // Segments snake loses  
  int growthReward;      // Segments snake gains  
  double detectionRange; // Range to start chasing  
    
  // Visuals  
  Expression currentExpression \= Expression.angry;  
  ParticleEffect chaseEffect;  
    
  @override  
  void update(double dt) {  
    super.update(dt);  
      
    final snake \= gameRef.snake;  
    final distance \= (snake.headPosition \- position).length;  
      
    // State machine  
    switch (state) {  
      case PreyState.idle:  
        if (distance \< detectionRange) {  
          state \= PreyState.chasing;  
          playAngryAnimation();  
          showExclamationMark();  
        }  
        break;  
          
      case PreyState.chasing:  
        final direction \= ai.calculateNextMove(position, snake.headPosition);  
        moveToward(direction, speed \* dt);  
          
        // Visual feedback when close  
        if (distance \< 50\) {  
          playIntenseAnimation();  
          spawnChaseParticles();  
        }  
        break;  
          
      case PreyState.eaten:  
        playDeathAnimation();  
        spawnExplosionParticles();  
        removeFromParent();  
        break;  
          
      case PreyState.victorious:  
        // When hitting snake body  
        playEvilLaughAnimation();  
        grow(2); // Prey gets bigger  
        state \= PreyState.chasing;  
        break;  
    }  
  }  
    
  void onHitSnakeBody(SnakeComponent snake) {  
    snake.shrink(damageAmount);  
    state \= PreyState.victorious;  
      
    // Juice effects  
    gameRef.screenShake(intensity: 0.3, duration: 0.2);  
    gameRef.slowMotion(0.5, 0.3);  
    spawnHitEffect();  
  }  
    
  void onEatenBySnake(SnakeComponent snake) {  
    snake.grow(growthReward);  
    state \= PreyState.eaten;  
      
    // Juice effects  
    gameRef.spawnSatisfyingExplosion(position, type.color);  
    gameRef.playEatSound(type);  
    gameRef.addScore(calculateScore());  
  }  
}

**Prey Stats Table:**

class PreyStats {  
  static const Map\<PreyType, PreyStats\> stats \= {  
    PreyType.angryApple: PreyStats(  
      speed: 6.0,  
      damage: 1,  
      reward: 1,  
      detectionRange: 200,  
      spawnWeight: 50, // Most common  
    ),  
    PreyType.zombieBurger: PreyStats(  
      speed: 4.0,  
      damage: 3,  
      reward: 2,  
      detectionRange: 250,  
      spawnWeight: 25,  
    ),  
    PreyType.ninjaSushi: PreyStats(  
      speed: 10.0,  
      damage: 1,  
      reward: 2,  
      detectionRange: 300,  
      spawnWeight: 15,  
    ),  
    PreyType.ghostPizza: PreyStats(  
      speed: 7.0,  
      damage: 2,  
      reward: 3,  
      detectionRange: 150,  
      spawnWeight: 8,  
      canPhase: true,  
    ),  
    PreyType.goldenCake: PreyStats(  
      speed: 8.0,  
      damage: 1,  
      reward: 5,  
      detectionRange: 400,  
      spawnWeight: 2, // Very rare  
    ),  
  };  
}

**AI Implementations:**

// Dumb AI: Straight line chase  
class DumbAI extends PreyAI {  
  @override  
  Vector2 calculateNextMove(Vector2 current, Vector2 target) {  
    return (target \- current).normalized();  
  }  
}

// Smart AI: A\* pathfinding, avoid walls  
class SmartAI extends PreyAI {  
  List\<Vector2\> currentPath \= \[\];  
  double recalculateInterval \= 0.5;  
  double timeSinceRecalc \= 0.0;  
    
  @override  
  Vector2 calculateNextMove(Vector2 current, Vector2 target) {  
    timeSinceRecalc \+= dt;  
      
    if (timeSinceRecalc \>= recalculateInterval || currentPath.isEmpty) {  
      currentPath \= findPath(current, target); // A\* algorithm  
      timeSinceRecalc \= 0.0;  
    }  
      
    if (currentPath.isNotEmpty) {  
      return (currentPath.first \- current).normalized();  
    }  
    return Vector2.zero();  
  }  
    
  List\<Vector2\> findPath(Vector2 start, Vector2 end) {  
    // A\* implementation with wall avoidance  
    // Return list of waypoints  
  }  
}

// Phase AI: Can move through walls briefly  
class PhaseAI extends SmartAI {  
  bool isPhasing \= false;  
  double phaseDuration \= 1.0;  
  double phaseTimer \= 0.0;  
  double phaseCooldown \= 5.0;  
  double cooldownTimer \= 0.0;  
    
  @override  
  Vector2 calculateNextMove(Vector2 current, Vector2 target) {  
    // Use phase when blocked by wall  
    if (isBlocked() && \!isPhasing && cooldownTimer \<= 0\) {  
      activatePhase();  
    }  
      
    return super.calculateNextMove(current, target);  
  }  
    
  void activatePhase() {  
    isPhasing \= true;  
    phaseTimer \= phaseDuration;  
    prey.playPhaseAnimation(); // Ghost effect  
    prey.collisionType \= CollisionType.none; // Ignore walls  
  }  
}

---

### **4\. Collision System (Enhanced)**

class CollisionManager extends Component {  
    
  void checkCollisions() {  
    checkPreyVsSnakeHead();  
    checkPreyVsSnakeBody();  
    checkSnakeVsWalls();  
    checkSnakeVsPowerUps();  
  }  
    
  void checkPreyVsSnakeHead(PreyComponent prey, SnakeComponent snake) {  
    if (prey.hitbox.overlaps(snake.headHitbox)) {  
      // Snake eats prey \- SATISFYING moment  
        
      // Score & combo  
      gameRef.furySystem.onPreyEaten(prey);  
      gameRef.scoreSystem.addScore(prey.stats.points);  
        
      // Prey reacts  
      prey.onEatenBySnake(snake);  
        
      // Collection tracking  
      gameRef.collectionSystem.recordDefeat(prey.type);  
        
      // Juice effects  
      spawnCrunchParticles(prey.position, prey.type.color);  
      playRandomEatSound();  
        
      // Slow-mo if big prey or golden  
      if (prey.type \== PreyType.goldenCake) {  
        gameRef.slowMotion(0.6, 0.8);  
        showBonusText("+5 LENGTH\!", prey.position);  
      }  
    }  
  }  
    
  void checkPreyVsSnakeBody(PreyComponent prey, SnakeComponent snake) {  
    for (var segment in snake.bodySegments) {  
      if (prey.hitbox.overlaps(segment.hitbox)) {  
        // Prey hits snake body \- TENSE moment  
          
        prey.onHitSnakeBody(snake);  
        gameRef.furySystem.onSnakeHit();  
          
        // Visual punishment  
        gameRef.screenShake(0.4, 0.3);  
        spawnHitFlash(segment.position);  
          
        // Show damage number  
        showDamageText("-${prey.stats.damage}", segment.position);  
          
        // Check game over  
        if (snake.currentLength \<= 3\) {  
          gameRef.gameOver();  
        }  
          
        break;  
      }  
    }  
  }  
    
  void checkSnakeVsWalls(SnakeComponent snake) {  
    if (snake.headPosition.isOutsideBounds(gameRef.bounds)) {  
      // Option A: Bounce back  
      snake.bounceBack();  
        
      // Option B: Game over (harder difficulty)  
      // gameRef.gameOver();  
    }  
  }  
    
  void checkSnakeVsPowerUps(SnakeComponent snake) {  
    for (var powerUp in gameRef.activePowerUps) {  
      if (snake.headHitbox.overlaps(powerUp.hitbox)) {  
        powerUp.activate(snake);  
        playPowerUpSound();  
        spawnCollectEffect(powerUp.position);  
      }  
    }  
  }  
}

---

### **5\. Power-Up System (Expanded)**

enum PowerUpType {  
  speedBoost,    // \+50% speed 5s  
  magnetMouth,   // Auto-pull prey 100px range  
  freezePrey,    // Stop all prey 3s  
  shield,        // Invincible 1 hit  
  reverse,       // Prey run away 5s  
  doubleFury,    // Fury lasts 2x longer  
}

class PowerUpComponent extends SpriteAnimationComponent {  
  PowerUpType type;  
  double duration;  
  bool isActive \= false;  
  Timer effectTimer;  
    
  void activate(SnakeComponent snake) {  
    isActive \= true;  
      
    switch (type) {  
      case PowerUpType.speedBoost:  
        snake.currentSpeed \*= 1.5;  
        snake.addSpeedTrail();  
        break;  
          
      case PowerUpType.magnetMouth:  
        snake.magnetRange \= 120.0;  
        snake.addMagnetAura();  
        break;  
          
      case PowerUpType.freezePrey:  
        gameRef.freezeAllPrey(duration);  
        spawnFreezeWave(snake.position);  
        break;  
          
      case PowerUpType.shield:  
        snake.hasShield \= true;  
        snake.addShieldVisual();  
        break;  
          
      case PowerUpType.reverse:  
        gameRef.reverseAllPreyAI(duration);  
        break;  
          
      case PowerUpType.doubleFury:  
        if (snake.isFuryActive) {  
          snake.furyDuration \*= 2;  
        }  
        break;  
    }  
      
    // Start timer  
    effectTimer \= Timer(duration, onComplete: () \=\> deactivate(snake));  
    removeFromParent();  
  }  
    
  void deactivate(SnakeComponent snake) {  
    // Revert effects  
    isActive \= false;  
  }  
}

// Spawn system  
class PowerUpSpawnSystem extends Component {  
  double spawnInterval \= 15.0;   // Every 15 seconds  
  double spawnChance \= 0.3;      // 30% chance  
  Timer spawnTimer;  
    
  @override  
  void update(double dt) {  
    spawnTimer.update(dt);  
  }  
    
  void trySpawn() {  
    if (Random().nextDouble() \< spawnChance) {  
      final type \= \_weightedRandomType();  
      final position \= \_randomSafePosition();  
      gameRef.add(PowerUpComponent(type: type, position: position));  
    }  
  }  
    
  PowerUpType \_weightedRandomType() {  
    // More common power-ups have higher weight  
    final weights \= {  
      PowerUpType.speedBoost: 30,  
      PowerUpType.shield: 25,  
      PowerUpType.magnetMouth: 20,  
      PowerUpType.freezePrey: 15,  
      PowerUpType.reverse: 8,  
      PowerUpType.doubleFury: 2, // Rare  
    };  
    return weightedRandom(weights);  
  }  
}

---

### **6\. Collection System (Pokédex-style)**

**Responsibility**: Track defeated prey, unlock rewards

class CollectionSystem {  
  Map\<PreyType, PreyCollection\> collections \= {};  
    
  void recordDefeat(PreyType type) {  
    if (\!collections.containsKey(type)) {  
      collections\[type\] \= PreyCollection(type);  
    }  
      
    collections\[type\].defeatedCount++;  
      
    // Check milestones  
    checkMilestones(type);  
  }  
    
  void checkMilestones(PreyType type) {  
    final collection \= collections\[type\];  
      
    // Milestone rewards  
    if (collection.defeatedCount \== 10\) {  
      unlockSkin('${type.name}\_trail');  
      showUnlockPopup('New trail unlocked\!');  
    }  
      
    if (collection.defeatedCount \== 50\) {  
      unlockSkin('${type.name}\_snake\_skin');  
      showUnlockPopup('New snake skin unlocked\!');  
    }  
      
    if (collection.defeatedCount \== 100\) {  
      unlockTitle('${type.name}\_hunter');  
      showUnlockPopup('New title: ${type.name} Hunter\!');  
    }  
  }  
    
  double getCompletionPercentage() {  
    // Calculate % of all prey types collected  
    int totalDefeated \= 0;  
    int totalRequired \= PreyType.values.length \* 100; // 100 each  
      
    for (var collection in collections.values) {  
      totalDefeated \+= min(collection.defeatedCount, 100);  
    }  
      
    return totalDefeated / totalRequired;  
  }  
}

class PreyCollection {  
  PreyType type;  
  int defeatedCount \= 0;  
  DateTime firstDefeat;  
  List\<Achievement\> achievements \= \[\];  
    
  bool hasUnlockedSkin \= false;  
  bool hasUnlockedTitle \= false;  
}

**Collection UI Screen:**

class CollectionScreen extends StatelessWidget {  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      appBar: AppBar(title: Text('Prey Gallery')),  
      body: GridView.builder(  
        itemCount: PreyType.values.length,  
        itemBuilder: (context, index) {  
          final type \= PreyType.values\[index\];  
          final collection \= collectionSystem.collections\[type\];  
            
          return PreyCard(  
            type: type,  
            defeatedCount: collection?.defeatedCount ?? 0,  
            isUnlocked: collection \!= null,  
          );  
        },  
      ),  
    );  
  }  
}

// Individual prey card  
class PreyCard extends StatelessWidget {  
  Widget build(BuildContext context) {  
    return Card(  
      child: Column(  
        children: \[  
          // Prey image (grayscale if not unlocked)  
          Image.asset(  
            'assets/prey/${type.name}.png',  
            color: isUnlocked ? null : Colors.grey,  
          ),  
          // Name & count  
          Text('${type.displayName}'),  
          Text('Defeated: $defeatedCount'),  
          // Progress to next milestone  
          LinearProgressIndicator(value: defeatedCount / 50),  
        \],  
      ),  
    );  
  }  
}

---

### **7\. Daily Challenge System**

**Responsibility**: Daily missions for retention

class DailyChallengeSystem {  
  List\<DailyChallenge\> todaysChallenges \= \[\];  
  DateTime lastRefreshDate;  
    
  void init() {  
    if (shouldRefresh()) {  
      generateNewChallenges();  
    }  
  }  
    
  bool shouldRefresh() {  
    final now \= DateTime.now();  
    return lastRefreshDate \== null ||   
           lastRefreshDate\!.day \!= now.day;  
  }  
    
  void generateNewChallenges() {  
    todaysChallenges \= \[  
      // Easy challenge  
      DailyChallenge(  
        id: 'easy',  
        description: 'Survive for 2 minutes',  
        type: ChallengeType.survival,  
        target: 120, // seconds  
        reward: ChallengeReward(gems: 50),  
      ),  
        
      // Medium challenge  
      DailyChallenge(  
        id: 'medium',  
        description: 'Eat 10 Ninja Sushi',  
        type: ChallengeType.eatSpecific,  
        target: 10,  
        preyType: PreyType.ninjaSushi,  
        reward: ChallengeReward(gems: 100),  
      ),  
        
      // Hard challenge  
      DailyChallenge(  
        id: 'hard',  
        description: 'Activate Fury Mode 3 times in one run',  
        type: ChallengeType.furyCount,  
        target: 3,  
        reward: ChallengeReward(  
          gems: 200,  
          skin: 'fire\_trail',  
        ),  
      ),  
    \];  
      
    lastRefreshDate \= DateTime.now();  
    saveToStorage();  
  }  
    
  void checkProgress(DailyChallenge challenge, GameStats stats) {  
    switch (challenge.type) {  
      case ChallengeType.survival:  
        if (stats.survivalTime \>= challenge.target) {  
          completeChallenge(challenge);  
        }  
        break;  
          
      case ChallengeType.eatSpecific:  
        final count \= stats.preyEatenByType\[challenge.preyType\] ?? 0;  
        if (count \>= challenge.target) {  
          completeChallenge(challenge);  
        }  
        break;  
          
      case ChallengeType.furyCount:  
        if (stats.furyActivationCount \>= challenge.target) {  
          completeChallenge(challenge);  
        }  
        break;  
    }  
  }  
    
  void completeChallenge(DailyChallenge challenge) {  
    if (\!challenge.isCompleted) {  
      challenge.isCompleted \= true;  
      awardReward(challenge.reward);  
      showCompletionPopup(challenge);  
      saveToStorage();  
    }  
  }  
}

class DailyChallenge {  
  String id;  
  String description;  
  ChallengeType type;  
  int target;  
  int progress \= 0;  
  bool isCompleted \= false;  
  ChallengeReward reward;  
  PreyType? preyType; // For specific prey challenges  
}

enum ChallengeType {  
  survival,      // Survive X seconds  
  eatSpecific,   // Eat X of a prey type  
  furyCount,     // Activate Fury X times  
  comboStreak,   // Reach combo of X  
  noHit,         // Don't get hit for X seconds  
}

---

### **8\. Snake Evolution System (Light Meta)**

**Responsibility**: Permanent upgrades (không broken balance)

class SnakeEvolutionSystem {  
  int playerLevel \= 1;  
  int currentXP \= 0;  
  int xpToNextLevel \= 100;  
    
  // Available upgrades  
  Map\<UpgradeType, int\> upgradeLevels \= {  
    UpgradeType.startLength: 0,      // \+1 segment per level (max 3\)  
    UpgradeType.baseSpeed: 0,        // \+5% speed per level (max 3\)  
    UpgradeType.furyDuration: 0,     // \+1s Fury per level (max 3\)  
    UpgradeType.magnetRange: 0,      // \+20px range per level (max 3\)  
    UpgradeType.comboWindow: 0,      // \+0.5s combo timeout (max 3\)  
  };  
    
  void earnXP(int amount) {  
    currentXP \+= amount;  
      
    while (currentXP \>= xpToNextLevel) {  
      levelUp();  
    }  
  }  
    
  void levelUp() {  
    playerLevel++;  
    currentXP \-= xpToNextLevel;  
    xpToNextLevel \= (xpToNextLevel \* 1.2).round(); // Scaling  
      
    // Grant upgrade point  
    upgradePoints++;  
    showLevelUpPopup();  
  }  
    
  void purchaseUpgrade(UpgradeType type) {  
    if (upgradePoints \> 0 && upgradeLevels\[type\]\! \< 3\) {  
      upgradeLevels\[type\] \= upgradeLevels\[type\]\! \+ 1;  
      upgradePoints--;  
      applyUpgrade(type);  
      saveToStorage();  
    }  
  }  
    
  void applyUpgrade(UpgradeType type) {  
    switch (type) {  
      case UpgradeType.startLength:  
        GameConfig.snakeStartLength \+= 1;  
        break;  
      case UpgradeType.baseSpeed:  
        GameConfig.snakeSpeed \*= 1.05;  
        break;  
      case UpgradeType.furyDuration:  
        GameConfig.furyDuration \+= 1.0;  
        break;  
      // ... etc  
    }  
  }  
    
  Map\<String, dynamic\> getStats() {  
    return {  
      'level': playerLevel,  
      'xp': currentXP,  
      'startLength': GameConfig.snakeStartLength,  
      'speed': GameConfig.snakeSpeed,  
      // ...  
    };  
  }  
}

---

## **🎨 Juice & Effects System (Enhanced)**

### **Visual Feedback Library**

class JuiceEffectsLibrary {  
    
  // 1\. Screen effects  
  void screenShake(double intensity, double duration) {  
    gameRef.camera.shake(  
      intensity: intensity,  
      duration: duration,  
      frequency: 20,  
    );  
  }  
    
  void flashScreen(Color color, double duration) {  
    final overlay \= RectangleComponent(  
      size: gameRef.size,  
      paint: Paint()..color \= color.withOpacity(0.5),  
    );  
    gameRef.add(overlay);  
      
    overlay.add(  
      OpacityEffect.fadeOut(  
        EffectController(duration: duration),  
        onComplete: () \=\> overlay.removeFromParent(),  
      ),  
    );  
  }  
    
  void slowMotion(double timeScale, double duration) {  
    gameRef.timeScale \= timeScale;  
    Future.delayed(Duration(seconds: duration), () {  
      gameRef.timeScale \= 1.0;  
    });  
  }  
    
  // 2\. Particle effects  
  void spawnExplosion(Vector2 position, Color color, {int count \= 20}) {  
    final particles \= ParticleSystemComponent(  
      particle: Particle.generate(  
        count: count,  
        generator: (i) \=\> AcceleratedParticle(  
          acceleration: Vector2(0, 100), // Gravity  
          speed: Vector2.random() \* 200,  
          position: position,  
          child: CircleParticle(  
            radius: 3,  
            paint: Paint()..color \= color,  
          ),  
        ),  
        lifespan: 1.0,  
      ),  
    );  
    gameRef.add(particles);  
  }  
    
  void spawnCrunchParticles(Vector2 position, Color baseColor) {  
    // Mixed particles: circles \+ stars \+ text  
    final particles \= \<Particle\>\[\];  
      
    // Circles  
    for (int i \= 0; i \< 15; i++) {  
      particles.add(  
        MovingParticle(  
          from: position,  
          to: position \+ Vector2.random() \* 50,  
          child: CircleParticle(radius: 4, paint: Paint()..color \= baseColor),  
          lifespan: 0.5,  
        ),  
      );  
    }  
      
    // Star bursts  
    particles.add(  
      ScalingParticle(  
        lifespan: 0.3,  
        child: ImageParticle(image: starImage, size: Vector2.all(20)),  
      ),  
    );  
      
    gameRef.add(ParticleSystemComponent(particle: particles));  
  }  
    
  void spawnFuryActivationEffect(Vector2 position) {  
    // Circular shockwave  
    final shockwave \= CircleComponent(  
      radius: 10,  
      position: position,  
      paint: Paint()  
        ..color \= Colors.orange.withOpacity(0.8)  
        ..style \= PaintingStyle.stroke  
        ..strokeWidth \= 4,  
    );  
      
    shockwave.add(  
      ScaleEffect.to(  
        Vector2.all(10.0), // Scale to 10x size  
        EffectController(duration: 0.8),  
        onComplete: () \=\> shockwave.removeFromParent(),  
      ),  
    );  
      
    shockwave.add(  
      OpacityEffect.fadeOut(EffectController(duration: 0.8)),  
    );  
      
    gameRef.add(shockwave);  
      
    // Fire particles rising  
    spawnFireParticles(position, count: 30);  
  }  
    
  // 3\. Text popups  
  void showFloatingText(String text, Vector2 position, {Color color \= Colors.white}) {  
    final textComponent \= TextComponent(  
      text: text,  
      position: position,  
      textRenderer: TextPaint(  
        style: TextStyle(  
          color: color,  
          fontSize: 24,  
          fontWeight: FontWeight.bold,  
        ),  
      ),  
    );  
      
    textComponent.add(  
      MoveEffect.by(  
        Vector2(0, \-50),  
        EffectController(duration: 1.0),  
      ),  
    );  
      
    textComponent.add(  
      OpacityEffect.fadeOut(  
        EffectController(duration: 1.0),  
        onComplete: () \=\> textComponent.removeFromParent(),  
      ),  
    );  
      
    gameRef.add(textComponent);  
  }  
    
  // 4\. Animation helpers  
  void popAnimation(Component component) {  
    component.scale \= Vector2.all(1.5);  
    component.add(  
      ScaleEffect.to(  
        Vector2.all(1.0),  
        EffectController(  
          duration: 0.3,  
          curve: Curves.elasticOut,  
        ),  
      ),  
    );  
  }  
    
  void shakeComponent(Component component, double intensity) {  
    final originalPosition \= component.position.clone();  
      
    component.add(  
      SequenceEffect(\[  
        MoveEffect.by(Vector2(intensity, 0), EffectController(duration: 0.05)),  
        MoveEffect.by(Vector2(-intensity \* 2, 0), EffectController(duration: 0.05)),  
        MoveEffect.by(Vector2(intensity, 0), EffectController(duration: 0.05)),  
        MoveEffect.to(originalPosition, EffectController(duration: 0.05)),  
      \]),  
    );  
  }  
}

### **Sound System**

class AudioService {  
  late AudioPlayer musicPlayer;  
  late AudioPlayer sfxPlayer;  
    
  // Music tracks  
  void playMenuMusic() \=\> musicPlayer.play('bgm\_menu.mp3', loop: true);  
  void playGameMusic() \=\> musicPlayer.play('bgm\_game\_tense.mp3', loop: true);  
  void playFuryMusic() \=\> musicPlayer.play('bgm\_fury\_intense.mp3', loop: true);  
    
  // SFX with variations  
  void playEatSound(PreyType type) {  
    final sounds \= {  
      PreyType.angryApple: 'crunch\_apple.wav',  
      PreyType.zombieBurger: 'crunch\_burger.wav',  
      PreyType.ninjaSushi: 'crunch\_sushi.wav',  
      PreyType.ghostPizza: 'crunch\_pizza.wav',  
      PreyType.goldenCake: 'crunch\_golden.wav',  
    };  
    sfxPlayer.play(sounds\[type\]\!);  
  }  
    
  void playComboSound(int combo) {  
    // Pitch increases with combo  
    final pitch \= 1.0 \+ (combo \* 0.1);  
    sfxPlayer.play('combo.wav', pitch: pitch);  
  }  
    
  void playHitSound() \=\> sfxPlayer.play('hit\_hurt.wav');  
  void playFuryActivation() \=\> sfxPlayer.play('fury\_activate.wav');  
  void playPowerUpCollect() \=\> sfxPlayer.play('powerup\_collect.wav');  
    
  // Evil laugh when prey hits snake  
  void playEvilLaugh() {  
    final laughs \= \['evil\_laugh\_1.wav', 'evil\_laugh\_2.wav', 'evil\_laugh\_3.wav'\];  
    sfxPlayer.play(laughs\[Random().nextInt(3)\]);  
  }  
}

---

## **🗂️ Updated Project Structure**

prey\_fury/  
├── lib/  
│   ├── main.dart  
│   ├── game/  
│   │   ├── prey\_fury\_game.dart               \# Main FlameGame  
│   │   ├── components/  
│   │   │   ├── snake/  
│   │   │   │   ├── snake\_component.dart  
│   │   │   │   ├── snake\_segment.dart  
│   │   │   │   └── snake\_visuals.dart  
│   │   │   ├── prey/  
│   │   │   │   ├── prey\_component.dart  
│   │   │   │   ├── prey\_factory.dart  
│   │   │   │   └── prey\_animations.dart  
│   │   │   ├── powerups/  
│   │   │   │   ├── powerup\_component.dart  
│   │   │   │   └── powerup\_effects.dart  
│   │   │   └── ui/  
│   │   │       ├── hud\_component.dart  
│   │   │       ├── fury\_meter.dart  
│   │   │       ├── combo\_display.dart  
│   │   │       └── floating\_text.dart  
│   │   ├── systems/  
│   │   │   ├── fury\_system.dart               🔥 NEW  
│   │   │   ├── collision\_system.dart  
│   │   │   ├── spawn\_system.dart  
│   │   │   ├── score\_system.dart  
│   │   │   ├── collection\_system.dart         🔥 NEW  
│   │   │   ├── daily\_challenge\_system.dart    🔥 NEW  
│   │   │   └── evolution\_system.dart          🔥 NEW  
│   │   ├── ai/  
│   │   │   ├── prey\_ai.dart  
│   │   │   ├── dumb\_ai.dart  
│   │   │   ├── smart\_ai.dart  
│   │   │   └── phase\_ai.dart                  🔥 NEW  
│   │   ├── effects/  
│   │   │   ├── juice\_effects.dart  
│   │   │   ├── particle\_presets.dart  
│   │   │   └── screen\_effects.dart  
│   │   └── levels/  
│   │       ├── level\_config.dart  
│   │       ├── endless\_mode.dart  
│   │       └── campaign\_mode.dart  
│   ├── ui/  
│   │   ├── screens/  
│   │   │   ├── menu\_screen.dart  
│   │   │   ├── game\_screen.dart  
│   │   │   ├── game\_over\_screen.dart  
│   │   │   ├── collection\_screen.dart         🔥 NEW  
│   │   │   ├── daily\_challenge\_screen.dart    🔥 NEW  
│   │   │   ├── evolution\_screen.dart          🔥 NEW  
│   │   │   └── shop\_screen.dart  
│   │   └── widgets/  
│   │       ├── hud\_overlay.dart  
│   │       ├── pause\_menu.dart  
│   │       ├── settings\_dialog.dart  
│   │       └── unlock\_popup.dart  
│   ├── state/  
│   │   ├── game\_state.dart  
│   │   ├── player\_data.dart                   🔥 NEW  
│   │   └── providers.dart  
│   ├── services/  
│   │   ├── audio\_service.dart  
│   │   ├── storage\_service.dart  
│   │   ├── ads\_service.dart  
│   │   ├── analytics\_service.dart  
│   │   └── notification\_service.dart          🔥 NEW  
│   ├── models/  
│   │   ├── prey\_stats.dart  
│   │   ├── daily\_challenge.dart  
│   │   ├── collection\_data.dart  
│   │   └── player\_profile.dart  
│   └── utils/  
│       ├── constants.dart  
│       ├── extensions.dart  
│       └── helpers.dart  
├── assets/  
│   ├── images/  
│   │   ├── snake/  
│   │   │   ├── heads/  
│   │   │   ├── bodies/  
│   │   │   ├── trails/  
│   │   │   └── skins/  
│   │   ├── prey/  
│   │   │   ├── angry\_apple/  
│   │   │   ├── zombie\_burger/  
│   │   │   ├── ninja\_sushi/  
│   │   │   ├── ghost\_pizza/  
│   │   │   └── golden\_cake/  
│   │   ├── powerups/  
│   │   ├── ui/  
│   │   └── effects/  
│   ├── audio/  
│   │   ├── music/  
│   │   │   ├── bgm\_menu.mp3  
│   │   │   ├── bgm\_game\_tense.mp3  
│   │   │   └── bgm\_fury\_intense.mp3  
│   │   └── sfx/  
│   │       ├── crunch\_\*.wav  
│   │       ├── combo.wav  
│   │       ├── fury\_activate.wav  
│   │       └── evil\_laugh\_\*.wav  
│   └── fonts/  
│       └── game\_font.ttf  
├── test/  
└── pubspec.yaml

---

## **📦 Updated Dependencies**

name: prey\_fury  
description: Reverse snake game with Fury Mode

dependencies:  
  flutter:  
    sdk: flutter  
    
  \# Game Engine  
  flame: ^1.18.0  
  flame\_audio: ^2.1.0  
    
  \# State Management  
  flutter\_riverpod: ^2.5.0  
    
  \# Local Storage  
  shared\_preferences: ^2.2.0  
  hive: ^2.2.3                    \# 🔥 NEW: For collection/player data  
  hive\_flutter: ^1.1.0  
    
  \# Monetization  
  google\_mobile\_ads: ^5.0.0  
  in\_app\_purchase: ^3.1.0         \# 🔥 NEW: For IAP  
    
  \# Analytics & Notifications  
  firebase\_core: ^3.0.0  
  firebase\_analytics: ^11.0.0  
  firebase\_crashlytics: ^4.0.0  
  flutter\_local\_notifications: ^17.0.0  \# 🔥 NEW: Daily reminders  
    
  \# Utils  
  vector\_math: ^2.1.4  
  equatable: ^2.0.5  
  intl: ^0.19.0                   \# Date formatting

dev\_dependencies:  
  flutter\_test:  
    sdk: flutter  
  flame\_test: ^1.18.0  
  flutter\_lints: ^4.0.0  
  hive\_generator: ^2.0.0  
  build\_runner: ^2.4.0

---

## **🎯 Revised Development Timeline**

### **Phase 1: Core Mechanics (Week 1-2)**

**Goal**: Playable prototype với core loop

✅ **Snake System**

* Grid-based movement với smooth interpolation  
* Grow/shrink mechanics  
* Body collision detection

✅ **Basic Prey AI** (1-2 types)

* Angry Apple (dumb chase)  
* Zombie Burger (tank)

✅ **Collision Detection**

* Head vs prey (eat)  
* Body vs prey (damage)

✅ **Basic Scoring**

**Deliverable**: Test core loop \- "Có addictive không?"

---

### **Phase 2: Fury System 🔥 (Week 2-3)**

**Goal**: Implement game-changing mechanic

✅ **Fury Mode System**

* Combo tracking  
* Fury activation (speed boost \+ magnet)  
* Visual/audio feedback

✅ **Enhanced Prey** (all 5 types)

* Ninja Sushi (smart AI)  
* Ghost Pizza (phasing)  
* Golden Cake (rare spawn)

✅ **Improved Collision**

* Better hitboxes  
* Precise detection

**Deliverable**: "Fury Mode cảm giác wow chưa?"

---

### **Phase 3: Juice & Polish (Week 3-4)**

**Goal**: Make it feel AMAZING

✅ **Visual Effects**

* Particle explosions  
* Screen shake  
* Slow motion moments  
* Glow effects  
* Smooth animations

✅ **Audio System**

* Background music (menu, game, fury)  
* SFX variations  
* Evil laugh  
* Dynamic audio (pitch changes)

✅ **UI/UX**

* HUD with fury meter  
* Combo display  
* Floating damage numbers  
* Smooth transitions

**Deliverable**: "Wow factor" achieved

---

### **Phase 4: Content & Modes (Week 4-6)**

**Goal**: Variety to prevent boredom

✅ **Game Modes**

* Endless Survival  
* Campaign levels (20 levels MVP)  
* Tutorial level

✅ **Power-Ups**

* 4-5 power-up types  
* Spawn system  
* Visual effects

✅ **Difficulty Scaling**

* Progressive spawn rates  
* Smarter AI over time

**Deliverable**: 2+ hours of content

---

### **Phase 5: Meta Systems (Week 6-7)**

**Goal**: Retention features

✅ **Collection System**

* Prey gallery  
* Defeat tracking  
* Milestone rewards

✅ **Daily Challenges**

* 3 challenges per day  
* Auto-refresh  
* Reward system

✅ **Snake Evolution**

* XP system  
* 3-5 permanent upgrades  
* Skill tree UI

✅ **Skins & Customization**

* 5-10 snake skins  
* Trail effects  
* Unlock conditions

**Deliverable**: D7 retention \> 20% (internal test)

---

### **Phase 6: Monetization & Polish (Week 7-8)**

**Goal**: Prepare for release

✅ **Ads Integration**

* Rewarded video (revive, double coins)  
* Interstitial (after game over, optional)  
* Banner (menu only)

✅ **IAP Setup**

* Remove ads ($0.99)  
* Skin bundles ($2.99)  
* Gem packs

✅ **Analytics**

* Event tracking  
* Funnel analysis  
* Retention metrics

✅ **Bug Fixes & Optimization**

* Performance tuning  
* Memory leaks  
* Edge cases

**Deliverable**: Stable, monetizable build

---

### **Phase 7: Soft Launch (Week 8-9)**

**Goal**: Test with real users

✅ **Android Release**

* Internal testing  
* Closed beta (100 users)  
* Open beta

✅ **Web Deployment**

* Firebase Hosting / Netlify  
* Share link for testing

✅ **Gather Feedback**

* Retention data  
* Session length  
* Monetization rates

**Deliverable**: Data-driven insights

---

### **Phase 8: Full Launch (Week 9-10)**

**Goal**: Go live\!

✅ **Marketing**

* TikTok/Reels clips  
* Press kit  
* Influencer outreach (micro)

✅ **App Store Optimization**

* Screenshots  
* Description  
* Keywords

✅ **Launch**

* Google Play  
* Web live  
* Monitor & iterate

**Deliverable**: Published game 🚀

---

### **Post-Launch Roadmap (Optional)**

**Phase 9: Live Ops (Month 2-3)**

* Weekly events  
* Seasonal content (Tết skins)  
* New prey types  
* New power-ups

**Phase 10: Multiplayer (Month 3-4)**

* Local 2-player  
* Online Fury Arena (4-6 players)  
* Leaderboards

**Phase 11: Battle Pass (Month 4+)**

* Season 1 content  
* Premium rewards  
* Exclusive skins

---

## **🎨 UI/UX Design Specs**

### **Main Menu Screen**

┌─────────────────────────────────────┐  
│          PREY FURY 🔥               │  
│       (Animated logo)               │  
│                                     │  
│     \[▶️  PLAY\]                      │  
│     \[📚 COLLECTION\]                 │  
│     \[🎯 DAILY CHALLENGES\]           │  
│     \[🛒 SHOP\]                       │  
│     \[⚙️  SETTINGS\]                  │  
│                                     │  
│  Current Level: 12  Gems: 450      │  
└─────────────────────────────────────┘

### **In-Game HUD**

┌─────────────────────────────────────┐  
│ ❤️❤️❤️  \[Fury Meter: ████░░\]      │  Top bar  
│ Score: 1250  Combo: x5 🔥          │  
│                                     │  
│                                     │  
│        \[Game Area\]                 │    
│      🐍 ← Snake                    │  Main gameplay  
│      😠🍎 ← Prey chasing           │  
│                                     │  
│                                     │  
│ \[⏸️\]  Time: 2:45  High: 2800       │  Bottom bar  
└─────────────────────────────────────┘

### **Fury Activation Visual**

Screen effect:  
1\. Slow-mo (0.7x) for 1 second  
2\. Circular shockwave from snake  
3\. Screen flash orange  
4\. Text: "FURY MODE\!" (big, bold)  
5\. Fury meter glows red  
6\. Music intensifies  
7\. Camera slight zoom in

### **Collection Screen**

┌─────────────────────────────────────┐  
│      PREY GALLERY                   │  
│  \[Progress: 45% Complete\]           │  
│                                     │  
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │  
│  │ 😠🍎 │ │ 🧟🍔│ │ 🥷🍣│ │ 👻🍕│  │  
│  │ 127 │ │  45 │ │  89 │ │  12 │  │  
│  └─────┘ └─────┘ └─────┘ └─────┘  │  
│  Unlocked Unlocked Unlocked Locked │  
│                                     │  
│  Tap to view details & rewards     │  
└─────────────────────────────────────┘

### **Daily Challenges**

┌─────────────────────────────────────┐  
│      TODAY'S CHALLENGES             │  
│  \[Resets in: 12h 34m\]              │  
│                                     │  
│  ✅ Survive 2 minutes               │  
│      Reward: 50 gems               │  
│                                     │  
│  ▢ Eat 10 Ninja Sushi              │  
│     Progress: 6/10                 │  
│     Reward: 100 gems               │  
│                                     │  
│  ▢ Activate Fury 3 times           │  
│     Progress: 1/3                  │  
│     Reward: 200 gems \+ Fire Trail  │  
└─────────────────────────────────────┘

---

## **⚖️ Game Balance Configuration (Updated)**

// constants.dart  
class GameConfig {  
  // Snake  
  static double snakeSpeed \= 8.0;              // tiles/second  
  static int snakeStartLength \= 8;  
  static int snakeMaxLength \= 100;  
    
  // Fury Mode 🔥  
  static int furyComboThreshold \= 5;  
  static double furyDuration \= 8.0;            // seconds  
  static double furySpeedMultiplier \= 1.5;  
  static double furyMagnetRange \= 100.0;       // pixels  
  static double comboTimeout \= 3.0;  
    
  // Prey Spawning  
  static int initialPreyCount \= 2;  
  static double spawnInterval \= 5.0;  
  static int maxPreyCount \= 10;  
  static double difficultyScaling \= 0.1;       // \+10% per minute  
    
  // Power-ups  
  static double powerUpSpawnChance \= 0.25;  
  static double powerUpDuration \= 5.0;  
    
  // Scoring  
  static Map\<PreyType, int\> preyPoints \= {  
    PreyType.angryApple: 10,  
    PreyType.zombieBurger: 20,  
    PreyType.ninjaSushi: 30,  
    PreyType.ghostPizza: 40,  
    PreyType.goldenCake: 100,  
  };  
  static int comboMultiplierMax \= 10;  
    
  // Meta progression  
  static int xpPerPreyEaten \= 5;  
  static int xpPerSecondSurvived \= 1;  
    
  // Monetization  
  static int gemsPerRun \= 10;                  // Base gems  
  static int gemsPerAd \= 50;  
  static Map\<String, int\> iapGemPacks \= {  
    'small': 100,  
    'medium': 500,  
    'large': 1200,  
  };  
}

**Balance Philosophy:**

* **Early game**: 2-3 prey, easy to build combo → learn Fury  
* **Mid game** (1-2 min): 5-6 prey, need strategy  
* **Late game** (3+ min): 8-10 prey, chaos mode, Fury essential  
* **Golden Cake**: Rare (2% spawn), huge reward, test of skill

---

## **📊 Analytics & KPIs**

### **Metrics to Track**

**Engagement:**

* DAU, MAU, WAU  
* Session length (target: 5-10 min)  
* Sessions per day (target: 3+)  
* Retention D1, D7, D30 (target: 40%, 20%, 10%)

**Gameplay:**

* Average survival time  
* Fury activations per game  
* Most common prey type eaten  
* Power-up usage rate  
* Completion rate (levels)

**Monetization:**

* Ad impressions per session  
* Rewarded ad view rate (target: 60%+)  
* IAP conversion (target: 2-5%)  
* ARPDAU (target: $0.05-0.10)

**Retention Features:**

* Daily challenge completion rate  
* Collection completion %  
* Evolution upgrade purchase rate  
* Login streaks

### **Event Tracking**

class AnalyticsEvents {  
  // Lifecycle  
  static const gameStart \= 'game\_start';  
  static const gameOver \= 'game\_over';  
  static const levelComplete \= 'level\_complete';  
    
  // Core mechanics  
  static const preyEaten \= 'prey\_eaten';  
  static const furyActivated \= 'fury\_activated';  
  static const comboAchieved \= 'combo\_achieved';  
  static const powerUpCollected \= 'powerup\_collected';  
    
  // Meta  
  static const dailyChallengeCompleted \= 'daily\_challenge\_completed';  
  static const collectionMilestone \= 'collection\_milestone';  
  static const evolutionUpgrade \= 'evolution\_upgrade';  
  static const skinUnlocked \= 'skin\_unlocked';  
    
  // Monetization  
  static const adWatched \= 'ad\_watched';  
  static const iapPurchased \= 'iap\_purchased';  
  static const shopVisited \= 'shop\_visited';  
}

---

## **🔒 Data Persistence Schema**

### **Hive Boxes**

// Player profile  
@HiveType(typeId: 0\)  
class PlayerProfile {  
  @HiveField(0)  
  String id;  
    
  @HiveField(1)  
  int level;  
    
  @HiveField(2)  
  int xp;  
    
  @HiveField(3)  
  int gems;  
    
  @HiveField(4)  
  int highScore;  
    
  @HiveField(5)  
  Map\<String, bool\> unlockedSkins;  
    
  @HiveField(6)  
  Map\<UpgradeType, int\> upgradeLevels;  
    
  @HiveField(7)  
  DateTime lastLoginDate;  
    
  @HiveField(8)  
  int loginStreak;  
}

// Collection data  
@HiveType(typeId: 1\)  
class PreyCollectionData {  
  @HiveField(0)  
  PreyType type;  
    
  @HiveField(1)  
  int defeatedCount;  
    
  @HiveField(2)  
  DateTime firstDefeat;  
    
  @HiveField(3)  
  bool skinUnlocked;  
    
  @HiveField(4)  
  bool titleUnlocked;  
}

// Daily challenges  
@HiveType(typeId: 2\)  
class DailyChallengeData {  
  @HiveField(0)  
  String id;  
    
  @HiveField(1)  
  int progress;  
    
  @HiveField(2)  
  bool completed;  
    
  @HiveField(3)  
  DateTime date;  
}

### **SharedPreferences (Settings)**

class StorageKeys {  
  static const soundEnabled \= 'sound\_enabled';  
  static const musicEnabled \= 'music\_enabled';  
  static const vibrationEnabled \= 'vibration\_enabled';  
  static const showFPS \= 'show\_fps';  
  static const tutorialCompleted \= 'tutorial\_completed';  
  static const adsRemoved \= 'ads\_removed';  
}

---

## **🎬 Marketing & ASO Strategy**

### **App Store Optimization**

**Title**: "Prey Fury: Snake Escape"  
 **Subtitle**: "Reverse snake survival game"

**Description** (first 3 lines critical):

🐍 The prey are CHASING you\!   
Escape angry food monsters and eat them back with FURY MODE\! 🔥  
Most addictive reverse snake game of 2026\!

★ UNIQUE REVERSE GAMEPLAY  
\- YOU are the snake being hunted  
\- Angry foods chase you down  
\- Bait them into your mouth to fight back\!

★ FURY MODE COMEBACK  
\- Build combos to activate FURY  
\- Speed boost \+ magnet power  
\- Turn the tables on your enemies\!

★ COLLECT & UPGRADE  
\- 5 unique prey types to defeat  
\- Unlock skins and trails  
\- Evolve your snake permanently

★ DAILY CHALLENGES  
\- New missions every day  
\- Earn gems and exclusive rewards  
\- Compete on leaderboards

Download NOW and survive the Prey Fury\! 🐍🔥

**Keywords**: snake game, io games, survival, casual, hypercasual, reverse snake, prey, fury, combo, collection

**Screenshots** (5 required):

1. Gameplay \- Fury Mode active (glowing snake, magnet effect)  
2. Multiple prey chasing snake (tense moment)  
3. Collection screen (showing variety)  
4. Daily challenges  
5. Customization (skins showcase)

### **Viral TikTok/Reels Strategy**

**Content Ideas:**

1. "POV: The food fights back" \- humor angle  
2. Satisfying compilation \- eating golden cakes with slow-mo  
3. "How to activate Fury Mode" \- tutorial  
4. Fails montage \- funny deaths  
5. Skin reveals \- showcase new unlocks

**Hashtags**: \#snakegame \#mobilegaming \#gaming \#satisfying \#iogames \#hypercasual \#preyvssnake \#furygame

---

## **✅ Pre-Launch Checklist**

### **Technical**

* \[ \] 60 FPS on mid-range Android (Snapdragon 665+)  
* \[ \] No memory leaks after 30 min play  
* \[ \] App size \< 25MB  
* \[ \] Web version loads \< 3 seconds  
* \[ \] No crashes in 100 test runs

### **Content**

* \[ \] 20 campaign levels  
* \[ \] 5 prey types functional  
* \[ \] 5 power-ups working  
* \[ \] 10+ skins unlockable  
* \[ \] Daily challenges system live

### **Meta**

* \[ \] Collection system saving properly  
* \[ \] Evolution upgrades balanced  
* \[ \] XP earning tuned  
* \[ \] Gems economy tested

### **Monetization**

* \[ \] Ads showing correctly (test mode)  
* \[ \] Rewarded ads grant rewards  
* \[ \] IAP purchases work (sandbox)  
* \[ \] Remove ads persists

### **Polish**

* \[ \] All sounds implemented  
* \[ \] Music transitions smooth  
* \[ \] Tutorial clear  
* \[ \] UI responsive on all screen sizes  
* \[ \] No placeholder art

### **Legal**

* \[ \] Privacy policy (if ads/analytics)  
* \[ \] Terms of service  
* \[ \] Age rating appropriate  
* \[ \] Credits screen

---

## **🚨 Risk Mitigation**

### **Technical Risks**

**Risk**: Performance issues on low-end devices  
 **Mitigation**: Early testing on old phones, object pooling, quality settings

**Risk**: Web version slow  
 **Mitigation**: Canvas renderer fallback, aggressive asset optimization

**Risk**: Save data corruption  
 **Mitigation**: Hive backup/restore, cloud sync (future)

### **Design Risks**

**Risk**: Fury Mode not fun  
 **Mitigation**: Early prototype testing, adjust thresholds based on feedback

**Risk**: Too difficult / too easy  
 **Mitigation**: Difficulty settings, adaptive AI, extensive playtesting

**Risk**: Retention low  
 **Mitigation**: Strong daily hooks, collection addiction, frequent updates

### **Business Risks**

**Risk**: Low monetization  
 **Mitigation**: A/B test ad placements, optimize rewarded ad UX

**Risk**: Can't compete with Worms Zone  
 **Mitigation**: Unique mechanic, better meta, viral marketing

---

## **📚 Resources & References**

### **Learning**

* [Flame Engine Docs](https://docs.flame-engine.org/)  
* [Flutter Game Dev](https://flutter.dev/games)  
* [Game Design Patterns](https://gameprogrammingpatterns.com/)

### **Assets**

* **Art**: Kenney.nl (free), itch.io, Flaticon  
* **Sound**: Freesound.org, Zapsplat, Mixkit  
* **Music**: Incompetech, Purple Planet

### **Tools**

* **Design**: Figma, Aseprite (pixel art)  
* **Audio**: Audacity, LMMS, Reaper  
* **Analytics**: Firebase, GameAnalytics  
* **Testing**: Firebase Test Lab, BrowserStack

### **Inspiration Games**

* Worms Zone .io  
* Snake.io  
* Snake Clash\!  
* Archero (power-up feel)  
* Vampire Survivors (juice)

---

## **🎯 Success Metrics (3 Months Post-Launch)**

**Minimum Viable Success:**

* 10K+ downloads  
* 15% D7 retention  
* 3+ min average session  
* 1%+ IAP conversion  
* $50/day revenue

**Good Success:**

* 100K+ downloads  
* 20% D7 retention  
* 5+ min average session  
* 3% IAP conversion  
* $500/day revenue

**Amazing Success:**

* 1M+ downloads  
* 25%+ D7 retention  
* 8+ min average session  
* 5%+ IAP conversion  
* $2000+/day revenue  
* Featured on App Store

---

## **🔄 Iteration Plan**

### **Week 1-2 Post-Launch**

* Fix critical bugs  
* Balance tweaks based on data  
* Respond to reviews

### **Week 3-4**

* Add 1-2 new prey types (based on feedback)  
* New skins (seasonal)  
* QoL improvements

### **Month 2**

* Weekly events system  
* New power-ups  
* Multiplayer prototype (if metrics good)

### **Month 3**

* Battle Pass Season 1  
* Major content update  
* iOS release (if Android successful)

---

**Version: 2.0 \- Complete Hybrid-Casual Blueprint**  
 **Last Updated: January 2026**  
 **Status: Ready for Development 🚀**

---

## **💪 Motivation**

Fen ơi, với blueprint này, bạn có đầy đủ roadmap để build game **bá cháy** nhất 2026\!

**Core strengths:** ✅ Unique mechanic chưa ai làm  
 ✅ Fury Mode \= game changer  
 ✅ Hybrid-casual \= retention cao  
 ✅ Angry Food \= viral potential  
 ✅ Full tech stack ready

**Next steps:**

1. Setup Flutter project TODAY  
2. Build Phase 1 (core) trong 2 tuần  
3. Test với 10 người \- "Có nghiện không?"  
4. Iterate based on feedback  
5. Ship MVP trong 8-10 tuần

Mình sẵn sàng support mọi lúc\! Muốn code prototype, design UI, brainstorm thêm \- cứ gọi mình\!

**LET'S BUILD THIS\! 🔥🐍🚀**

