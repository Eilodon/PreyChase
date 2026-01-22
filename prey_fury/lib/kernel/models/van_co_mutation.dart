/// Vạn Cổ Chi Vương Mutation System
///
/// Enhanced mutation system based on GDD with:
/// - 4 tiers: Common (60%), Rare (30%), Epic (9%), Legendary (1%)
/// - Synergies and anti-synergies
/// - Vietnamese names and descriptions

import 'package:flutter/material.dart';

/// Mutation rarity tier
enum MutationRarity {
  common(
    dropRate: 0.60,
    color: Color(0xFF9E9E9E), // Gray
    powerBoost: 0.15, // 10-15% power
  ),
  rare(
    dropRate: 0.30,
    color: Color(0xFF2196F3), // Blue
    powerBoost: 0.25, // 20-30% power
  ),
  epic(
    dropRate: 0.09,
    color: Color(0xFF9C27B0), // Purple
    powerBoost: 0.50, // 40-60% power
  ),
  legendary(
    dropRate: 0.01,
    color: Color(0xFFFFD700), // Gold
    powerBoost: 1.0, // 100%+ power
  );

  final double dropRate;
  final Color color;
  final double powerBoost;

  const MutationRarity({
    required this.dropRate,
    required this.color,
    required this.powerBoost,
  });
}

/// All mutations in Vạn Cổ Chi Vương
enum VanCoMutation {
  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON MUTATIONS (60%)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tốc Hành - +15% speed
  tocHanh,

  /// Máu Dày - +20% max HP
  mauDay,

  /// Gai Nhẹ - Reflect 10% damage
  gaiNhe,

  /// Sát Khí - +10% damage
  satKhi,

  /// Thính Giác - +30% view range
  thinhGiac,

  // ═══════════════════════════════════════════════════════════════════════════
  // RARE MUTATIONS (30%)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dash Boost - Split dash +50% range
  dashBoost,

  /// Hút Máu - Lifesteal 15%
  hutMau,

  /// Xuyên Giáp - Ignore 20% defense
  xuyenGiap,

  /// Tàng Hình - Invisible when still 3s
  tangHinh,

  /// Độc Tố - Attacks poison (3 DPS x 3s)
  docTo,

  // ═══════════════════════════════════════════════════════════════════════════
  // EPIC MUTATIONS (9%)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Phân Thân - Split into 3 instead of 2
  phanThan,

  /// Bất Tử - Survive fatal hit once with 1 HP
  batTu,

  /// Ma Tốc - +100% speed for 5s, 30s cooldown
  maToc,

  /// Từ Trường - Push small enemies 50px
  tuTruong,

  /// Hấp Tinh - Kills give 2x growth
  hapTinh,

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGENDARY MUTATIONS (1%)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Thời Gian Ngược - Rewind 5s (position + HP)
  thoiGianNguoc,

  /// Thiên Kiếp - Call lightning on 3 nearest enemies
  thienKiep,

  /// Cổ Vương Hóa - Size x2 for 15s
  coVuongHoa,

  /// Bất Diệt - Immune to damage 3s
  batDiet,

  /// Hỗn Độn - Swap size with random enemy
  honDon,
}

/// Complete mutation data
class VanCoMutationData {
  final VanCoMutation type;
  final String name;
  final String nameVi;
  final String description;
  final String descriptionVi;
  final String emoji;
  final MutationRarity rarity;
  final Color color;
  final List<VanCoMutation> synergies;
  final List<VanCoMutation> antiSynergies;

  // Effect values
  final double? speedBonus;
  final double? hpBonus;
  final double? damageBonus;
  final double? reflectPercent;
  final double? lifestealPercent;
  final double? armorPenPercent;
  final double? viewRangeBonus;
  final double? cooldown;
  final double? duration;

  const VanCoMutationData({
    required this.type,
    required this.name,
    required this.nameVi,
    required this.description,
    required this.descriptionVi,
    required this.emoji,
    required this.rarity,
    required this.color,
    this.synergies = const [],
    this.antiSynergies = const [],
    this.speedBonus,
    this.hpBonus,
    this.damageBonus,
    this.reflectPercent,
    this.lifestealPercent,
    this.armorPenPercent,
    this.viewRangeBonus,
    this.cooldown,
    this.duration,
  });

  /// Get synergy bonus (15% per synergy)
  double getSynergyBonus(List<VanCoMutation> activeMutations) {
    int count = 0;
    for (final m in activeMutations) {
      if (synergies.contains(m)) count++;
    }
    return 1.0 + (count * 0.15);
  }
}

