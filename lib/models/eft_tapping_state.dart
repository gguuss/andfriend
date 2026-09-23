import 'package:flutter/material.dart';

/// Clinically validated somatic Emotional Freedom Technique (EFT) meridian points.
/// Used for polyvagal down-regulation and somatic nervous system calming.
enum EftMeridianPoint {
  topOfHead(
    name: 'Top of Head (Crown)',
    clinicalFocus: 'Restores cognitive clarity and breaks cognitive fatigue',
    affirmation: 'My mind is clear, calm, and gentle with itself.',
    icon: Icons.wb_sunny,
    relativeOffset: Offset(0.50, 0.14),
  ),
  eyebrow(
    name: 'Eyebrow Point',
    clinicalFocus: 'Releases mental tension, eye fatigue, and sensory overload',
    affirmation: 'I release tension behind my eyes and allow my thoughts to soften.',
    icon: Icons.visibility,
    relativeOffset: Offset(0.38, 0.32),
  ),
  sideOfEye(
    name: 'Side of Eye Point',
    clinicalFocus: 'Clears emotional frustration and visual strain',
    affirmation: 'I give myself permission to let go of screen strain and hurry.',
    icon: Icons.remove_red_eye,
    relativeOffset: Offset(0.72, 0.36),
  ),
  underEye(
    name: 'Under Eye Point',
    clinicalFocus: 'Grounds somatic anxiety and soothes nervous agitation',
    affirmation: 'I am safe in this moment, grounded and deeply supported.',
    icon: Icons.spa,
    relativeOffset: Offset(0.50, 0.48),
  ),
  collarbone(
    name: 'Collarbone Point',
    clinicalFocus: 'Down-regulates fight-or-flight sympathetic arousal',
    affirmation: 'My nervous system can relax. I am safe to slow down.',
    icon: Icons.favorite,
    relativeOffset: Offset(0.50, 0.76),
  );

  final String name;
  final String clinicalFocus;
  final String affirmation;
  final IconData icon;
  final Offset relativeOffset;

  const EftMeridianPoint({
    required this.name,
    required this.clinicalFocus,
    required this.affirmation,
    required this.icon,
    required this.relativeOffset,
  });
}

/// Manages the state and progress of an interactive EFT Tapping session with your companion.
class EftTappingSession {
  static const int tapsPerPoint = 5;
  static const int totalPoints = 5;
  static const int totalSessionTaps = tapsPerPoint * totalPoints; // 25 taps

  int currentPointIndex = 0;
  int currentPointTapCount = 0;
  int totalTapsRecorded = 0;
  bool isCompleted = false;

  EftMeridianPoint get currentPoint => EftMeridianPoint.values[currentPointIndex];

  double get pointProgress => (currentPointTapCount / tapsPerPoint).clamp(0.0, 1.0);
  double get overallProgress => (totalTapsRecorded / totalSessionTaps).clamp(0.0, 1.0);

  /// Registers a rhythmic tap on the active meridian point.
  /// Returns `true` if this tap completed the active point or entire session.
  bool registerTap() {
    if (isCompleted) return false;

    totalTapsRecorded++;
    currentPointTapCount++;

    if (currentPointTapCount >= tapsPerPoint) {
      if (currentPointIndex < EftMeridianPoint.values.length - 1) {
        currentPointIndex++;
        currentPointTapCount = 0;
        return true;
      } else {
        isCompleted = true;
        return true;
      }
    }

    return false;
  }

  void reset() {
    currentPointIndex = 0;
    currentPointTapCount = 0;
    totalTapsRecorded = 0;
    isCompleted = false;
  }
}
