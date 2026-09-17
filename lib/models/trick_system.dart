import 'package:flutter/material.dart';

enum TrickMasteryTier {
  novice(name: 'Novice', minXp: 0, stars: 1, color: Color(0xFF95A5A6)),
  apprentice(name: 'Apprentice', minXp: 100, stars: 2, color: Color(0xFF3498DB)),
  master(name: 'Master', minXp: 300, stars: 3, color: Color(0xFFF1C40F));

  final String name;
  final int minXp;
  final int stars;
  final Color color;

  const TrickMasteryTier({
    required this.name,
    required this.minXp,
    required this.stars,
    required this.color,
  });

  static TrickMasteryTier fromXp(int xp) {
    if (xp >= master.minXp) return master;
    if (xp >= apprentice.minXp) return apprentice;
    return novice;
  }
}

class PetTrick {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Duration duration;
  final int energyCost;
  final int xpReward;

  const PetTrick({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.duration,
    this.energyCost = 15,
    this.xpReward = 25,
  });

  static const List<PetTrick> allTricks = [
    PetTrick(
      id: 'backflip',
      name: 'Backflip',
      description: 'A 360° acrobatic backward somersault with sparkle burst!',
      icon: Icons.refresh,
      duration: Duration(milliseconds: 1400),
      energyCost: 15,
      xpReward: 30,
    ),
    PetTrick(
      id: 'spin',
      name: 'Tornado Spin',
      description: 'Spins in rapid circles and gets comically dizzy.',
      icon: Icons.autorenew,
      duration: Duration(milliseconds: 1600),
      energyCost: 12,
      xpReward: 25,
    ),
    PetTrick(
      id: 'playDead',
      name: 'Play Dead',
      description: 'Dramatically flops over playing dead until you give a treat.',
      icon: Icons.hotel,
      duration: Duration(milliseconds: 2500),
      energyCost: 10,
      xpReward: 35,
    ),
    PetTrick(
      id: 'beg',
      name: 'Beg / Sit Pretty',
      description: 'Stands up on hind legs and waves both paws pleadingly.',
      icon: Icons.front_hand,
      duration: Duration(milliseconds: 1800),
      energyCost: 8,
      xpReward: 20,
    ),
    PetTrick(
      id: 'dance',
      name: 'Bop Dance',
      description: 'Grooves side-to-side to a rhythmic beat with music notes.',
      icon: Icons.music_note,
      duration: Duration(milliseconds: 2200),
      energyCost: 14,
      xpReward: 30,
    ),
    PetTrick(
      id: 'highFive',
      name: 'High Five',
      description: 'Leaps up and taps your mouse cursor with its paw!',
      icon: Icons.pan_tool_alt,
      duration: Duration(milliseconds: 1200),
      energyCost: 10,
      xpReward: 25,
    ),
  ];

  static PetTrick? findById(String id) {
    try {
      return allTricks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