/// Central mutation registry
class VanCoMutationRegistry {
  static const Map<VanCoMutation, VanCoMutationData> _data = {
    // ═══════════════════════════════════════════════════════════════════════════
    // COMMON MUTATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    VanCoMutation.tocHanh: VanCoMutationData(
      type: VanCoMutation.tocHanh,
      name: 'Swift Movement',
      nameVi: 'Tốc Hành',
      description: '+15% movement speed',
      descriptionVi: '+15% tốc độ di chuyển',
      emoji: '💨',
      rarity: MutationRarity.common,
      color: Color(0xFF42A5F5),
      speedBonus: 0.15,
      synergies: [VanCoMutation.maToc, VanCoMutation.dashBoost],
    ),

    VanCoMutation.mauDay: VanCoMutationData(
      type: VanCoMutation.mauDay,
      name: 'Thick Blood',
      nameVi: 'Máu Dày',
      description: '+20% max HP',
      descriptionVi: '+20% máu tối đa',
      emoji: '❤️',
      rarity: MutationRarity.common,
      color: Color(0xFFE53935),
      hpBonus: 0.20,
      synergies: [VanCoMutation.batTu, VanCoMutation.hutMau],
    ),

    VanCoMutation.gaiNhe: VanCoMutationData(
      type: VanCoMutation.gaiNhe,
      name: 'Light Thorns',
      nameVi: 'Gai Nhẹ',
      description: 'Reflect 10% damage taken',
      descriptionVi: 'Phản lại 10% sát thương nhận',
      emoji: '🌵',
      rarity: MutationRarity.common,
      color: Color(0xFF8D6E63),
      reflectPercent: 0.10,
      synergies: [VanCoMutation.mauDay, VanCoMutation.tuTruong],
    ),

    VanCoMutation.satKhi: VanCoMutationData(
      type: VanCoMutation.satKhi,
      name: 'Killing Intent',
      nameVi: 'Sát Khí',
      description: '+10% damage dealt',
      descriptionVi: '+10% sát thương gây ra',
      emoji: '⚔️',
      rarity: MutationRarity.common,
      color: Color(0xFFD32F2F),
      damageBonus: 0.10,
      synergies: [VanCoMutation.xuyenGiap, VanCoMutation.docTo],
    ),

    VanCoMutation.thinhGiac: VanCoMutationData(
      type: VanCoMutation.thinhGiac,
      name: 'Keen Hearing',
      nameVi: 'Thính Giác',
      description: '+30% view range (fog of war)',
      descriptionVi: '+30% tầm nhìn (sương mù)',
      emoji: '👂',
      rarity: MutationRarity.common,
      color: Color(0xFF7B1FA2),
      viewRangeBonus: 0.30,
      synergies: [VanCoMutation.tangHinh],
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // RARE MUTATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    VanCoMutation.dashBoost: VanCoMutationData(
      type: VanCoMutation.dashBoost,
      name: 'Dash Boost',
      nameVi: 'Tăng Tốc Lướt',
      description: 'Split dash range +50%',
      descriptionVi: 'Tầm lướt khi phân thân +50%',
      emoji: '🚀',
      rarity: MutationRarity.rare,
      color: Color(0xFF00BCD4),
      synergies: [VanCoMutation.tocHanh, VanCoMutation.phanThan],
    ),

    VanCoMutation.hutMau: VanCoMutationData(
      type: VanCoMutation.hutMau,
      name: 'Blood Drain',
      nameVi: 'Hút Máu',
      description: 'Heal 15% of damage dealt',
      descriptionVi: 'Hồi 15% sát thương gây ra',
      emoji: '🩸',
      rarity: MutationRarity.rare,
      color: Color(0xFFC62828),
      lifestealPercent: 0.15,
      synergies: [VanCoMutation.satKhi, VanCoMutation.mauDay],
    ),

    VanCoMutation.xuyenGiap: VanCoMutationData(
      type: VanCoMutation.xuyenGiap,
      name: 'Armor Piercing',
      nameVi: 'Xuyên Giáp',
      description: 'Ignore 20% of enemy defense',
      descriptionVi: 'Xuyên qua 20% giáp địch',
      emoji: '🗡️',
      rarity: MutationRarity.rare,
      color: Color(0xFF455A64),
      armorPenPercent: 0.20,
      synergies: [VanCoMutation.satKhi, VanCoMutation.hapTinh],
    ),

