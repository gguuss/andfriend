import 'package:flutter/material.dart';

/// Clinically validated 5-4-3-2-1 Sensory Grounding Technique endpoints.
/// Used to interrupt catastrophic rumination, acute panic, and sensory overstimulation.
enum GroundingSense {
  sight(
    order: 5,
    name: '5 Things You See',
    shortName: 'See',
    prompt: 'Look around: notice shapes, shadows, colors, or small details in your space.',
    instruction: 'Tap each item as you observe it in your environment.',
    targetCount: 5,
    icon: Icons.visibility,
    color: Color(0xFF64B5F6),
    emoji: '👁️',
  ),
  touch(
    order: 4,
    name: '4 Things You Can Feel',
    shortName: 'Feel',
    prompt: 'Feel your feet on the ground, your posture, your chair, or desk texture.',
    instruction: 'Acknowledge physical sensations connecting you to the room.',
    targetCount: 4,
    icon: Icons.touch_app,
    color: Color(0xFFBA68C8),
    emoji: '✋',
  ),
  hearing(
    order: 3,
    name: '3 Things You Hear',
    shortName: 'Hear',
    prompt: 'Listen closely: keyboard clicks, distant traffic, your breath, or ambient hum.',
    instruction: 'Notice subtle layers of sound around you right now.',
    targetCount: 3,
    icon: Icons.hearing,
    color: Color(0xFF4DB6AC),
    emoji: '👂',
  ),
  smell(
    order: 2,
    name: '2 Things You Smell',
    shortName: 'Smell',
    prompt: 'Inhale gently: notice the air in the room, tea, coffee, paper, or hand lotion.',
    instruction: 'If scents are faint, appreciate the freshness of your breath.',
    targetCount: 2,
    icon: Icons.air,
    color: Color(0xFFFFB74D),
    emoji: '👃',
  ),
  taste(
    order: 1,
    name: '1 Thing You Taste',
    shortName: 'Taste',
    prompt: 'Take a sip of water, or notice the lingering taste of mint, tea, or neutral breath.',
    instruction: 'Anchor your attention inside your mouth for one moment.',
    targetCount: 1,
    icon: Icons.local_cafe,
    color: Color(0xFFE57373),
    emoji: '👅',
  );

  final int order;
  final String name;
  final String shortName;
  final String prompt;
  final String instruction;
  final int targetCount;
  final IconData icon;
  final Color color;
  final String emoji;

  const GroundingSense({
    required this.order,
    required this.name,
    required this.shortName,
    required this.prompt,
    required this.instruction,
    required this.targetCount,
    required this.icon,
    required this.color,
    required this.emoji,
  });
}

/// State container for managing a live 5-4-3-2-1 Sensory Grounding scan.
class GroundingScanSession {
  static const int totalSessionItems = 5 + 4 + 3 + 2 + 1; // 15 total items

  int currentSenseIndex = 0;
  int currentSenseCount = 0;
  int totalAcknowledged = 0;
  bool isCompleted = false;

  GroundingSense get currentSense => GroundingSense.values[currentSenseIndex];

  double get senseProgress => (currentSenseCount / currentSense.targetCount).clamp(0.0, 1.0);
  double get overallProgress => (totalAcknowledged / totalSessionItems).clamp(0.0, 1.0);

  /// Registers an observed sensory item in the active category.
  /// Returns `true` if this item completed the category or the entire session.
  bool registerItem() {
    if (isCompleted) return false;

    totalAcknowledged++;
    currentSenseCount++;

    if (currentSenseCount >= currentSense.targetCount) {
      if (currentSenseIndex < GroundingSense.values.length - 1) {
        currentSenseIndex++;
        currentSenseCount = 0;
        return true;
      } else {
        isCompleted = true;
        return true;
      }
    }

    return false;
  }

  void reset() {
    currentSenseIndex = 0;
    currentSenseCount = 0;
    totalAcknowledged = 0;
    isCompleted = false;
  }
}
