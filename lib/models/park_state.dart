import 'dart:convert';
import 'package:flutter/material.dart';
import 'companion_model.dart';
import 'exergaming_state.dart';

enum WarmFuzzyType {
  sunbeam(
    label: 'Warm Sunbeam',
    affirmation: 'Sending gentle warmth and sunbeams your way ☀️',
    icon: Icons.wb_sunny,
    color: Colors.amberAccent,
  ),
  flower(
    label: 'Blossom of Care',
    affirmation: 'A blooming flower of kindness for your day 🌸',
    icon: Icons.local_florist,
    color: Colors.pinkAccent,
  ),
  clover(
    label: 'Lucky Clover',
    affirmation: 'Wishing you peaceful luck and calm breathing 🍀',
    icon: Icons.eco,
    color: Colors.lightGreenAccent,
  ),
  star(
    label: 'Guiding Star',
    affirmation: 'You are doing wonderful just by being here ⭐',
    icon: Icons.star,
    color: Colors.cyanAccent,
  ),
  cupOfTea(
    label: 'Cozy Tea Cup',
    affirmation: 'A gentle reminder to pause, breathe, and rest 🍵',
    icon: Icons.emoji_food_beverage,
    color: Colors.orangeAccent,
  );

  final String label;
  final String affirmation;
  final IconData icon;
  final Color color;

  const WarmFuzzyType({
    required this.label,
    required this.affirmation,
    required this.icon,
    required this.color,
  });
}

class ParkCompanion {
  final String peerId;
  final String petName;
  final CompanionArchetype archetype;
  final Color primaryColor;
  final Color accentColor;
  double x;
  double y;
  double targetX;
  double targetY;
  final bool isNpc;
  String? activeThought;
  DateTime? thoughtExpiresAt;

  ParkCompanion({
    required this.peerId,
    required this.petName,
    required this.archetype,
    required this.primaryColor,
    required this.accentColor,
    this.x = 0.5,
    this.y = 0.5,
    double? targetX,
    double? targetY,
    this.isNpc = false,
    this.activeThought,
    this.thoughtExpiresAt,
  })  : targetX = targetX ?? x,
        targetY = targetY ?? y;

  factory ParkCompanion.fromPeerMap(Map<String, dynamic> map, {bool isNpc = false}) {
    CompanionArchetype arch = CompanionArchetype.fox;
    if (map['archetype'] != null) {
      arch = CompanionArchetype.values.firstWhere(
        (a) => a.name == map['archetype'],
        orElse: () => CompanionArchetype.fox,
      );
    }

    final primInt = map['primaryColor'] as int? ?? 0xFFE67E22;
    final accInt = map['accentColor'] as int? ?? 0xFFD35400;

    return ParkCompanion(
      peerId: map['peerId'] as String? ?? 'peer_${DateTime.now().millisecondsSinceEpoch}',
      petName: map['petName'] as String? ?? 'Friend',
      archetype: arch,
      primaryColor: Color(primInt),
      accentColor: Color(accInt),
      x: (map['x'] as num?)?.toDouble() ?? 0.5,
      y: (map['y'] as num?)?.toDouble() ?? 0.5,
      isNpc: isNpc,
    );
  }

  void setThought(String text, {Duration duration = const Duration(seconds: 4)}) {
    activeThought = text;
    thoughtExpiresAt = DateTime.now().add(duration);
  }

  bool get hasActiveThought {
    if (activeThought == null) return false;
    if (thoughtExpiresAt != null && DateTime.now().isAfter(thoughtExpiresAt!)) {
      activeThought = null;
      return false;
    }
    return true;
  }
}

/// Type-safe park protocol events
class ParkMessage {
  final String type;
  final Map<String, dynamic> payload;

  const ParkMessage({required this.type, required this.payload});

  String serialize() => jsonEncode({'type': type, ...payload});

  static ParkMessage? deserialize(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final type = map['type'] as String?;
      if (type == null) return null;
      final payload = Map<String, dynamic>.from(map)..remove('type');
      return ParkMessage(type: type, payload: payload);
    } catch (_) {
      return null;
    }
  }

  static String join({
    required String roomId,
    required String peerId,
    required String petName,
    required String archetype,
    required int primaryColor,
    required int accentColor,
    double x = 0.5,
    double y = 0.5,
  }) {
    return jsonEncode({
      'type': 'join',
      'roomId': roomId,
      'peerId': peerId,
      'petName': petName,
      'archetype': archetype,
      'primaryColor': primaryColor,
      'accentColor': accentColor,
      'x': x,
      'y': y,
    });
  }

  static String move({required double x, required double y}) {
    return jsonEncode({
      'type': 'move',
      'x': x,
      'y': y,
    });
  }

  static String warmFuzzy({
    required String targetPeerId,
    required WarmFuzzyType fuzzyType,
    required String affirmation,
  }) {
    return jsonEncode({
      'type': 'warm_fuzzy',
      'targetPeerId': targetPeerId,
      'fuzzyType': fuzzyType.name,
      'affirmation': affirmation,
    });
  }

  static String gift({
    required String targetPeerId,
    required BurrowTreasure treasure,
  }) {
    return jsonEncode({
      'type': 'gift',
      'targetPeerId': targetPeerId,
      'gift': treasure.toJson(),
    });
  }
}