    VanCoMutation.tangHinh: VanCoMutationData(
      type: VanCoMutation.tangHinh,
      name: 'Invisibility',
      nameVi: 'Tàng Hình',
      description: 'Invisible when standing still 3s',
      descriptionVi: 'Tàng hình khi đứng yên 3 giây',
      emoji: '👻',
      rarity: MutationRarity.rare,
      color: Color(0xFFB39DDB),
      duration: 3.0,
      synergies: [VanCoMutation.thinhGiac, VanCoMutation.docTo],
    ),

    VanCoMutation.docTo: VanCoMutationData(
      type: VanCoMutation.docTo,
      name: 'Venom',
      nameVi: 'Độc Tố',
      description: 'Attacks poison: 3 DPS x 3s',
      descriptionVi: 'Đòn đánh gây độc: 3 sát thương/giây x 3 giây',
      emoji: '🐍',
      rarity: MutationRarity.rare,
      color: Color(0xFF7CB342),
      damageBonus: 9.0, // Total 9 damage over 3s
      duration: 3.0,
      synergies: [VanCoMutation.satKhi, VanCoMutation.tangHinh],
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // EPIC MUTATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    VanCoMutation.phanThan: VanCoMutationData(
      type: VanCoMutation.phanThan,
      name: 'Clone Split',
      nameVi: 'Phân Thân',
      description: 'Split into 3 instead of 2',
      descriptionVi: 'Phân thân thành 3 thay vì 2',
      emoji: '👥',
      rarity: MutationRarity.epic,
      color: Color(0xFF7E57C2),
      synergies: [VanCoMutation.dashBoost],
      antiSynergies: [VanCoMutation.coVuongHoa],
    ),

    VanCoMutation.batTu: VanCoMutationData(
      type: VanCoMutation.batTu,
      name: 'Immortal',
      nameVi: 'Bất Tử',
      description: 'Survive fatal hit once with 1 HP',
      descriptionVi: 'Sống sót 1 lần/trận với 1 HP khi chết',
      emoji: '💀',
      rarity: MutationRarity.epic,
      color: Color(0xFF37474F),
      synergies: [VanCoMutation.mauDay, VanCoMutation.hutMau],
    ),

    VanCoMutation.maToc: VanCoMutationData(
      type: VanCoMutation.maToc,
      name: 'Ghost Speed',
      nameVi: 'Ma Tốc',
      description: '+100% speed for 5s, 30s cooldown',
      descriptionVi: '+100% tốc độ trong 5 giây, hồi chiêu 30 giây',
      emoji: '👻',
      rarity: MutationRarity.epic,
      color: Color(0xFF00E5FF),
      speedBonus: 1.0,
      duration: 5.0,
      cooldown: 30.0,
      synergies: [VanCoMutation.tocHanh, VanCoMutation.dashBoost],
    ),

    VanCoMutation.tuTruong: VanCoMutationData(
      type: VanCoMutation.tuTruong,
      name: 'Magnetic Field',
      nameVi: 'Từ Trường',
      description: 'Push small enemies out of 50px radius',
      descriptionVi: 'Đẩy địch nhỏ ra khỏi vùng 50px',
      emoji: '🧲',
      rarity: MutationRarity.epic,
      color: Color(0xFF5C6BC0),
      synergies: [VanCoMutation.gaiNhe, VanCoMutation.thinhGiac],
    ),

    VanCoMutation.hapTinh: VanCoMutationData(
      type: VanCoMutation.hapTinh,
      name: 'Soul Absorb',
      nameVi: 'Hấp Tinh',
      description: 'Kills give 2x size growth',
      descriptionVi: 'Giết địch tăng gấp đôi kích thước',
      emoji: '✨',
      rarity: MutationRarity.epic,
      color: Color(0xFFFFD54F),
      synergies: [VanCoMutation.satKhi, VanCoMutation.xuyenGiap],
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // LEGENDARY MUTATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    VanCoMutation.thoiGianNguoc: VanCoMutationData(
      type: VanCoMutation.thoiGianNguoc,
      name: 'Time Rewind',
      nameVi: 'Thời Gian Ngược',
      description: 'Rewind 5s (position + HP)',
      descriptionVi: 'Quay ngược 5 giây (vị trí + máu)',
      emoji: '⏪',
      rarity: MutationRarity.legendary,
      color: Color(0xFF00ACC1),
      duration: 5.0,
      cooldown: 60.0,
    ),

