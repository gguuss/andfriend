import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ParticleType {
  heart,
  dirt,
  crumb,
  zzz,
  sparkle,
  musicNote,
  waterDrop,
  confetti,
  partyHat,
  treat,
}

class Particle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  double life;
  final double maxLife;
  final ParticleType type;
  final Color color;
  double rotation;
  final double rotationSpeed;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.maxLife,
    required this.type,
    required this.color,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
  })  : life = maxLife,
        opacity = 1.0;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;

    opacity = (life / maxLife).clamp(0.0, 1.0);
    position += velocity * dt;

    // Apply physics based on particle type
    if (type == ParticleType.dirt || type == ParticleType.crumb || type == ParticleType.waterDrop) {
      velocity = Offset(velocity.dx * 0.98, velocity.dy + 350.0 * dt);
    } else if (type == ParticleType.zzz || type == ParticleType.heart) {
      // Gentle floating oscillation
      velocity = Offset(
        velocity.dx + (math.sin(life * 5.0) * 15.0 * dt),
        velocity.dy,
      );
    } else if (type == ParticleType.confetti) {
      // Fluttering downward drift with gentle sway
      velocity = Offset(
        velocity.dx * 0.96 + (math.sin(life * 8.0) * 45.0 * dt),
        math.min(velocity.dy + 180.0 * dt, 140.0),
      );
      rotation += rotationSpeed * dt;
    } else if (type == ParticleType.partyHat || type == ParticleType.treat) {
      velocity = Offset(velocity.dx * 0.97, velocity.dy + 260.0 * dt);
      rotation += rotationSpeed * dt;
    }

    return true;
  }
}
