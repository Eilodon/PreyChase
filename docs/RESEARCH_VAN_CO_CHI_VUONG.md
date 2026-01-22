# VẠN CỔ CHI VƯƠNG - Research & Implementation Analysis

**Date:** 2026-01-22
**Branch:** `claude/research-feeding-frenzy-j0H38`
**Status:** Research Complete

---

## Executive Summary

Sau khi nghiên cứu kỹ codebase hiện tại (`prey_fury`) và so sánh với GDD "Vạn Cổ Chi Vương", tôi đã xác định được:

1. **Nền tảng hiện có rất mạnh** - 70% cơ sở hạ tầng đã sẵn sàng
2. **Cần pivot từ Wave-Survival sang Battle Royale** - Thay đổi game loop cốt lõi
3. **Flutter/Flame hoạt động tốt** - Không cần chuyển sang Phaser.js như GDD đề xuất
4. **Có thể tái sử dụng nhiều hệ thống** - Mutations, Biomes, AI behaviors

---

## 1. CODEBASE ANALYSIS - Những Gì Đã Có

### 1.1 Tech Stack (Giữ nguyên - Không đổi)

```
Current Stack:              GDD Recommendation:
─────────────────────────   ─────────────────────────
Flutter 3.9.2               Phaser.js (Browser)
Flame Engine 1.34.0         → KHÔNG CẦN THAY ĐỔI
Dart                        JavaScript
Riverpod                    -
```

**Quyết định:** Giữ Flutter/Flame. Lý do:
- Performance tốt hơn Phaser.js cho game có nhiều entities
- Đã có codebase mature với 50+ files, 5000+ LOC
- Cross-platform (Web, Mobile, Desktop) sẵn sàng
- Flame có ECS pattern phù hợp với game design này

### 1.2 Core Systems - So Sánh Chi Tiết

| System | Current | GDD Requirement | Match | Action |
|--------|---------|-----------------|-------|--------|
| **Player Movement** | WASD, 8-dir | Mouse follow | 60% | Add mouse option |
| **Size System** | Fatness 0-10 | Size tiers 1-5 | 70% | Refactor to tiers |
| **Eating Mechanic** | Fury mode only | Size-based (90/110% rule) | 30% | Major change |
| **Split/Dash** | None | Space = split, W = eject | 0% | New system |
| **Factions** | 4 food-based | 5 Ngũ Hành | 50% | Redesign |
| **Mutations** | 18 types | 20+ types | 90% | Minor additions |
| **Zones/Biomes** | 4 biomes | 5 zones | 80% | Add 1 zone |
| **Hazards** | Obstacles only | Lightning, Poison, Zone | 40% | Add systems |
| **AI Behaviors** | 3 emotions | Complex faction AI | 50% | Enhance |
| **Battle Royale** | None | Shrinking zone, last alive | 0% | New system |

### 1.3 Existing Systems - Có Thể Tái Sử Dụng

#### A. Mutation System (`kernel/models/mutation_type.dart`)
```dart
// 18 mutations đã có, có thể mapping trực tiếp:
MutationType.speedDemon      → "Tốc Hành" (+20% speed)
MutationType.armoredScales   → "Máu Dày" (-30% damage)
MutationType.thornAura       → "Gai Nhẹ" (reflect damage)
MutationType.criticalBite    → "Sát Khí" (crit chance)
MutationType.lifeSteal       → "Hút Máu" (heal on damage)
MutationType.ghostPhase      → "Tàng Hình" (i-frames)
MutationType.venomousFangs   → "Độc Tố" (poison)
MutationType.secondChance    → "Bất Tử" (revive once)
MutationType.timeWarp        → "Thời Gian Ngược" (slow-mo)
MutationType.berserker       → "Cổ Vương Hóa" (low HP = high dmg)
```

**Gap Analysis:** Cần thêm:
- "Phân Thân" (split thành 3)
- "Ma Tốc" (burst speed cooldown)
- "Từ Trường" (push enemies)
- "Hấp Tinh" (2x growth on kill)
- "Thiên Kiếp" (call lightning)
- "Hỗn Độn" (swap size with enemy)

