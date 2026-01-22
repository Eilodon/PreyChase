/// Ngũ Hành Faction System - 5 Elements for Vạn Cổ Chi Vương
///
/// Based on Chinese Wu Xing (五行) philosophy:
/// Kim (Metal) → khắc Mộc (Wood) → khắc Thổ (Earth) → khắc Thủy (Water) → khắc Hỏa (Fire) → khắc Kim
///
/// Each faction has:
/// - Unique creature visual (Ong, Rắn, Cóc, Tằm, Bò Cạp)
/// - Passive ability
/// - Active skill
/// - Tier 5 transformation
/// - Zone affinity

import 'package:flutter/material.dart';

/// The 5 elemental factions
enum NguHanhFaction {
  /// 🐝 Kim Tộc - Ong Vàng (Golden Bee)
  /// Playstyle: Assassin - Crit, burst damage, high risk
  kim,

  /// 🐍 Mộc Tộc - Rắn Lục (Green Snake)
  /// Playstyle: Sustain Tank - Lifesteal, regen, war of attrition
  moc,

  /// 🐸 Hỏa Tộc - Cóc Đỏ (Red Toad)
  /// Playstyle: DOT Mage - Burn, zone control
  hoa,

  /// 🐛 Thủy Tộc - Tằm Xanh (Blue Silkworm)
  /// Playstyle: Speed Demon - Kite, slow, outmaneuver
  thuy,

  /// 🦂 Thổ Tộc - Bò Cạp Nâu (Brown Scorpion)
  /// Playstyle: Defense Tank - Reflect, counter-attack
  tho,
}

/// Base stats for each faction
class FactionStats {
  final int hp;
  final int attack;
  final int speed;
  final double defense; // Damage reduction (0.0 - 1.0)
  final double critChance; // Only Kim has base crit
  final double magicResist; // Only Mộc has base magic resist

  const FactionStats({
    required this.hp,
    required this.attack,
    required this.speed,
    this.defense = 0.0,
    this.critChance = 0.0,
    this.magicResist = 0.0,
  });
}

/// Passive ability data
class PassiveAbility {
  final String name;
  final String nameVi;
  final String description;
  final String descriptionVi;

  const PassiveAbility({
    required this.name,
    required this.nameVi,
    required this.description,
    required this.descriptionVi,
  });
}

/// Active skill data
class ActiveSkill {
  final String name;
  final String nameVi;
  final String description;
  final String descriptionVi;
  final double cooldown;
  final double range;

  const ActiveSkill({
    required this.name,
    required this.nameVi,
    required this.description,
    required this.descriptionVi,
    required this.cooldown,
    this.range = 0,
  });
}

/// Tier 5 transformation data
class Tier5Transformation {
  final String name;
  final String nameVi;
  final String description;

  const Tier5Transformation({
    required this.name,
    required this.nameVi,
    required this.description,
  });
}

/// Complete faction data
class NguHanhFactionData {
  final NguHanhFaction faction;
  final String name;
  final String nameVi;
  final String emoji;
  final String creature;
  final String creatureVi;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final FactionStats baseStats;
  final NguHanhFaction counters; // Khắc
  final NguHanhFaction counteredBy; // Bị khắc
  final PassiveAbility passive;
  final ActiveSkill active;
  final Tier5Transformation transformation;

  const NguHanhFactionData({
    required this.faction,
    required this.name,
    required this.nameVi,
    required this.emoji,
    required this.creature,
    required this.creatureVi,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.baseStats,
    required this.counters,
    required this.counteredBy,
    required this.passive,
    required this.active,
    required this.transformation,
  });

  /// Get counter damage multiplier
  /// - Deals 1.5x damage to countered faction
  /// - Takes 1.5x damage from counter faction
  double getDamageMultiplierAgainst(NguHanhFaction target) {
    if (target == counters) return 1.5; // We counter them
    if (target == counteredBy) return 0.75; // They counter us (we deal less)
    return 1.0;
  }

  /// Get damage received multiplier
  double getDamageReceivedFrom(NguHanhFaction attacker) {
    if (attacker == counteredBy) return 1.5; // They counter us
    if (attacker == counters) return 0.75; // We counter them
    return 1.0;
  }
}

