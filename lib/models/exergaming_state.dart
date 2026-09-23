import 'dart:convert';
import 'package:flutter/material.dart';

/// Clinical research shows a +20% increase in baseline physical activity
/// when paired with non-punitive virtual pet companion exergaming.
enum StepGoalTier {
  bronze(
    name: 'Bronze Stride',
    stepThreshold: 2500,
    xpReward: 35,
    staminaReward: 15.0,
    icon: Icons.emoji_events_outlined,
    color: Color(0xFFCD7F32),
  ),
  silver(
    name: 'Silver Target (+20% Lift)',
    stepThreshold: 5000,
    xpReward: 75,
    staminaReward: 30.0,
    icon: Icons.military_tech_outlined,
    color: Color(0xFFC0C0C0),
  ),
  gold(
    name: 'Gold Odyssey',
    stepThreshold: 8000,
    xpReward: 150,
    staminaReward: 45.0,
    icon: Icons.workspace_premium,
    color: Color(0xFFFFD700),
  ),
  platinum(
    name: 'Platinum Champion',
    stepThreshold: 10000,
    xpReward: 250,
    staminaReward: 60.0,
    icon: Icons.diamond_outlined,
    color: Color(0xFFE5E4E2),
  );

  final String name;
  final int stepThreshold;
  final int xpReward;
  final double staminaReward;
  final IconData icon;
  final Color color;

  const StepGoalTier({
    required this.name,
    required this.stepThreshold,
    required this.xpReward,
    required this.staminaReward,
    required this.icon,
    required this.color,
  });
}

enum TreasureRarity {
  common('Common', Color(0xFF4CAF50)),
  rare('Rare', Color(0xFF2196F3)),
  legendary('Legendary', Color(0xFFFF9800));

  final String label;
  final Color color;

  const TreasureRarity(this.label, this.color);
}

class BurrowTreasure {
  final String id;
  final String name;
  final String description;
  final TreasureRarity rarity;
  final IconData icon;
  final DateTime unearthedAt;