#### B. Biome System (`kernel/models/biome.dart`)
```dart
// 4 biomes đã có:
BiomeType.swampStart   → Zone Mộc (rừng, vines)
BiomeType.lavaField    → Zone Hỏa (núi lửa)
BiomeType.iceTundra    → Zone Thủy (băng)
BiomeType.voidRift     → Trung Tâm (chaos)

// Cần thêm:
- Zone Kim (rừng tre, gió)
- Zone Thổ (đá, cát)
```

#### C. Faction System (`kernel/models/faction.dart`)
```dart
// 4 factions đã có (cần redesign):
PreyFaction.fruitGang     → Need: Kim Tộc (Ong)
PreyFaction.junkFoodMafia → Need: Mộc Tộc (Rắn)
PreyFaction.ninjaClan     → Need: Hỏa Tộc (Cóc)
PreyFaction.dessertCult   → Need: Thủy Tộc (Tằm)
                          → Need: Thổ Tộc (Bò Cạp)
```

#### D. Prey/Entity System (`crocodile_game/components/prey_component.dart`)
```dart
// AI behaviors đã có:
PreyVisualEmotion.angry     → Chase player
PreyVisualEmotion.terrified → Flee from player
PreyVisualEmotion.desperate → Speed boost when last

// Steering behaviors:
- _seek()           → Đuổi theo target
- _flee()           → Chạy khỏi target
- _wander()         → Di chuyển ngẫu nhiên
- _separationForce() → Tránh đám đông

// Cần thêm cho Battle Royale:
- Size-based targeting (eat smaller, flee larger)
- Faction-based aggression
- Combat between AI entities
```

---

## 2. IMPLEMENTATION STRATEGY - Phương Án Triển Khai

### 2.1 Option A: Full Pivot (Khuyến nghị)
**Thay đổi hoàn toàn game concept** từ Wave-Survival sang Battle Royale

**Pros:**
- Đúng với vision của GDD
- Gameplay độc đáo hơn (Feeding Frenzy + Agar.io + BR)
- Replayability cao hơn

**Cons:**
- Cần refactor nhiều
- Mất 3-4 tuần development
- Risk cao hơn

### 2.2 Option B: Hybrid Mode
**Giữ Wave-Survival, thêm Battle Royale mode**

**Pros:**
- Ít rủi ro
- Có 2 game modes
- Development nhanh hơn (2 tuần)

**Cons:**
- Codebase phức tạp hơn
- Không 100% đúng GDD vision

### 2.3 Option C: Gradual Migration
**Từng bước chuyển đổi qua nhiều updates**

**Pros:**
- Có thể ship từng phần
- Test với players thực
- Flexible

**Cons:**
- Timeline dài (6-8 tuần)
- Version management phức tạp

---

## 3. RECOMMENDED IMPLEMENTATION - Chi Tiết Kỹ Thuật

### Phase 1: Core Mechanics Rewrite (Priority: HIGH)

#### 1.1 Size-Based Eating System
**File cần sửa:** `fury_world.dart`, `crocodile_player.dart`

```dart
// NEW: Size Manager class
class SizeManager {
  static const double EAT_THRESHOLD = 0.9;   // Can eat if target <= 90% your size
  static const double EATEN_THRESHOLD = 1.1; // Get eaten if predator >= 110% your size

  static SizeRelation getRelation(double mySize, double theirSize) {
    final ratio = mySize / theirSize;
    if (ratio >= 1.1) return SizeRelation.larger;   // Can eat
    if (ratio <= 0.9) return SizeRelation.smaller;  // Will be eaten
    return SizeRelation.equal; // Combat zone
  }
}

enum SizeRelation { larger, smaller, equal }
```

**Thay thế Fury System:**
- Bỏ fury mode (không cần nữa)
- Size determines who eats who
- Combat xảy ra khi size gần bằng nhau (90-110%)

#### 1.2 Size Tier Visual System
**File cần sửa:** `crocodile_player.dart`

```dart
enum SizeTier {
  tier1_larva,    // 0-20% max size - Ấu Trùng
  tier2_juvenile, // 20-40% - Thiếu Niên
  tier3_adult,    // 40-60% - Trưởng Thành
  tier4_elite,    // 60-80% - Tinh Anh
  tier5_king,     // 80-100% - Cổ Vương
}

// Mỗi tier có:
// - Sprite riêng (evolution visual)
// - Size multiplier
// - Base stats modifier
// - Mutation unlock (1 mutation per tier up)
```

#### 1.3 Split & Dash Mechanics
**File mới:** `split_system.dart`

