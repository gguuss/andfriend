import 'dart:convert';
import 'package:flutter/material.dart';

enum RoutineCategory {
  health,
  mindfulness,
  focus,
  custom,
}

class RoutineItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final RoutineCategory category;
  bool isCompleted;
  DateTime? completedAt;
  final int xpReward;
  final String companionQuote;
  final bool isCustom;

  RoutineItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.category = RoutineCategory.health,
    this.isCompleted = false,
    this.completedAt,
    this.xpReward = 25,
    required this.companionQuote,
    this.isCustom = false,
  });

  static IconData iconFromId(String id) {
    switch (id) {
      case 'vitamins':
        return Icons.medication;
      case 'morning_water':
        return Icons.water_drop;
      case 'posture_reset':
        return Icons.accessibility_new;
      case 'nourishing_lunch':
        return Icons.restaurant;
      case 'eye_rest':
        return Icons.remove_red_eye;
      case 'evening_winddown':
        return Icons.nightlight_round;
      default:
        return Icons.task_alt;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'category': category.name,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'xpReward': xpReward,
    'companionQuote': companionQuote,
    'isCustom': isCustom,
  };

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return RoutineItem(
      id: id,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      icon: iconFromId(id),
      category: RoutineCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => RoutineCategory.health,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
      xpReward: json['xpReward'] as int? ?? 25,
      companionQuote: json['companionQuote'] as String? ?? 'Great job on your routine! ⭐',
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

class DailyRoutineTracker {
  List<RoutineItem> items;
  DateTime lastCheckedDate;
  int currentStreak;
  int bestStreak;
  DateTime? lastStreakUpdateDate;

  DailyRoutineTracker({
    List<RoutineItem>? items,
    DateTime? lastCheckedDate,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastStreakUpdateDate,
  })  : items = items ?? defaultItems(),
        lastCheckedDate = lastCheckedDate ?? DateTime.now();

  static List<RoutineItem> defaultItems() {
    return [
      RoutineItem(
        id: 'vitamins',
        title: 'Eat Daily Vitamins',
        subtitle: 'Fuel your body & mind with daily vitamins or medicine 💊',
        icon: Icons.medication,
        category: RoutineCategory.health,
        xpReward: 35,
        companionQuote: 'Yay! Vitamins taken! Super healthy and energized! 💊✨',
      ),
      RoutineItem(
        id: 'morning_water',
        title: 'Morning Hydration',
        subtitle: 'Drink a crisp, refreshing glass of water 💧',
        icon: Icons.water_drop,
        category: RoutineCategory.health,
        xpReward: 20,
        companionQuote: 'Glug glug! Refreshed and hydrated together! 💧',
      ),
      RoutineItem(
        id: 'posture_reset',
        title: 'Posture & Spine Reset',
        subtitle: 'Drop shoulders, unclench jaw, sit up tall 🧘',
        icon: Icons.accessibility_new,
        category: RoutineCategory.mindfulness,
        xpReward: 20,
        companionQuote: 'Shoulders dropped, jaw relaxed. Feeling balanced! ✨',
      ),
      RoutineItem(
        id: 'nourishing_lunch',
        title: 'Nourishing Meal Break',
        subtitle: 'Step away from your screen for a wholesome meal 🥗',
        icon: Icons.restaurant,
        category: RoutineCategory.health,
        xpReward: 25,
        companionQuote: 'Mmm, delicious fuel for your wonderful brain! 🥗',
      ),
      RoutineItem(
        id: 'eye_rest',
        title: '20-20-20 Eye Rest',
        subtitle: 'Glance 20 feet away for 20 seconds to rest your eyes 🪟',
        icon: Icons.remove_red_eye,
        category: RoutineCategory.mindfulness,
        xpReward: 20,
        companionQuote: 'Resting eyes means clear sight and sharp focus! 🌿',
      ),
      RoutineItem(
        id: 'evening_winddown',
        title: 'Evening Wind-Down',
        subtitle: 'Reflect on one positive moment and prepare for rest 🌙',
        icon: Icons.nightlight_round,
        category: RoutineCategory.mindfulness,
        xpReward: 30,
        companionQuote: 'You worked hard today. I\'m so proud of you! Sleep cozy 🌙',
      ),
    ];
  }

  void checkDayRollover({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final isNewDay = now.year != lastCheckedDate.year ||
        now.month != lastCheckedDate.month ||
        now.day != lastCheckedDate.day;

    if (!isNewDay) return;

    // Check if the previous day qualified for streak continuation
    final wasCompletedYesterday = completedCount >= 1;
    final dayDiff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastCheckedDate.year, lastCheckedDate.month, lastCheckedDate.day))
        .inDays;

    if (dayDiff > 1 && !wasCompletedYesterday) {
      // Skipped more than a day without completing
      currentStreak = 0;
    }

    // Reset daily completion for the new day
    for (final item in items) {
      item.isCompleted = false;
      item.completedAt = null;
    }
    lastCheckedDate = now;
  }

  bool completeItem(String id, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    checkDayRollover(currentTime: now);

    final item = items.firstWhere((i) => i.id == id, orElse: () => throw ArgumentError('Item not found'));
    if (item.isCompleted) return false;

    item.isCompleted = true;
    item.completedAt = now;

    // Update streak if this is the first item completed today
    final today = DateTime(now.year, now.month, now.day);
    if (lastStreakUpdateDate == null ||
        DateTime(lastStreakUpdateDate!.year, lastStreakUpdateDate!.month, lastStreakUpdateDate!.day) != today) {
      currentStreak += 1;
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }
      lastStreakUpdateDate = now;
    }

    return true;
  }

  bool uncompleteItem(String id) {
    final item = items.firstWhere((i) => i.id == id, orElse: () => throw ArgumentError('Item not found'));
    if (!item.isCompleted) return false;

    item.isCompleted = false;
    item.completedAt = null;
    return true;
  }

  void addCustomItem({
    required String title,
    String subtitle = '',
    IconData icon = Icons.task_alt,
    int xpReward = 20,
    String companionQuote = 'Awesome! Checked off your custom goal! ⭐',
  }) {
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    items.add(RoutineItem(
      id: newId,
      title: title,
      subtitle: subtitle,
      icon: icon,
      category: RoutineCategory.custom,
      xpReward: xpReward,
      companionQuote: companionQuote,
      isCustom: true,
    ));
  }

  bool removeCustomItem(String id) {
    final index = items.indexWhere((i) => i.id == id && i.isCustom);
    if (index == -1) return false;
    items.removeAt(index);
    return true;
  }

  int get completedCount => items.where((i) => i.isCompleted).length;
  int get totalCount => items.length;
  double get progressRatio => totalCount == 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);
  bool get allCompleted => totalCount > 0 && completedCount == totalCount;
  bool get isVitaminsCompleted => items.any((i) => i.id == 'vitamins' && i.isCompleted);

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    'lastCheckedDate': lastCheckedDate.toIso8601String(),
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'lastStreakUpdateDate': lastStreakUpdateDate?.toIso8601String(),
  };

  factory DailyRoutineTracker.fromJson(Map<String, dynamic> json) {
    return DailyRoutineTracker(
      items: json['items'] != null
          ? (json['items'] as List).map((i) => RoutineItem.fromJson(Map<String, dynamic>.from(i as Map))).toList()
          : defaultItems(),
      lastCheckedDate: json['lastCheckedDate'] != null
          ? DateTime.tryParse(json['lastCheckedDate'] as String)
          : null,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastStreakUpdateDate: json['lastStreakUpdateDate'] != null
          ? DateTime.tryParse(json['lastStreakUpdateDate'] as String)
          : null,
    );
  }

  String serialize() => jsonEncode(toJson());

  static DailyRoutineTracker deserialize(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DailyRoutineTracker.fromJson(decoded);
    } catch (_) {
      return DailyRoutineTracker();
    }
  }
}