/// Central registry for all faction data
class NguHanhRegistry {
  static const Map<NguHanhFaction, NguHanhFactionData> _data = {
    // ═══════════════════════════════════════════════════════════════════════════
    // KIM TỘC - 🐝 ONG VÀNG (GOLDEN BEE) - ASSASSIN
    // ═══════════════════════════════════════════════════════════════════════════
    NguHanhFaction.kim: NguHanhFactionData(
      faction: NguHanhFaction.kim,
      name: 'Metal Clan',
      nameVi: 'Kim Tộc',
      emoji: '🐝',
      creature: 'Golden Bee',
      creatureVi: 'Ong Vàng',
      primaryColor: Color(0xFFC0C0C0), // Silver
      secondaryColor: Color(0xFF4682B4), // Steel Blue
      accentColor: Color(0xFF708090), // Slate Gray
      baseStats: FactionStats(
        hp: 90,
        attack: 14,
        speed: 130,
        defense: 0.10,
        critChance: 0.15, // UNIQUE: Base crit chance
      ),
      counters: NguHanhFaction.moc, // Kim khắc Mộc
      counteredBy: NguHanhFaction.hoa, // Hỏa khắc Kim
      passive: PassiveAbility(
        name: 'Sword Wind',
        nameVi: 'Kiếm Phong',
        description: '15% crit chance. Crits stack "Sát Khí" (max 3). At 3 stacks, next attack is guaranteed crit + bleed.',
        descriptionVi: '15% tỉ lệ chí mạng. Chí mạng tích "Sát Khí" (tối đa 3). Đủ 3 tầng, đòn tiếp theo chắc chắn chí mạng + gây chảy máu.',
      ),
      active: ActiveSkill(
        name: 'Continuous Sting',
        nameVi: 'Liên Châm Toát',
        description: 'Dash 120px toward cursor, damage enemies passed through. Kill resets 50% cooldown.',
        descriptionVi: 'Lướt 120px về phía con trỏ, gây sát thương cho kẻ địch đi qua. Giết địch giảm 50% hồi chiêu.',
        cooldown: 6.0,
        range: 120,
      ),
      transformation: Tier5Transformation(
        name: 'BẠO VŨ THIẾT PHONG',
        nameVi: '暴雨鐵蜂 - Bạo Vũ Thiết Phong',
        description: 'Crit chance 35%. Each crit fires wind blades in 3 directions. Dash 3 times consecutively.',
      ),
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // MỘC TỘC - 🐍 RẮN LỤC (GREEN SNAKE) - SUSTAIN TANK
    // ═══════════════════════════════════════════════════════════════════════════
    NguHanhFaction.moc: NguHanhFactionData(
      faction: NguHanhFaction.moc,
      name: 'Wood Clan',
      nameVi: 'Mộc Tộc',
      emoji: '🐍',
      creature: 'Green Snake',
      creatureVi: 'Rắn Lục',
      primaryColor: Color(0xFF4CAF50), // Green
      secondaryColor: Color(0xFF81C784), // Light Green
      accentColor: Color(0xFF2E7D32), // Dark Green
      baseStats: FactionStats(
        hp: 140,
        attack: 8,
        speed: 95,
        defense: 0.25,
        magicResist: 0.20, // UNIQUE: Magic resist
      ),
      counters: NguHanhFaction.tho, // Mộc khắc Thổ
      counteredBy: NguHanhFaction.kim, // Kim khắc Mộc
      passive: PassiveAbility(
        name: 'Serpent Regeneration',
        nameVi: 'Xà Linh Hồi Sinh',
        description: 'Standing still 1.5s: Heal 3 HP/s. Kills drop "Linh Châu" orbs (heal 20 HP). Below 30% HP: Regen x2.',
        descriptionVi: 'Đứng yên 1.5 giây: Hồi 3 HP/s. Giết địch rơi "Linh Châu" (hồi 20 HP). Dưới 30% HP: Hồi x2.',
      ),
      active: ActiveSkill(
        name: 'Constricting Drain',
        nameVi: 'Quấn Siết Hút Máu',
        description: 'Fire tongue (250px). Hit: Pull enemy + lifesteal 8 HP/s for 4s. Enemy slowed 40%.',
        descriptionVi: 'Bắn lưỡi (250px). Trúng: Kéo địch + hút máu 8 HP/s trong 4 giây. Địch chậm 40%.',
        cooldown: 8.0,
        range: 250,
      ),
      transformation: Tier5Transformation(
        name: 'THANH PHƯỢC YÊU XÀ',
        nameVi: '青鳳妖蛇 - Thanh Phược Yêu Xà',
        description: 'Magic Resist 40%. Healing aura 100px radius (2 HP/s for allies). Active roots enemy for 2s + 12 HP/s lifesteal.',
      ),
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // HỎA TỘC - 🐸 CÓC ĐỎ (RED TOAD) - DOT MAGE
    // ═══════════════════════════════════════════════════════════════════════════
    NguHanhFaction.hoa: NguHanhFactionData(
      faction: NguHanhFaction.hoa,
      name: 'Fire Clan',
      nameVi: 'Hỏa Tộc',
      emoji: '🐸',
      creature: 'Red Toad',
      creatureVi: 'Cóc Đỏ',
      primaryColor: Color(0xFFFF6B35), // Orange-Red
      secondaryColor: Color(0xFFFFD23F), // Yellow
      accentColor: Color(0xFFFF4500), // Orange Red
      baseStats: FactionStats(
        hp: 100,
        attack: 11,
        speed: 80,
        defense: 0.15,
      ),
      counters: NguHanhFaction.kim, // Hỏa khắc Kim
      counteredBy: NguHanhFaction.thuy, // Thủy khắc Hỏa
      passive: PassiveAbility(
        name: 'Lava Skin',
        nameVi: 'Nham Nhiệt Da',
        description: 'Attackers burn (4 dmg/s x 3s). Each burning enemy heals you 2 HP/s. Burns stack.',
        descriptionVi: 'Kẻ tấn công bị cháy (4 sát thương/giây x 3 giây). Mỗi địch đang cháy hồi 2 HP/giây cho bạn.',
      ),
      active: ActiveSkill(
        name: 'Lava Spit',
        nameVi: 'Nham Phún',
        description: 'Leap up, land creates 120px AOE: 25 dmg + 50% slow 2s. Leaves fire trail (8 dmg/s, 5s).',
        descriptionVi: 'Nhảy lên, rơi xuống tạo vùng 120px: 25 sát thương + chậm 50% trong 2 giây. Để lại vệt lửa (8 sát thương/giây, 5 giây).',
        cooldown: 10.0,
        range: 120,
      ),
      transformation: Tier5Transformation(
        name: 'NHAM HỎA XÍCH CÁP',
        nameVi: '岩火赤蟾 - Nham Hỏa Xích Cáp',
        description: 'Burn damage 6/s. Movement leaves fire trail (3s, 6 dmg/s). Lava Spit AOE 180px, trail 8s.',
      ),
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // THỦY TỘC - 🐛 TẰM XANH (BLUE SILKWORM) - SPEED DEMON
    // ═══════════════════════════════════════════════════════════════════════════
    NguHanhFaction.thuy: NguHanhFactionData(
      faction: NguHanhFaction.thuy,
      name: 'Water Clan',
      nameVi: 'Thủy Tộc',
      emoji: '🐛',
      creature: 'Blue Silkworm',
      creatureVi: 'Tằm Xanh',
      primaryColor: Color(0xFF2196F3), // Blue
      secondaryColor: Color(0xFF7B68EE), // Medium Slate Blue
      accentColor: Color(0xFF1565C0), // Dark Blue
      baseStats: FactionStats(
        hp: 75,
        attack: 9,
        speed: 150, // FASTEST
        defense: 0.05,
      ),
      counters: NguHanhFaction.hoa, // Thủy khắc Hỏa
      counteredBy: NguHanhFaction.tho, // Thổ khắc Thủy
      passive: PassiveAbility(
        name: 'Ice Speed',
        nameVi: 'Băng Tốc',
        description: 'Each skill use: +15% speed (stacks 3x, max +45%, 5s). At max: Leave ice trail that slows enemies 30% 2s.',
        descriptionVi: 'Mỗi lần dùng chiêu: +15% tốc độ (tối đa 3 tầng = +45%, 5 giây). Đủ tầng: Để lại vệt băng làm chậm địch 30% trong 2 giây.',
      ),
      active: ActiveSkill(
        name: 'Frozen Silk',
        nameVi: 'Tơ Băng Trói',
        description: 'Fire 3 silk threads (cone, 180px): 7 dmg + 50% slow 3s each. All 3 hit = 1.5s freeze (stun).',
        descriptionVi: 'Bắn 3 sợi tơ băng (hình nón, 180px): Mỗi sợi 7 sát thương + chậm 50% trong 3 giây. Trúng cả 3 = đóng băng 1.5 giây.',
        cooldown: 5.0,
        range: 180,
      ),
      transformation: Tier5Transformation(
        name: 'HÀN BĂNG CỔ TẰM',
        nameVi: '寒冰古蠶 - Hàn Băng Cổ Tằm',
        description: 'Base speed 180 (fastest!). Max speed stacks 5 (+75%). Active creates "Ice Cocoon" AOE 150px: 60% slow 4s.',
      ),
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // THỔ TỘC - 🦂 BÒ CẠP NÂU (BROWN SCORPION) - DEFENSE TANK
    // ═══════════════════════════════════════════════════════════════════════════
    NguHanhFaction.tho: NguHanhFactionData(
      faction: NguHanhFaction.tho,
      name: 'Earth Clan',
      nameVi: 'Thổ Tộc',
      emoji: '🦂',
      creature: 'Brown Scorpion',
      creatureVi: 'Bò Cạp Nâu',
      primaryColor: Color(0xFF8B5A3C), // Brown
      secondaryColor: Color(0xFFD4A574), // Tan
      accentColor: Color(0xFF654321), // Dark Brown
      baseStats: FactionStats(
        hp: 160, // HIGHEST HP
        attack: 6,
        speed: 70, // SLOWEST
        defense: 0.35, // HIGHEST DEFENSE
      ),
      counters: NguHanhFaction.thuy, // Thổ khắc Thủy
      counteredBy: NguHanhFaction.moc, // Mộc khắc Thổ
      passive: PassiveAbility(
        name: 'Diamond Armor',
        nameVi: 'Kim Cang Giáp',
        description: 'Reflect 25% damage taken. Below 30% HP: Reflect 50% + defense +20%. Each hit stacks "Resolve" (+2% defense, max 5).',
        descriptionVi: 'Phản lại 25% sát thương nhận. Dưới 30% HP: Phản 50% + phòng thủ +20%. Mỗi đòn đánh tích "Cương Quyết" (+2% phòng thủ, tối đa 5 tầng).',
      ),
      active: ActiveSkill(
        name: 'Tail Counter-Strike',
        nameVi: 'Đuôi Quật Phản Kích',
        description: 'Raise shield 3s (absorb 60 dmg). If broken: Spin 360°, knockback + 30 dmg in 100px. Not broken: 50% CD refund.',
        descriptionVi: 'Dựng khiên 3 giây (hấp thụ 60 sát thương). Nếu vỡ: Quay 360°, đẩy lùi + 30 sát thương trong 100px. Không vỡ: Hoàn 50% hồi chiêu.',
        cooldown: 12.0,
        range: 100,
      ),
      transformation: Tier5Transformation(
        name: 'KIM CANG ĐỘC HẠT',
        nameVi: '金剛毒蠍 - Kim Cang Độc Hạt',
        description: 'Defense 50% reduction. Reflect causes poison (3 dmg/s x 4s). Shield absorbs 100 dmg + CC immune while active.',
      ),
    ),
  };

  /// Get faction data
  static NguHanhFactionData get(NguHanhFaction faction) => _data[faction]!;

  /// Get all factions
  static List<NguHanhFactionData> get all => _data.values.toList();

  /// Get faction by emoji
  static NguHanhFaction? fromEmoji(String emoji) {
    for (final data in _data.values) {
      if (data.emoji == emoji) return data.faction;
    }
    return null;
  }

  /// Check if A counters B
  static bool counters(NguHanhFaction a, NguHanhFaction b) {
    return _data[a]!.counters == b;
  }

  /// Get damage multiplier when A attacks B
  static double getDamageMultiplier(NguHanhFaction attacker, NguHanhFaction defender) {
    return _data[attacker]!.getDamageMultiplierAgainst(defender);
  }

  /// Get the counter chain description
  static String get counterChainDescription =>
      'Kim → Mộc → Thổ → Thủy → Hỏa → Kim';
}

/// Extension for faction UI helpers
extension NguHanhFactionExt on NguHanhFaction {
  NguHanhFactionData get data => NguHanhRegistry.get(this);
  String get emoji => data.emoji;
  String get nameVi => data.nameVi;
  Color get color => data.primaryColor;
  NguHanhFaction get counters => data.counters;
  NguHanhFaction get counteredBy => data.counteredBy;
}