    VanCoMutation.thienKiep: VanCoMutationData(
      type: VanCoMutation.thienKiep,
      name: 'Heaven\'s Tribulation',
      nameVi: 'Thiên Kiếp',
      description: 'Call lightning on 3 nearest enemies',
      descriptionVi: 'Triệu hồi sét đánh 3 địch gần nhất',
      emoji: '⚡',
      rarity: MutationRarity.legendary,
      color: Color(0xFFFFEB3B),
      cooldown: 45.0,
    ),

    VanCoMutation.coVuongHoa: VanCoMutationData(
      type: VanCoMutation.coVuongHoa,
      name: 'Ancient King Form',
      nameVi: 'Cổ Vương Hóa',
      description: 'Size x2 for 15s',
      descriptionVi: 'Kích thước x2 trong 15 giây',
      emoji: '👑',
      rarity: MutationRarity.legendary,
      color: Color(0xFFFFD700),
      duration: 15.0,
      cooldown: 90.0,
      antiSynergies: [VanCoMutation.phanThan],
    ),

    VanCoMutation.batDiet: VanCoMutationData(
      type: VanCoMutation.batDiet,
      name: 'Invincible',
      nameVi: 'Bất Diệt',
      description: 'Immune to damage for 3s',
      descriptionVi: 'Miễn nhiễm sát thương 3 giây',
      emoji: '🛡️',
      rarity: MutationRarity.legendary,
      color: Color(0xFFE65100),
      duration: 3.0,
      cooldown: 60.0,
    ),

    VanCoMutation.honDon: VanCoMutationData(
      type: VanCoMutation.honDon,
      name: 'Chaos',
      nameVi: 'Hỗn Độn',
      description: 'Swap size with random enemy',
      descriptionVi: 'Hoán đổi kích thước với địch ngẫu nhiên',
      emoji: '🎲',
      rarity: MutationRarity.legendary,
      color: Color(0xFF880E4F),
      cooldown: 120.0,
    ),
  };

  /// Get mutation data
  static VanCoMutationData get(VanCoMutation type) => _data[type]!;

  /// Get all mutations
  static List<VanCoMutationData> get all => _data.values.toList();

  /// Get mutations by rarity
  static List<VanCoMutationData> byRarity(MutationRarity rarity) =>
      _data.values.where((m) => m.rarity == rarity).toList();

  /// Roll random mutations (weighted by rarity)
  static List<VanCoMutation> rollMutations(int count, {List<VanCoMutation>? exclude}) {
    final available = _data.values
        .where((m) => exclude == null || !exclude.contains(m.type))
        .toList();

    if (available.isEmpty || count <= 0) return [];

    final result = <VanCoMutation>[];
    final random = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < count && available.isNotEmpty; i++) {
      // Weighted random selection
      var roll = (random + i * 17) % 10000 / 10000.0;

      VanCoMutationData? selected;
      for (final m in available) {
        roll -= m.rarity.dropRate;
        if (roll <= 0) {
          selected = m;
          break;
        }
      }

      selected ??= available.last;
      result.add(selected.type);
      available.remove(selected);
    }

    return result;
  }

  /// Check if two mutations have synergy
  static bool hasSynergy(VanCoMutation a, VanCoMutation b) {
    final dataA = _data[a]!;
    return dataA.synergies.contains(b);
  }

  /// Check if two mutations are incompatible
  static bool hasAntiSynergy(VanCoMutation a, VanCoMutation b) {
    final dataA = _data[a]!;
    return dataA.antiSynergies.contains(b);
  }

  /// Get all active synergies for a set of mutations
  static List<(VanCoMutation, VanCoMutation)> getActiveSynergies(List<VanCoMutation> mutations) {
    final synergies = <(VanCoMutation, VanCoMutation)>[];
    for (int i = 0; i < mutations.length; i++) {
      for (int j = i + 1; j < mutations.length; j++) {
        if (hasSynergy(mutations[i], mutations[j])) {
          synergies.add((mutations[i], mutations[j]));
        }
      }
    }
    return synergies;
  }
}

/// Extension for mutation helpers
extension VanCoMutationExt on VanCoMutation {
  VanCoMutationData get data => VanCoMutationRegistry.get(this);
  String get nameVi => data.nameVi;
  String get emoji => data.emoji;
  MutationRarity get rarity => data.rarity;
  Color get color => data.color;
}
