import 'dart:math' as math;
import 'package:flutter/material.dart';

enum PetMood {
  idle,
  wandering,
  eating,
  sleeping,
  tickled,
  digging,
  burrowSniffing,
  peekingBurrow,
  performingTrick,
  sniffing,
  happy,
}

enum BurrowEdge {
  bottom,
  left,
  right,
}

enum BurrowCorner {
  bottomLeft,
  bottomRight,
}

enum SnackType {
  berry(name: 'Wild Berry', hungerRestore: 20, happinessBoost: 10, icon: Icons.grass, color: Color(0xFFE74C3C)),
  fish(name: 'Golden Fish', hungerRestore: 35, happinessBoost: 15, icon: Icons.set_meal, color: Color(0xFF3498DB)),
  dumpling(name: 'Warm Dumpling', hungerRestore: 50, happinessBoost: 25, icon: Icons.bakery_dining, color: Color(0xFFF39C12)),
  desktopCookie(name: 'File Cookie', hungerRestore: 40, happinessBoost: 30, icon: Icons.insert_drive_file, color: Color(0xFF9B59B6));

  final String name;
  final double hungerRestore;
  final double happinessBoost;
  final IconData icon;
  final Color color;

  const SnackType({
    required this.name,
    required this.hungerRestore,
    required this.happinessBoost,
    required this.icon,
    required this.color,
  });
}

class IncomingSnack {
  final SnackType snack;
  final Offset startPosition;
  final Offset targetPosition;
  final double durationSeconds;
  double elapsedSeconds = 0.0;
  double rotation = 0.0;

  IncomingSnack({
    required this.snack,
    required this.startPosition,
    required this.targetPosition,
    this.durationSeconds = 0.85,
  });

  double get progress => (elapsedSeconds / durationSeconds).clamp(0.0, 1.0);

  bool get isFinished => elapsedSeconds >= durationSeconds;

  Offset get currentPosition {
    final t = progress;
    // Parabolic arc interpolation:
    // Linear in X, arc in Y with apex lift
    final x = startPosition.dx + (targetPosition.dx - startPosition.dx) * t;
    final linearY = startPosition.dy + (targetPosition.dy - startPosition.dy) * t;
    // Parabolic arc: 4 * t * (1 - t) peaks at 1.0 when t = 0.5
    final arcOffset = (startPosition.dy < 50) ? 0.0 : -math.sin(t * math.pi) * 120.0;
    return Offset(x, linearY + arcOffset);
  }

  void update(double dt) {
    elapsedSeconds += dt;
    rotation += dt * 5.0; // Tumbling spin
  }
}

class PetVitals {
  double hunger; // 0 (starving) to 100 (full)
  double energy; // 0 (exhausted) to 100 (energetic)
  double happiness; // 0 (sad) to 100 (ecstatic)
  double affection; // 0 to 100 (bond level)
  int level;
  int currentXp;
  int get xp => currentXp;

  PetVitals({
    this.hunger = 80.0,
    this.energy = 85.0,
    this.happiness = 90.0,
    this.affection = 70.0,
    this.level = 1,
    this.currentXp = 0,
  });

  void feed(double amount) {
    hunger = (hunger + amount).clamp(0.0, 100.0);
    happiness = (happiness + (amount * 0.3)).clamp(0.0, 100.0);
    affection = (affection + 2.0).clamp(0.0, 100.0);
  }

  void sleepTick(double amount) {
    energy = (energy + amount).clamp(0.0, 100.0);
    if (energy > 95.0) {
      happiness = (happiness + 5.0).clamp(0.0, 100.0);
    }
  }

  void tickle() {
    happiness = (happiness + 5.0).clamp(0.0, 100.0);
    affection = (affection + 3.0).clamp(0.0, 100.0);
  }

  void gainXp(int xp) {
    currentXp += xp;
    final needed = level * 100;
    if (currentXp >= needed) {
      currentXp -= needed;
      level++;
      happiness = 100.0;
    }
  }

  void decay(double deltaSeconds) {
    // Hunger decays gradually
    hunger = (hunger - (deltaSeconds * 0.25)).clamp(0.0, 100.0);
    // Energy decays with activity
    energy = (energy - (deltaSeconds * 0.15)).clamp(0.0, 100.0);
    // If hungry or tired, happiness decays faster
    if (hunger < 30 || energy < 20) {
      happiness = (happiness - (deltaSeconds * 0.4)).clamp(0.0, 100.0);
    } else {
      happiness = (happiness - (deltaSeconds * 0.1)).clamp(0.0, 100.0);
    }
  }

  Map<String, dynamic> toJson() => {
        'hunger': hunger,
        'energy': energy,
        'happiness': happiness,
        'affection': affection,
        'level': level,
        'currentXp': currentXp,
      };

  factory PetVitals.fromJson(Map<String, dynamic> json) => PetVitals(
        hunger: (json['hunger'] as num?)?.toDouble() ?? 80.0,
        energy: (json['energy'] as num?)?.toDouble() ?? 85.0,
        happiness: (json['happiness'] as num?)?.toDouble() ?? 90.0,
        affection: (json['affection'] as num?)?.toDouble() ?? 70.0,
        level: json['level'] as int? ?? 1,
        currentXp: json['currentXp'] as int? ?? 0,
      );
}

enum HaltType {
  hungry,
  angry,
  lonely,
  tired;

  String get title {
    switch (this) {
      case HaltType.hungry:
        return 'Hydration & Fuel';
      case HaltType.angry:
        return 'Emotional Reset';
      case HaltType.lonely:
        return 'Connection';
      case HaltType.tired:
        return 'Pacing & Rest';
    }
  }

  String get prompt => promptText;

  String get promptText {
    switch (this) {
      case HaltType.hungry:
        return 'Nourish check! How about a sip of water or a nourishing snack? 💧✨';
      case HaltType.angry:
        return 'Feeling tense or overwhelmed? Let\'s take a slow deep breath together. 🌿💚';
      case HaltType.lonely:
        return 'I\'m right here with you! Sending a cozy warm thought. 🐾💖';
      case HaltType.tired:
        return 'Rest is productive. How about a gentle 2-minute rest? 🌙✨';
    }
  }

  IconData get icon {
    switch (this) {
      case HaltType.hungry:
        return Icons.water_drop;
      case HaltType.angry:
        return Icons.air;
      case HaltType.lonely:
        return Icons.favorite;
      case HaltType.tired:
        return Icons.bedtime;
    }
  }
}

class ThoughtBubble {
  final String text;
  final IconData? icon;
  final DateTime createdAt;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final HaltType? haltType;

  ThoughtBubble({
    required this.text,
    this.icon,
    required this.duration,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.haltType,
  }) : createdAt = DateTime.now();

  bool get isActionable => actionLabel != null;

  bool get isExpired => DateTime.now().difference(createdAt) > duration;
}
