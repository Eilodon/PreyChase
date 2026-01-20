/// Species & Evolutionary Tree System
/// Part of PREY CHAOS - Meta Progression

import 'package:flutter/material.dart';

/// Available playable species
enum Species {
  /// Default - balanced stats, water affinity
  crocodile,
  
  /// Poison specialist - DoT damage, slow but deadly
  komodo,
  
  /// Tank build - high armor, slow, powerful jaws
  alligator,
}

/// Tier progression within each species
enum SpeciesTier {
  /// Starting tier
  hatchling,
  
  /// First evolution (unlock after 10 runs)
  juvenile,
  
  /// Second evolution (unlock after 25 runs)
  adult,
  
  /// Final form (unlock after 50 runs)
  alpha,
}

/// Passive abilities granted by species
enum PassiveAbility {
  // Crocodile passives
  waterAffinity,      // +20% speed in swamp biome
  deathRoll,          // Bonus damage on grabbed prey
  amphibious,         // Can dash through water obstacles
  
  // Komodo passives
  venomBite,          // All attacks apply poison
  patientHunter,      // Bonus damage after not attacking for 3s
  toxicBlood,         // Damage attackers on hit
  
  // Alligator passives
  thickHide,          // -30% damage taken
  crushingJaw,        // Instant kill prey below 20% HP
  unstoppable,        // Cannot be slowed or frozen
}

/// Species tier data
class SpeciesTierData {
  final SpeciesTier tier;
  final String name;
  final String description;
  final int runsRequired;
  final double healthBonus;
  final double damageBonus;
  final double speedBonus;
  final PassiveAbility? unlockedPassive;
  
  const SpeciesTierData({
    required this.tier,
    required this.name,
    required this.description,
    required this.runsRequired,
    this.healthBonus = 0.0,
    this.damageBonus = 0.0,
    this.speedBonus = 0.0,
    this.unlockedPassive,
  });
}

/// Complete species data with evolution tree
class SpeciesData {
  final Species species;
  final String name;
  final String description;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final List<SpeciesTierData> tiers;
  final List<PassiveAbility> passives;
  final double baseHealth;
  final double baseDamage;
  final double baseSpeed;
  
  const SpeciesData({
    required this.species,
    required this.name,
    required this.description,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tiers,
    required this.passives,
    required this.baseHealth,
    required this.baseDamage,
    required this.baseSpeed,
  });
}

