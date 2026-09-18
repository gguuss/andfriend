import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MindfulnessCategory {
  hydration(name: 'Hydration', icon: Icons.water_drop, color: Color(0xFF29B6F6)),
  rest(name: 'Fresh Air & Rest', icon: Icons.park, color: Color(0xFF66BB6A)),
  posture(name: 'Posture Check', icon: Icons.accessibility_new, color: Color(0xFFAB47BC)),
  affirmation(name: 'Affirmation & Love', icon: Icons.favorite, color: Color(0xFFEC407A)),
  nightWindDown(name: 'Evening Wind-Down', icon: Icons.bedtime, color: Color(0xFF7E57C2));

  final String name;
  final IconData icon;
  final Color color;

  const MindfulnessCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class MindfulnessQuote {
  final String text;
  final MindfulnessCategory category;
  final IconData icon;

  const MindfulnessQuote({
    required this.text,
    required this.category,
    required this.icon,
  });
}

class MindfulnessBank {
  static const List<MindfulnessQuote> allQuotes = [
    // Hydration
    MindfulnessQuote(
      text: 'Remember to take a refreshing sip of water! Stay hydrated, friend 💧',
      category: MindfulnessCategory.hydration,
      icon: Icons.water_drop,
    ),
    MindfulnessQuote(
      text: 'Water break time! Your brain loves staying well-hydrated 🌊',
      category: MindfulnessCategory.hydration,
      icon: Icons.water_drop,
    ),
    // Rest & Fresh Air
    MindfulnessQuote(
      text: 'You\'ve been focused for a while. Glance out the window for 20 seconds or step outside! 🌿',
      category: MindfulnessCategory.rest,
      icon: Icons.nature_people,
    ),
    MindfulnessQuote(
      text: 'Give your eyes a gentle rest. Look at something far away for a moment 🪟',
      category: MindfulnessCategory.rest,
      icon: Icons.remove_red_eye,
    ),
    MindfulnessQuote(
      text: 'Take a brief stroll or a quick stretch! Fresh air works wonders 🍃',
      category: MindfulnessCategory.rest,
      icon: Icons.park,
    ),
    // Posture
    MindfulnessQuote(
      text: 'Friendly posture check: gently unclench your jaw and drop your shoulders 🧘',
      category: MindfulnessCategory.posture,
      icon: Icons.accessibility_new,
    ),
    MindfulnessQuote(
      text: 'Take a deep breath and straighten your spine. Let tension melt away ✨',
      category: MindfulnessCategory.posture,
      icon: Icons.self_improvement,
    ),
    // Affirmation & Care
    MindfulnessQuote(
      text: 'You are doing great today. I\'m so glad to share a workspace with you! 💖',
      category: MindfulnessCategory.affirmation,
      icon: Icons.favorite,
    ),
    MindfulnessQuote(
      text: 'Never forget: you are valued, capable, and loved! Proud of you ⭐',
      category: MindfulnessCategory.affirmation,
      icon: Icons.stars,
    ),
    MindfulnessQuote(
      text: 'Be gentle with yourself. Every small step forward is wonderful progress 🌱',
      category: MindfulnessCategory.affirmation,
      icon: Icons.eco,
    ),
    // Late night
    MindfulnessQuote(
      text: 'It\'s late, friend! Make sure to get plenty of cozy rest tonight 🌙',
      category: MindfulnessCategory.nightWindDown,
      icon: Icons.bedtime,
    ),
  ];

  static MindfulnessQuote getRandom({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final rng = math.Random();

    // Late night (between 11 PM and 5 AM)
    if (now.hour >= 23 || now.hour < 5) {
      final nightQuotes = allQuotes.where((q) => q.category == MindfulnessCategory.nightWindDown).toList();
      if (nightQuotes.isNotEmpty && rng.nextBool()) {
        return nightQuotes[rng.nextInt(nightQuotes.length)];
      }
    }

    final daylightQuotes = allQuotes.where((q) => q.category != MindfulnessCategory.nightWindDown).toList();
    return daylightQuotes[rng.nextInt(daylightQuotes.length)];
  }
}