```dart
class SplitSystem {
  static const double SPLIT_DASH_DISTANCE = 200.0;
  static const double MERGE_COOLDOWN = 10.0;

  List<PlayerFragment> fragments = [];

  void split(PlayerEntity player, Vector2 cursorDirection) {
    // Split into 2 equal parts
    // One part dashes toward cursor
    // Both parts are now vulnerable (smaller)
  }

  void ejectMass(PlayerEntity player, Vector2 direction) {
    // Eject 10% mass as projectile
    // Can be used to:
    // - Feed allies
    // - Propel self (Newton's 3rd law)
    // - Bait enemies
  }
}
```

### Phase 2: Battle Royale Systems (Priority: HIGH)

#### 2.1 Shrinking Zone (Bo)
**File mới:** `battle_royale_manager.dart`

```dart
class BattleRoyaleManager extends Component {
  // Map: 2000x2000 circular
  static const double MAP_RADIUS = 1000.0;

  // Shrink phases
  double currentSafeRadius = MAP_RADIUS;
  double targetRadius = MAP_RADIUS;
  double shrinkSpeed = 0.0;

  // Poison damage outside zone
  double poisonDamage = 5.0; // Starts at 5, increases each phase

  // Game phases (8 minutes total)
  int currentPhase = 0;
  final phases = [
    Phase(start: 0, end: 150, shrinkTo: 700, poisonDmg: 5),   // 0:00-2:30
    Phase(start: 150, end: 300, shrinkTo: 400, poisonDmg: 8), // 2:30-5:00
    Phase(start: 300, end: 450, shrinkTo: 250, poisonDmg: 12), // 5:00-7:30
    Phase(start: 450, end: 510, shrinkTo: 0, poisonDmg: 20),  // 7:30+ Sudden Death
  ];
}
```

#### 2.2 Thiên Kiếp (Lightning Hazard)
**File mới:** `lightning_system.dart`

```dart
class LightningSystem extends Component {
  double strikeInterval = 12.0; // Starts every 12s, decreases over time

  void triggerLightning() {
    // 1. Select target (weighted by size - bigger = more likely)
    final target = selectTarget();

    // 2. Telegraph warning (1.2s, red circle + sound)
    showWarning(target.position, 1.2);

    // 3. Strike after delay
    Future.delayed(Duration(milliseconds: 1200), () {
      strike(target.position, damage: 40); // 40% max HP
    });
  }

  Entity selectTarget() {
    // Weighted random: larger entities more likely to be hit
    final weights = entities.map((e) => e.size * e.size).toList();
    return weightedRandom(entities, weights);
  }
}
```

### Phase 3: Ngũ Hành Faction Redesign (Priority: MEDIUM)

#### 3.1 New Faction Definitions
**File cần sửa:** `faction.dart`

```dart
enum NguHanhFaction {
  kim,   // 🐝 Ong Vàng - Assassin, crit, burst
  moc,   // 🐍 Rắn Lục - Tank, lifesteal, sustain
  hoa,   // 🐸 Cóc Đỏ - Mage, DoT, zone control
  thuy,  // 🐛 Tằm Xanh - Speed, CC, kite
  tho,   // 🦂 Bò Cạp - Defense, reflect, counter
}

// Ngũ Hành Counter System
// Kim khắc Mộc (kim chặt gỗ)
// Mộc khắc Thổ (rễ xuyên đất)
// Thổ khắc Thủy (đất hấp thụ nước)
// Thủy khắc Hỏa (nước dập lửa)
// Hỏa khắc Kim (lửa nấu chảy kim loại)

class NguHanhFactionData {
  final NguHanhFaction faction;
  final NguHanhFaction counters;    // Khắc
  final NguHanhFaction counteredBy; // Bị khắc
  final FactionStats baseStats;
  final PassiveAbility passive;
  final ActiveAbility active;
  final Tier5Transformation transformation;
}
```