/// Species registry with all evolution data
class SpeciesRegistry {
  static const Map<Species, SpeciesData> _species = {
    Species.crocodile: SpeciesData(
      species: Species.crocodile,
      name: 'Crocodile',
      description: 'Balanced hunter. Master of swamp.',
      emoji: '🐊',
      primaryColor: Color(0xFF4CAF50),
      secondaryColor: Color(0xFF2E7D32),
      baseHealth: 100.0,
      baseDamage: 10.0,
      baseSpeed: 200.0,
      passives: [
        PassiveAbility.waterAffinity,
        PassiveAbility.deathRoll,
        PassiveAbility.amphibious,
      ],
      tiers: [
        SpeciesTierData(
          tier: SpeciesTier.hatchling,
          name: 'Swamp Hatchling',
          description: 'Young and eager. The journey begins.',
          runsRequired: 0,
        ),
        SpeciesTierData(
          tier: SpeciesTier.juvenile,
          name: 'River Stalker',
          description: 'Growing stronger. Prey beware.',
          runsRequired: 10,
          healthBonus: 0.1,
          unlockedPassive: PassiveAbility.waterAffinity,
        ),
        SpeciesTierData(
          tier: SpeciesTier.adult,
          name: 'Swamp Dominator',
          description: 'The apex of the wetlands.',
          runsRequired: 25,
          healthBonus: 0.2,
          damageBonus: 0.15,
          unlockedPassive: PassiveAbility.deathRoll,
        ),
        SpeciesTierData(
          tier: SpeciesTier.alpha,
          name: 'Primordial Apex',
          description: 'Ancient terror reborn.',
          runsRequired: 50,
          healthBonus: 0.3,
          damageBonus: 0.25,
          speedBonus: 0.1,
          unlockedPassive: PassiveAbility.amphibious,
        ),
      ],
    ),
    Species.komodo: SpeciesData(
      species: Species.komodo,
      name: 'Komodo Dragon',
      description: 'Patient killer. Poison master.',
      emoji: '🦎',
      primaryColor: Color(0xFF8D6E63),
      secondaryColor: Color(0xFF6D4C41),
      baseHealth: 80.0,
      baseDamage: 8.0,
      baseSpeed: 180.0,
      passives: [
        PassiveAbility.venomBite,
        PassiveAbility.patientHunter,
        PassiveAbility.toxicBlood,
      ],
      tiers: [
        SpeciesTierData(
          tier: SpeciesTier.hatchling,
          name: 'Venomling',
          description: 'Small but already deadly.',
          runsRequired: 0,
        ),
        SpeciesTierData(
          tier: SpeciesTier.juvenile,
          name: 'Toxic Stalker',
          description: 'Venom grows stronger.',
          runsRequired: 10,
          damageBonus: 0.1,
          unlockedPassive: PassiveAbility.venomBite,
        ),
        SpeciesTierData(
          tier: SpeciesTier.adult,
          name: 'Plague Bringer',
          description: 'Death follows in your wake.',
          runsRequired: 25,
          damageBonus: 0.25,
          unlockedPassive: PassiveAbility.patientHunter,
        ),
        SpeciesTierData(
          tier: SpeciesTier.alpha,
          name: 'Dragon of Rot',
          description: 'Legend made flesh. Poison incarnate.',
          runsRequired: 50,
          healthBonus: 0.15,
          damageBonus: 0.4,
          unlockedPassive: PassiveAbility.toxicBlood,
        ),
      ],
    ),
    Species.alligator: SpeciesData(
      species: Species.alligator,
      name: 'Alligator',
      description: 'Unstoppable force. Living tank.',
      emoji: '🐲',
      primaryColor: Color(0xFF37474F),
      secondaryColor: Color(0xFF263238),
      baseHealth: 150.0,
      baseDamage: 15.0,
      baseSpeed: 150.0,
      passives: [
        PassiveAbility.thickHide,
        PassiveAbility.crushingJaw,
        PassiveAbility.unstoppable,
      ],
      tiers: [
        SpeciesTierData(
          tier: SpeciesTier.hatchling,
          name: 'Armored Hatchling',
          description: 'Born tough.',
          runsRequired: 0,
        ),
        SpeciesTierData(
          tier: SpeciesTier.juvenile,
          name: 'Heavy Snapper',
          description: 'Scales hardening.',
          runsRequired: 10,
          healthBonus: 0.15,
          unlockedPassive: PassiveAbility.thickHide,
        ),
        SpeciesTierData(
          tier: SpeciesTier.adult,
          name: 'Ironjaw',
          description: 'Nothing escapes your grip.',
          runsRequired: 25,
          healthBonus: 0.3,
          damageBonus: 0.2,
          unlockedPassive: PassiveAbility.crushingJaw,
        ),
        SpeciesTierData(
          tier: SpeciesTier.alpha,
          name: 'Titanbite',
          description: 'An unstoppable force of nature.',
          runsRequired: 50,
          healthBonus: 0.5,
          damageBonus: 0.3,
          speedBonus: -0.1, // Slower but much tankier
          unlockedPassive: PassiveAbility.unstoppable,
        ),
      ],
    ),
  };
  
  static SpeciesData get(Species species) => _species[species]!;
  
  static List<SpeciesData> get all => _species.values.toList();
  
  static SpeciesTierData getTier(Species species, SpeciesTier tier) =>
      _species[species]!.tiers.firstWhere((t) => t.tier == tier);
  
  static SpeciesTier getTierForRuns(Species species, int totalRuns) {
    final tiers = _species[species]!.tiers.reversed.toList();
    for (final tierData in tiers) {
      if (totalRuns >= tierData.runsRequired) return tierData.tier;
    }
    return SpeciesTier.hatchling;
  }
}