  const BurrowTreasure({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.icon,
    required this.unearthedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'rarity': rarity.name,
    'iconCode': icon.codePoint,
    'unearthedAt': unearthedAt.toIso8601String(),
  };

  factory BurrowTreasure.fromJson(Map<String, dynamic> json) {
    TreasureRarity rarity = TreasureRarity.common;
    if (json['rarity'] != null) {
      rarity = TreasureRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => TreasureRarity.common,
      );
    }

    final id = json['id'] as String? ?? 'treasure_${DateTime.now().millisecondsSinceEpoch}';
    IconData icon = Icons.auto_awesome;
    for (final item in catalog) {
      if (id.startsWith(item.id)) {
        icon = item.icon;
        break;
      }
    }

    return BurrowTreasure(
      id: id,
      name: json['name'] as String? ?? 'Burrow Treasure',
      description: json['description'] as String? ?? 'Unearthed on a gentle walk.',
      rarity: rarity,
      icon: icon,
      unearthedAt: json['unearthedAt'] != null
          ? DateTime.tryParse(json['unearthedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Catalogs potential treasures the pet unearths during walks
  static List<BurrowTreasure> get catalog => [
    BurrowTreasure(
      id: 'golden_clover',
      name: 'Golden 4-Leaf Clover',
      description: 'Found by your companion tucked along the morning path.',
      rarity: TreasureRarity.rare,
      icon: Icons.eco,
      unearthedAt: DateTime.now(),
    ),
    BurrowTreasure(
      id: 'river_pebble',
      name: 'Glowing River Pebble',
      description: 'Polished smooth by clear streams. Emits a calming aura.',
      rarity: TreasureRarity.common,
      icon: Icons.grain,
      unearthedAt: DateTime.now(),
    ),
    BurrowTreasure(
      id: 'ancient_acorn',
      name: 'Ancient Sunlit Acorn',
      description: 'A prized snack and good luck charm tucked into the burrow.',
      rarity: TreasureRarity.common,
      icon: Icons.park,
      unearthedAt: DateTime.now(),
    ),
    BurrowTreasure(
      id: 'running_shoe_badge',
      name: 'Tiny Running Shoe Pin',
      description: 'Commemorates reaching the clinical +20% activity baseline!',
      rarity: TreasureRarity.legendary,
      icon: Icons.directions_run,
      unearthedAt: DateTime.now(),
    ),
    BurrowTreasure(
      id: 'star_seed',
      name: 'Cosmic Blossom Seed',
      description: 'Ready to plant in the community garden at The Park.',
      rarity: TreasureRarity.rare,
      icon: Icons.flare,
      unearthedAt: DateTime.now(),
    ),
  ];
}

/// Manages daily physical step metrics, stamina buffering, and burrow treasure discoveries.
class DailyExergamingRecord {
  int currentSteps;
  double distanceKm;
  int activeMinutes;
  double estimatedCalories;
  double staminaBuffer; // 0.0 to 100.0 (buffers companion fatigue)
  Set<StepGoalTier> completedTiers;
  List<BurrowTreasure> treasures;
  DateTime lastUpdatedDate;
  Map<String, int> dailyHistory; // 'YYYY-MM-DD' -> steps

  static const int baselineTargetSteps = 5000; // Clinical target

  DailyExergamingRecord({
    this.currentSteps = 0,
    this.distanceKm = 0.0,
    this.activeMinutes = 0,
    this.estimatedCalories = 0.0,
    this.staminaBuffer = 20.0,
    Set<StepGoalTier>? completedTiers,
    List<BurrowTreasure>? treasures,
    DateTime? lastUpdatedDate,
    Map<String, int>? dailyHistory,
  })  : completedTiers = completedTiers ?? <StepGoalTier>{},
        treasures = treasures ?? <BurrowTreasure>[],
        lastUpdatedDate = lastUpdatedDate ?? DateTime.now(),
        dailyHistory = dailyHistory ?? <String, int>{};

  double get targetProgress => (currentSteps / baselineTargetSteps).clamp(0.0, 1.0);

  bool isTierAchieved(StepGoalTier tier) => completedTiers.contains(tier);

  /// Checks and rolls over steps at midnight, preserving history and unearned progress
  void checkDayRollover({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final isSameDay = now.year == lastUpdatedDate.year &&
        now.month == lastUpdatedDate.month &&
        now.day == lastUpdatedDate.day;

    if (!isSameDay) {
      // Archive yesterday's step count
      final dateKey = '${lastUpdatedDate.year}-${lastUpdatedDate.month.toString().padLeft(2, '0')}-${lastUpdatedDate.day.toString().padLeft(2, '0')}';
      dailyHistory[dateKey] = currentSteps;

      // Reset daily counters gently (purely non-punitive)
      currentSteps = 0;
      distanceKm = 0.0;
      activeMinutes = 0;
      estimatedCalories = 0.0;
      completedTiers.clear();
      lastUpdatedDate = now;
    }
  }

  /// Records steps and returns newly unlocked tiers and newly unearthed treasures.
  ({List<StepGoalTier> newTiers, List<BurrowTreasure> newTreasures}) recordSteps(int stepsToAdd) {
    if (stepsToAdd <= 0) {
      return (newTiers: <StepGoalTier>[], newTreasures: <BurrowTreasure>[]);
    }

    checkDayRollover();
    currentSteps += stepsToAdd;

    // Approximate metrics: 1,300 steps ≈ 1 km, ~0.04 kcal/step, 100 steps/min
    distanceKm = double.parse((currentSteps / 1300.0).toStringAsFixed(2));
    estimatedCalories = double.parse((currentSteps * 0.04).toStringAsFixed(1));
    activeMinutes = currentSteps ~/ 100;

    final newTiers = <StepGoalTier>[];
    final newTreasures = <BurrowTreasure>[];

    for (final tier in StepGoalTier.values) {
      if (currentSteps >= tier.stepThreshold && !completedTiers.contains(tier)) {
        completedTiers.add(tier);
        newTiers.add(tier);
        staminaBuffer = (staminaBuffer + tier.staminaReward).clamp(0.0, 100.0);

        // Unearthed treasure roll on tier crossing
        final availableCatalog = BurrowTreasure.catalog;
        final index = (tier.index) % availableCatalog.length;
        final found = availableCatalog[index];
        final freshTreasure = BurrowTreasure(
          id: '${found.id}_${DateTime.now().millisecondsSinceEpoch}',
          name: found.name,
          description: found.description,
          rarity: found.rarity,
          icon: found.icon,
          unearthedAt: DateTime.now(),
        );
        treasures.add(freshTreasure);
        newTreasures.add(freshTreasure);
      }
    }

    lastUpdatedDate = DateTime.now();
    return (newTiers: newTiers, newTreasures: newTreasures);
  }

  String serialize() {
    return jsonEncode({
      'currentSteps': currentSteps,
      'distanceKm': distanceKm,
      'activeMinutes': activeMinutes,
      'estimatedCalories': estimatedCalories,
      'staminaBuffer': staminaBuffer,
      'completedTiers': completedTiers.map((t) => t.name).toList(),
      'treasures': treasures.map((t) => t.toJson()).toList(),
      'lastUpdatedDate': lastUpdatedDate.toIso8601String(),
      'dailyHistory': dailyHistory,
    });
  }

  factory DailyExergamingRecord.deserialize(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final tiers = <StepGoalTier>{};
      if (map['completedTiers'] is List) {
        for (final t in map['completedTiers'] as List) {
          try {
            tiers.add(StepGoalTier.values.firstWhere((val) => val.name == t));
          } catch (_) {}
        }
      }

      final treasures = <BurrowTreasure>[];
      if (map['treasures'] is List) {
        for (final t in map['treasures'] as List) {
          if (t is Map<String, dynamic>) {
            treasures.add(BurrowTreasure.fromJson(t));
          }
        }
      }

      final history = <String, int>{};
      if (map['dailyHistory'] is Map) {
        (map['dailyHistory'] as Map).forEach((k, v) {
          if (v is int) history[k.toString()] = v;
        });
      }

      return DailyExergamingRecord(
        currentSteps: map['currentSteps'] as int? ?? 0,
        distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
        activeMinutes: map['activeMinutes'] as int? ?? 0,
        estimatedCalories: (map['estimatedCalories'] as num?)?.toDouble() ?? 0.0,
        staminaBuffer: (map['staminaBuffer'] as num?)?.toDouble() ?? 20.0,
        completedTiers: tiers,
        treasures: treasures,
        lastUpdatedDate: map['lastUpdatedDate'] != null
            ? DateTime.tryParse(map['lastUpdatedDate'] as String) ?? DateTime.now()
            : DateTime.now(),
        dailyHistory: history,
      );
    } catch (_) {
      return DailyExergamingRecord();
    }
  }
}