#### 3.2 Faction-Specific Stats
```dart
// Kim Tộc - Ong Vàng (Assassin)
const kimStats = FactionStats(
  hp: 90,
  atk: 14,
  speed: 130,
  defense: 0.10,
  critChance: 0.15, // Unique!
);

// Mộc Tộc - Rắn Lục (Tank)
const mocStats = FactionStats(
  hp: 140,
  atk: 8,
  speed: 95,
  defense: 0.25,
  magicResist: 0.20, // Unique!
);

// Hỏa Tộc - Cóc Đỏ (Mage)
const hoaStats = FactionStats(
  hp: 100,
  atk: 11,
  speed: 80,
  defense: 0.15,
);

// Thủy Tộc - Tằm Xanh (Speed)
const thuyStats = FactionStats(
  hp: 75,
  atk: 9,
  speed: 150, // Fastest!
  defense: 0.05,
);

// Thổ Tộc - Bò Cạp (Defense)
const thoStats = FactionStats(
  hp: 160, // Highest!
  atk: 6,
  speed: 70, // Slowest
  defense: 0.35, // Highest!
);
```

### Phase 4: Zone/Map Redesign (Priority: MEDIUM)

#### 4.1 Five Zones Layout
**File mới:** `ngu_hanh_zone.dart`

```dart
// Map: 2000x2000 circular
// 5 zones ở các góc, trung tâm là Vực Vạn Cổ

class MapLayout {
  static const double MAP_SIZE = 2000.0;
  static const double ZONE_SIZE = 400.0;

  // Zone positions (rough layout)
  static final zones = {
    NguHanhFaction.hoa: ZoneData(
      center: Vector2(-600, -600),  // Northwest
      terrain: [TerrainType.lavaPool, TerrainType.geyser],
      neutral: CreepType.salamander,
      powerUp: PowerUpType.hoaChau, // +30% damage
    ),
    NguHanhFaction.moc: ZoneData(
      center: Vector2(0, -700),     // North
      terrain: [TerrainType.tallGrass, TerrainType.vines],
      neutral: CreepType.poisonFrog,
      powerUp: PowerUpType.linhDuoc, // Heal 30%
    ),
    NguHanhFaction.thuy: ZoneData(
      center: Vector2(600, -600),   // Northeast
      terrain: [TerrainType.ice, TerrainType.thinIce],
      neutral: CreepType.iceSlime,
      powerUp: PowerUpType.bangTam, // +40% speed
    ),
    NguHanhFaction.kim: ZoneData(
      center: Vector2(-600, 600),   // Southwest
      terrain: [TerrainType.bamboo, TerrainType.windTunnel],
      neutral: CreepType.hornet,
      powerUp: PowerUpType.kiemKhi, // Crit x5
    ),
    NguHanhFaction.tho: ZoneData(
      center: Vector2(600, 600),    // Southeast
      terrain: [TerrainType.boulder, TerrainType.crumbling],
      neutral: CreepType.rockCrab,
      powerUp: PowerUpType.kimCang, // Shield 50 HP
    ),
  };

  // Center zone - Vực Vạn Cổ (Final Arena)
  static final centerZone = CenterZoneData(
    radius: 250.0,
    boss: BossType.coTrungMau,
    terrain: TerrainType.chaos, // Mix of all elements
  );
}
```

### Phase 5: AI Enhancement (Priority: MEDIUM)

#### 5.1 Battle Royale AI
**File cần sửa:** `prey_component.dart` → `critter_ai.dart`

```dart
class CritterAI extends Component {
  // State machine for BR behavior
  AIState state = AIState.farm;

  void update(double dt) {
    final threats = scanForThreats();
    final prey = scanForPrey();

    // Priority: Survive > Kill > Farm
    if (threats.isNotEmpty) {
      state = AIState.flee;
      fleeFrom(threats.nearest);
    } else if (prey.isNotEmpty && shouldHunt()) {
      state = AIState.hunt;
      chase(prey.weakest);
    } else {
      state = AIState.farm;
      seekFood();
    }
  }

  List<Entity> scanForThreats() {
    // Find entities that can eat us (size > 110% our size)
    return nearbyEntities.where((e) =>
      SizeManager.getRelation(e.size, this.size) == SizeRelation.larger
    ).toList();
  }

  List<Entity> scanForPrey() {
    // Find entities we can eat (size < 90% our size)
    return nearbyEntities.where((e) =>
      SizeManager.getRelation(this.size, e.size) == SizeRelation.larger
    ).toList();
  }

  bool shouldHunt() {
    // Decision factors:
    // - Current size vs average size
    // - Game phase (more aggressive late game)
    // - Faction aggression level
    // - 20% random noise for unpredictability
  }
}
```

#### 5.2 AI Personality Types
```dart
enum AIPersonality {
  aggressive, // 70% hunt, 30% farm
  passive,    // 30% hunt, 70% farm
  sneaky,     // Target weakest, avoid fights
  berserker,  // Always attack, ignore threats
  survivor,   // Prioritize survival, only eat when safe
}

// Each AI gets random personality at spawn
// Higher difficulty = smarter personality mix
```

---

## 4. FILE STRUCTURE - Proposed Changes

```
lib/
├── kernel/
│   ├── models/
│   │   ├── critter.dart           # NEW: Replace prey.dart
│   │   ├── ngu_hanh_faction.dart  # NEW: Replace faction.dart
│   │   ├── mutation_type.dart     # KEEP: Add 6 new mutations
│   │   ├── size_tier.dart         # NEW: Size system
│   │   └── biome.dart             # MODIFY: Add 2 zones
│   ├── systems/
│   │   ├── size_manager.dart      # NEW: Size-based eating
│   │   ├── split_system.dart      # NEW: Split/dash mechanics
│   │   ├── battle_royale.dart     # NEW: BR game loop
│   │   └── lightning_system.dart  # NEW: Thiên Kiếp hazard
│   └── logic/
│       └── critter_ai.dart        # MODIFY: Enhanced AI
│
├── crocodile_game/ → rename to → van_co_game/
│   ├── components/
│   │   ├── player_critter.dart    # MODIFY: From crocodile_player
│   │   ├── ai_critter.dart        # NEW: AI-controlled critters
│   │   ├── zone_component.dart    # NEW: Zone rendering
│   │   └── hazard_component.dart  # NEW: Lightning, poison
│   ├── config/
│   │   ├── game_config.dart       # MODIFY: BR settings
│   │   └── faction_config.dart    # NEW: Ngũ Hành data
│   └── van_co_world.dart          # MODIFY: Main game world
│
└── view/
    └── screens/
        ├── faction_select.dart    # NEW: Choose faction
        └── game_hud.dart          # MODIFY: BR-style HUD
```

---

## 5. IMPLEMENTATION TIMELINE

### Sprint 1 (Week 1-2): Core Mechanics
- [ ] Size-based eating system
- [ ] Remove Fury dependency
- [ ] Size tier visuals
- [ ] Basic split mechanic

### Sprint 2 (Week 3-4): Battle Royale
- [ ] Shrinking zone (Bo)
- [ ] Poison damage outside zone
- [ ] Game timer & phases
- [ ] Win condition (last alive)

### Sprint 3 (Week 5-6): Factions & AI
- [ ] 5 Ngũ Hành factions
- [ ] Counter system (khắc)
- [ ] Faction abilities
- [ ] Enhanced AI behaviors

### Sprint 4 (Week 7-8): Polish & Content
- [ ] 5 zones with unique terrain
- [ ] Thiên Kiếp hazard
- [ ] New mutations
- [ ] Visual polish
- [ ] Sound design

---

## 6. RISK ASSESSMENT

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Size system breaks balance | High | High | Extensive playtesting, tunable constants |
| AI too predictable | Medium | Medium | Add randomness, multiple personalities |
| Performance with 20 entities | Low | High | Spatial grid already optimized |
| Faction imbalance | High | Medium | Accept 45-55% win rate, iterate |
| Split mechanic too complex | Medium | Medium | Start simple, add complexity later |

---

## 7. CONCLUSION

Codebase hiện tại có nền tảng tốt để triển khai "Vạn Cổ Chi Vương":

**Strengths (Điểm mạnh):**
- Flutter/Flame performance tốt
- Mutation system gần hoàn chỉnh
- Biome system có thể mở rộng
- AI framework có steering behaviors
- Spatial grid optimization đã có

**Gaps (Khoảng trống cần lấp):**
- Size-based eating (thay Fury mode)
- Split/dash mechanics
- Battle Royale game loop
- Ngũ Hành faction system
- Thiên Kiếp hazard

**Recommendation:** Thực hiện Option A (Full Pivot) với timeline 8 tuần. Game sẽ có identity độc đáo và gameplay depth cao hơn current wave-survival mode.

---

## 8. NEXT STEPS

1. **Immediate:** Quyết định Option A/B/C
2. **Week 1:** Start với Size Manager + eating mechanic
3. **Ongoing:** Weekly playtests để validate changes

---

*Document prepared by Claude Code Research Agent*
