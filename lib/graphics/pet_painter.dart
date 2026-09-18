import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/companion_model.dart';
import '../models/pet_state.dart';
import 'particle.dart';

class PetPainter extends CustomPainter {
  final CompanionModel companion;
  final PetMood mood;
  final double animationTime;
  final Offset gazeOffset; // Normalized [-1.0, 1.0]
  final double gazeDistance;
  final double trickProgress; // 0.0 to 1.0
  final String? activeTrickId;
  final List<Particle> particles;
  final Offset? burrowPosition;
  final bool hasBurrow;
  final BurrowEdge burrowEdge;
  final ui.Image? customImage;
  final bool drawMascot;
  final IncomingSnack? incomingSnack;

  PetPainter({
    required this.companion,
    required this.mood,
    required this.animationTime,
    required this.gazeOffset,
    required this.gazeDistance,
    required this.trickProgress,
    required this.activeTrickId,
    required this.particles,
    required this.hasBurrow,
    this.burrowEdge = BurrowEdge.bottom,
    this.burrowPosition,
    this.customImage,
    this.drawMascot = true,
    this.incomingSnack,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Burrow Mound right where the friend dug it
    if (hasBurrow && burrowPosition != null) {
      _drawBurrowMound(canvas, burrowPosition!);
    }

    // 2. Draw Particles (underneath or around)
    _drawParticles(canvas);

    // 3. Draw Incoming Flying Snack (from sky or tossed from hand)
    if (incomingSnack != null) {
      _drawIncomingSnack(canvas, incomingSnack!);
    }

    // If this painter is only responsible for world effects (burrow & particles), skip mascot
    if (!drawMascot) return;

    // If pet is peeking inside burrow, adjust position
    final center = Offset(size.width / 2, size.height * 0.65);

    canvas.save();

    // 3. Apply animation transforms (tricks, breathing, walking, hopping)
    _applyTransforms(canvas, center);

    // 4. Occlusion layer: When tucked in the burrow, strictly clip away
    // the body, belly, paws, tail, wings, and lower head so only the ears/horns peek out!
    if (mood == PetMood.peekingBurrow) {
      canvas.clipRect(Rect.fromLTRB(
        center.dx - 80,
        0,
        center.dx + 80,
        center.dy + 6,
      ));
    }

    // 5. Draw Mascot Body by Archetype
    if (companion.archetype == CompanionArchetype.customSprite && customImage != null) {
      _drawCustomSprite(canvas, center);
    } else {
      switch (companion.archetype) {
        case CompanionArchetype.cat:
          _drawCat(canvas, center);
          break;
        case CompanionArchetype.fox:
          _drawFox(canvas, center);
          break;
        case CompanionArchetype.bunny:
          _drawBunny(canvas, center);
          break;
        case CompanionArchetype.shiba:
          _drawShiba(canvas, center);
          break;
        case CompanionArchetype.dragon:
          _drawDragon(canvas, center);
          break;
        case CompanionArchetype.slime:
          _drawSlime(canvas, center);
          break;
        case CompanionArchetype.customSprite:
          _drawSlime(canvas, center); // Fallback if image not yet loaded
          break;
      }
    }

    // 6. Draw Eyes & Facial Expressions (gaze tracking!)
    _drawFaceAndEyes(canvas, center);

    // 7. Draw Accessory
    _drawAccessory(canvas, center);

    canvas.restore();
  }

  void _applyTransforms(Canvas canvas, Offset center) {
    canvas.translate(center.dx, center.dy);

    // Trick-specific transforms
    if (mood == PetMood.performingTrick && activeTrickId != null) {
      if (activeTrickId == 'backflip') {
        // 360 degree backflip with jump parabola
        final angle = -trickProgress * 2 * math.pi;
        final jumpY = -math.sin(trickProgress * math.pi) * 70.0;
        canvas.translate(0, jumpY);
        canvas.rotate(angle);
      } else if (activeTrickId == 'spin') {
        // High speed spin with horizontal scaling squash
        final spinAngle = trickProgress * 6 * math.pi;
        final scaleX = math.cos(spinAngle);
        canvas.scale(scaleX, 1.0);
      } else if (activeTrickId == 'playDead') {
        // Dramatic flop onto back
        final flopAngle = (trickProgress * 1.5).clamp(0.0, 1.0) * (math.pi / 2);
        canvas.rotate(flopAngle);
        canvas.translate(0, 20.0 * (trickProgress * 2).clamp(0.0, 1.0));
      } else if (activeTrickId == 'beg') {
        // Upright posture with gentle paw bobbing
        canvas.translate(0, -15.0 + math.sin(animationTime * 6) * 4.0);
      } else if (activeTrickId == 'dance') {
        // Rhythmic side-to-side groove
        final bopAngle = math.sin(animationTime * 8) * 0.18;
        final bopY = -math.sin(animationTime * 16).abs() * 8.0;
        canvas.translate(0, bopY);
        canvas.rotate(bopAngle);
      } else if (activeTrickId == 'highFive') {
        final reach = math.sin(trickProgress * math.pi);
        canvas.translate(reach * 20.0, -reach * 15.0);
      }
    } else if (mood == PetMood.sleeping) {
      // Gentle rhythmic breathing
      final breath = math.sin(animationTime * 2.0) * 0.04;
      canvas.scale(1.0 + breath, 1.0 - breath);
      canvas.translate(0, 10);
    } else if (mood == PetMood.digging) {
      // Rapid vibrating dig animation
      final digShake = math.sin(animationTime * 25.0) * 3.0;
      final digPitch = math.cos(animationTime * 20.0) * 0.15;
      canvas.translate(digShake, 15);
      canvas.rotate(digPitch);
    } else if (mood == PetMood.burrowSniffing) {
      // Orient towards edge burrow hole
      final edgeAngle = switch (burrowEdge) {
        BurrowEdge.bottom => 0.0,
        BurrowEdge.left => math.pi / 2,
        BurrowEdge.right => -math.pi / 2,
      };
      canvas.rotate(edgeAngle);

      // Eager curious sniffing & wiggling around the burrow hole
      final sniffWiggle = math.sin(animationTime * 20.0) * 3.5;
      final sniffDip = (math.sin(animationTime * 14.0).abs()) * 5.0 + 4.0;
      final buttWiggle = math.sin(animationTime * 16.0) * 0.06;
      canvas.translate(sniffWiggle, sniffDip);
      canvas.rotate(buttWiggle);
    } else if (mood == PetMood.peekingBurrow) {
      // Orient according to burrow edge
      final edgeAngle = switch (burrowEdge) {
        BurrowEdge.bottom => 0.0,
        BurrowEdge.left => math.pi / 2,
        BurrowEdge.right => -math.pi / 2,
      };
      canvas.rotate(edgeAngle);

      // Deep, peaceful nap breathing
      final napBreath = math.sin(animationTime * 2.0) * 0.02;
      canvas.scale(1.0 + napBreath, 1.0 - napBreath);
      // Ears stick comfortably right out of the burrow hole rim
      canvas.translate(0, 10);
    } else if (mood == PetMood.wandering) {
      // Walking waddle
      final waddleAngle = math.sin(animationTime * 6.0) * 0.08;
      final hopY = -math.sin(animationTime * 12.0).abs() * 6.0;
      canvas.translate(0, hopY);
      canvas.rotate(waddleAngle);
    } else {
      // Idle organic breathing
      final breath = math.sin(animationTime * 3.0) * 0.02;
      canvas.scale(1.0 + breath, 1.0 - breath);
    }

    canvas.translate(-center.dx, -center.dy);
  }

  // --- DRAW ARCHETYPES ---

  void _drawFox(Canvas canvas, Offset center) {
    final bodyPaint = Paint()..color = companion.primaryColor;
    final bellyPaint = Paint()..color = companion.secondaryColor;
    final accentPaint = Paint()..color = companion.accentColor;

    // Tail (swishing)
    final tailAngle = math.sin(animationTime * 4.0) * 0.25;
    canvas.save();
    canvas.translate(center.dx + 30, center.dy + 15);
    canvas.rotate(tailAngle);
    final tailPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(40, -10, 60, -40, 75, -20)
      ..cubicTo(70, 10, 40, 25, 0, 5);
    canvas.drawPath(tailPath, bodyPaint);

    // White tail tip
    final tipPath = Path()
      ..moveTo(55, -25)
      ..cubicTo(65, -35, 75, -20, 70, -5)
      ..cubicTo(60, 5, 55, 5, 55, -25);
    canvas.drawPath(tipPath, bellyPaint);
    canvas.restore();

    // Large fluffy ears with dark tips (with cute ear wiggles!)
    _drawFluffyEar(
      canvas,
      Offset(center.dx - 32, center.dy - 35),
      isLeft: true,
      wiggle: _calculateEarWiggle(isLeft: true),
    );
    _drawFluffyEar(
      canvas,
      Offset(center.dx + 32, center.dy - 35),
      isLeft: false,
      wiggle: _calculateEarWiggle(isLeft: false),
    );

    // Body & Head (Plump Fox)
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 90, height: 75),
      const Radius.circular(38),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Fluffy white cheeks
    final leftCheek = Path()
      ..moveTo(center.dx - 35, center.dy + 5)
      ..quadraticBezierTo(center.dx - 55, center.dy + 15, center.dx - 30, center.dy + 25)
      ..close();
    canvas.drawPath(leftCheek, bellyPaint);

    final rightCheek = Path()
      ..moveTo(center.dx + 35, center.dy + 5)
      ..quadraticBezierTo(center.dx + 55, center.dy + 15, center.dx + 30, center.dy + 25)
      ..close();
    canvas.drawPath(rightCheek, bellyPaint);

    // Cream Belly
    final bellyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 12), width: 50, height: 42),
      const Radius.circular(22),
    );
    canvas.drawRRect(bellyRRect, bellyPaint);

    // Cute paws
    final pawPaint = Paint()..color = accentPaint.color;
    canvas.drawCircle(Offset(center.dx - 22, center.dy + 35), 8, pawPaint);
    canvas.drawCircle(Offset(center.dx + 22, center.dy + 35), 8, pawPaint);
  }

  double _calculateEarWiggle({required bool isLeft}) {
    // 1. Natural intermittent twitches (animals twitch ears periodically)
    final cycleOffset = isLeft ? 0.0 : 1.7;
    final cycle = (animationTime + cycleOffset) % 3.4;
    double twitch = 0.0;
    if (cycle < 0.32) {
      // Rapid cute double-twitch
      twitch = math.sin(cycle * math.pi * 14.0) * 0.14 * (isLeft ? -1.0 : 1.0);
    }

    // 2. Mood-based dynamic ear movement
    double moodTilt = 0.0;
    if (mood == PetMood.tickled) {
      // Fast happy flutter!
      moodTilt = math.sin(animationTime * 22.0) * 0.22 * (isLeft ? -1.0 : 1.0);
    } else if (mood == PetMood.eating) {
      // Chomping ear rhythm
      moodTilt = math.sin(animationTime * 12.0) * 0.10 * (isLeft ? 1.0 : -1.0);
    } else if (mood == PetMood.sleeping) {
      // Cozy droopy ears
      moodTilt = isLeft ? 0.24 : -0.24;
    } else if (mood == PetMood.burrowSniffing) {
      // Rapid curious twitching as friend investigates the burrow
      moodTilt = math.sin(animationTime * 24.0) * 0.20 * (isLeft ? -1.0 : 1.0);
    } else if (mood == PetMood.peekingBurrow) {
      // Soft cozy ear twitches while tucked in and resting
      moodTilt = math.sin(animationTime * 3.0) * 0.06 * (isLeft ? -1.0 : 1.0);
    } else if (mood == PetMood.wandering) {
      // Bouncing ear bob
      moodTilt = math.sin(animationTime * 8.0) * 0.08 * (isLeft ? -1.0 : 1.0);
    }

    return twitch + moodTilt;
  }

  void _drawFluffyEar(Canvas canvas, Offset earBase, {required bool isLeft, double wiggle = 0.0}) {
    final earPaint = Paint()..color = companion.primaryColor;
    final innerPaint = Paint()..color = companion.secondaryColor;
    final tipPaint = Paint()..color = companion.accentColor;

    final sign = isLeft ? -1.0 : 1.0;

    canvas.save();
    canvas.translate(earBase.dx, earBase.dy);
    canvas.rotate(wiggle);

    final path = Path()
      ..moveTo(-10 * sign, 5)
      ..lineTo(12 * sign, -32)
      ..lineTo(20 * sign, 8)
      ..close();
    canvas.drawPath(path, earPaint);

    // Dark tip
    final tipPath = Path()
      ..moveTo(5 * sign, -18)
      ..lineTo(12 * sign, -32)
      ..lineTo(17 * sign, -12)
      ..close();
    canvas.drawPath(tipPath, tipPaint);

    // Inner fluffy tuft
    final innerPath = Path()
      ..moveTo(-2 * sign, 2)
      ..lineTo(10 * sign, -18)
      ..lineTo(15 * sign, 4)
      ..close();
    canvas.drawPath(innerPath, innerPaint);

    canvas.restore();
  }

  void _drawCat(Canvas canvas, Offset center) {
    final bodyPaint = Paint()..color = companion.primaryColor;
    final bellyPaint = Paint()..color = companion.secondaryColor;

    // Tail (curled up feline tail)
    final tailWag = math.sin(animationTime * 4.5) * 0.2;
    canvas.save();
    canvas.translate(center.dx + 30, center.dy + 15);
    canvas.rotate(tailWag);
    final tailPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(25, -5, 35, -45, 20, -50)
      ..cubicTo(12, -45, 18, -15, 0, 5);
    canvas.drawPath(tailPath, bodyPaint);
    canvas.restore();

    // Pointed cat ears with cute wiggle
    final earPaint = Paint()..color = companion.primaryColor;
    final innerEarPaint = Paint()..color = const Color(0xFFFFB6C1); // Soft pink

    void drawEar(double dx, bool left) {
      final sign = left ? -1.0 : 1.0;
      final wiggle = _calculateEarWiggle(isLeft: left);
      canvas.save();
      canvas.translate(dx, center.dy - 20);
      canvas.rotate(wiggle);

      final path = Path()
        ..moveTo(-12 * sign, -5)
        ..lineTo(5 * sign, -35)
        ..lineTo(18 * sign, 0)
        ..close();
      canvas.drawPath(path, earPaint);

      final inner = Path()
        ..moveTo(-5 * sign, -5)
        ..lineTo(5 * sign, -25)
        ..lineTo(13 * sign, -2)
        ..close();
      canvas.drawPath(inner, innerEarPaint);
      canvas.restore();
    }

    drawEar(center.dx - 22, true);
    drawEar(center.dx + 22, false);

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 85, height: 72),
      const Radius.circular(36),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Belly patch
    final bellyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 12), width: 44, height: 38),
      const Radius.circular(20),
    );
    canvas.drawRRect(bellyRect, bellyPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0x88333333)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Left whiskers
    canvas.drawLine(Offset(center.dx - 32, center.dy + 4), Offset(center.dx - 58, center.dy - 2), whiskerPaint);
    canvas.drawLine(Offset(center.dx - 32, center.dy + 10), Offset(center.dx - 58, center.dy + 10), whiskerPaint);
    // Right whiskers
    canvas.drawLine(Offset(center.dx + 32, center.dy + 4), Offset(center.dx + 58, center.dy - 2), whiskerPaint);
    canvas.drawLine(Offset(center.dx + 32, center.dy + 10), Offset(center.dx + 58, center.dy + 10), whiskerPaint);

    // Paws
    final pawPaint = Paint()..color = companion.secondaryColor;
    canvas.drawCircle(Offset(center.dx - 20, center.dy + 34), 8, pawPaint);
    canvas.drawCircle(Offset(center.dx + 20, center.dy + 34), 8, pawPaint);
  }

  void _drawBunny(Canvas canvas, Offset center) {
    final bodyPaint = Paint()..color = companion.primaryColor;
    final bellyPaint = Paint()..color = companion.secondaryColor;
    final innerPaint = Paint()..color = const Color(0xFFFFC0CB);

    // Round cotton tail
    final tailPaint = Paint()..color = companion.secondaryColor;
    canvas.drawCircle(Offset(center.dx + 38, center.dy + 15), 14, tailPaint);

    // Long tall bunny ears with cute twitch and wiggle
    void drawBunnyEar(double xOffset, bool left) {
      final sign = left ? -1.0 : 1.0;
      final wiggle = _calculateEarWiggle(isLeft: left);
      canvas.save();
      canvas.translate(center.dx + xOffset, center.dy - 30);
      canvas.rotate(wiggle + (sign * 0.10));
      final earRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -32), width: 22, height: 65),
        const Radius.circular(11),
      );
      canvas.drawRRect(earRRect, bodyPaint);

      final innerRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -32), width: 12, height: 50),
        const Radius.circular(6),
      );
      canvas.drawRRect(innerRRect, innerPaint);
      canvas.restore();
    }

    drawBunnyEar(-18, true);
    drawBunnyEar(18, false);

    // Round body
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 84, height: 74),
      const Radius.circular(37),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Belly
    final belly = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 10), width: 44, height: 38),
      const Radius.circular(20),
    );
    canvas.drawRRect(belly, bellyPaint);

    // Paws
    canvas.drawCircle(Offset(center.dx - 18, center.dy + 35), 9, tailPaint);
    canvas.drawCircle(Offset(center.dx + 18, center.dy + 35), 9, tailPaint);
  }

  void _drawShiba(Canvas canvas, Offset center) {
    final bodyPaint = Paint()..color = companion.primaryColor;
    final whitePaint = Paint()..color = companion.secondaryColor;

    // Curled tail
    final tailPaint = Paint()..color = companion.primaryColor;
    canvas.save();
    canvas.translate(center.dx + 34, center.dy + 10);
    final tailPath = Path()
      ..addArc(Rect.fromCenter(center: const Offset(0, -10), width: 32, height: 32), 0, math.pi * 1.5);
    canvas.drawPath(tailPath, Paint()..color = tailPaint.color..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round);
    canvas.restore();

    // Alert triangular ears with cute twitch and wiggle
    void drawShibaEar(double xOffset, bool left) {
      final sign = left ? -1.0 : 1.0;
      final wiggle = _calculateEarWiggle(isLeft: left);
      canvas.save();
      canvas.translate(center.dx + xOffset, center.dy - 22);
      canvas.rotate(wiggle);

      final path = Path()
        ..moveTo(-12 * sign, -3)
        ..lineTo(4 * sign, -28)
        ..lineTo(16 * sign, 0)
        ..close();
      canvas.drawPath(path, bodyPaint);

      final inner = Path()
        ..moveTo(-5 * sign, -3)
        ..lineTo(4 * sign, -20)
        ..lineTo(12 * sign, -2)
        ..close();
      canvas.drawPath(inner, whitePaint);
      canvas.restore();
    }
    drawShibaEar(-24, true);
    drawShibaEar(24, false);

    // Body
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 88, height: 75),
      const Radius.circular(37),
    );
    canvas.drawRRect(body, bodyPaint);

    // Shiba Urajiro (white cheeks and muzzle)
    final urajiroPath = Path()
      ..moveTo(center.dx - 38, center.dy + 5)
      ..quadraticBezierTo(center.dx, center.dy + 40, center.dx + 38, center.dy + 5)
      ..quadraticBezierTo(center.dx, center.dy + 15, center.dx - 38, center.dy + 5)
      ..close();
    canvas.drawPath(urajiroPath, whitePaint);

    // Shiba eye brow dots ("Maro")
    canvas.drawCircle(Offset(center.dx - 18, center.dy - 18), 4.5, whitePaint);
    canvas.drawCircle(Offset(center.dx + 18, center.dy - 18), 4.5, whitePaint);

    // Paws
    canvas.drawCircle(Offset(center.dx - 22, center.dy + 35), 8, whitePaint);
    canvas.drawCircle(Offset(center.dx + 22, center.dy + 35), 8, whitePaint);
  }

  void _drawDragon(Canvas canvas, Offset center) {
    final bodyPaint = Paint()..color = companion.primaryColor;
    final bellyPaint = Paint()..color = companion.secondaryColor;
    final hornPaint = Paint()..color = companion.accentColor;

    // Fluttering tiny dragon wings
    final wingFlap = math.sin(animationTime * 12.0) * 0.3;
    void drawWing(bool left) {
      final sign = left ? -1.0 : 1.0;
      canvas.save();
      canvas.translate(center.dx + 28 * sign, center.dy - 5);
      canvas.rotate(wingFlap * sign);
      final wingPath = Path()
        ..moveTo(0, 0)
        ..lineTo(25 * sign, -25)
        ..lineTo(18 * sign, -5)
        ..lineTo(22 * sign, 5)
        ..lineTo(10 * sign, 10)
        ..close();
      canvas.drawPath(wingPath, Paint()..color = companion.accentColor);
      canvas.restore();
    }
    drawWing(true);
    drawWing(false);

    // Dragon tail with spade tip
    final tailPath = Path()
      ..moveTo(center.dx + 30, center.dy + 15)
      ..cubicTo(center.dx + 50, center.dy + 25, center.dx + 65, center.dy, center.dx + 70, center.dy - 15);
    canvas.drawPath(tailPath, Paint()..color = companion.primaryColor..strokeWidth = 14..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // Spade tip
    final spade = Path()
      ..moveTo(center.dx + 70, center.dy - 25)
      ..lineTo(center.dx + 82, center.dy - 15)
      ..lineTo(center.dx + 70, center.dy - 5)
      ..close();
    canvas.drawPath(spade, hornPaint);

    // Curved golden horns with alert twitch
    void drawHorn(double xOffset, bool left) {
      final sign = left ? -1.0 : 1.0;
      final wiggle = _calculateEarWiggle(isLeft: left) * 0.5;
      canvas.save();
      canvas.translate(center.dx + xOffset, center.dy - 22);
      canvas.rotate(wiggle);

      final path = Path()
        ..moveTo(0, -3)
        ..cubicTo(10 * sign, -28, 25 * sign, -23, 20 * sign, -13)
        ..lineTo(12 * sign, 0)
        ..close();
      canvas.drawPath(path, hornPaint);
      canvas.restore();
    }
    drawHorn(-18, true);
    drawHorn(18, false);

    // Plump dragon body
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 88, height: 76),
      const Radius.circular(38),
    );
    canvas.drawRRect(body, bodyPaint);

    // Scaled belly plates
    final belly = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 12), width: 46, height: 40),
      const Radius.circular(22),
    );
    canvas.drawRRect(belly, bellyPaint);

    // Paws
    canvas.drawCircle(Offset(center.dx - 22, center.dy + 35), 8, hornPaint);
    canvas.drawCircle(Offset(center.dx + 22, center.dy + 35), 8, hornPaint);
  }

  void _drawSlime(Canvas canvas, Offset center) {
    final bodyPaint = Paint()..color = companion.primaryColor;

    // Jiggly squishy blob shape
    final jiggle = math.sin(animationTime * 4.0) * 4.0;
    final path = Path()
      ..moveTo(center.dx - 45, center.dy + 25)
      ..cubicTo(center.dx - 48, center.dy - 20 + jiggle, center.dx - 20, center.dy - 45, center.dx, center.dy - 45 + jiggle)
      ..cubicTo(center.dx + 20, center.dy - 45, center.dx + 48, center.dy - 20 + jiggle, center.dx + 45, center.dy + 25)
      ..cubicTo(center.dx + 30, center.dy + 38 - jiggle, center.dx - 30, center.dy + 38 - jiggle, center.dx - 45, center.dy + 25)
      ..close();
    canvas.drawPath(path, bodyPaint);

    // Glossy jelly highlights
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final glossPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(center.dx - 18, center.dy - 22 + jiggle), width: 18, height: 10));
    canvas.drawPath(glossPath, highlightPaint);
  }

  void _drawCustomSprite(Canvas canvas, Offset center) {
    if (customImage != null) {
      final img = customImage!;
      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = Rect.fromCenter(center: center, width: 85, height: 85);
      canvas.drawImageRect(img, src, dst, Paint());
    }
  }

  // --- DRAW FACE, EYES & CURSOR GAZE TRACKING ---

  void _drawFaceAndEyes(Canvas canvas, Offset center) {
    final leftEyeCenter = Offset(center.dx - 18, center.dy - 4);
    final rightEyeCenter = Offset(center.dx + 18, center.dy - 4);

    if (mood == PetMood.sleeping || mood == PetMood.peekingBurrow) {
      // Peaceful closed smiling nap eyes (- -)
      final eyePaint = Paint()
        ..color = companion.eyeColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final leftEye = Path()
        ..moveTo(leftEyeCenter.dx - 9, leftEyeCenter.dy + 2)
        ..quadraticBezierTo(leftEyeCenter.dx, leftEyeCenter.dy - 4, leftEyeCenter.dx + 9, leftEyeCenter.dy + 2);
      canvas.drawPath(leftEye, eyePaint);

      final rightEye = Path()
        ..moveTo(rightEyeCenter.dx - 9, rightEyeCenter.dy + 2)
        ..quadraticBezierTo(rightEyeCenter.dx, rightEyeCenter.dy - 4, rightEyeCenter.dx + 9, rightEyeCenter.dy + 2);
      canvas.drawPath(rightEye, eyePaint);
    } else if (mood == PetMood.burrowSniffing) {
      // Inquisitive sniffing eyes looking down towards burrow entrance with occasional blink
      final blink = (math.sin(animationTime * 8.0) > 0.7);
      if (blink) {
        final eyePaint = Paint()
          ..color = companion.eyeColor
          ..strokeWidth = 2.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(leftEyeCenter.dx - 6, leftEyeCenter.dy + 2), Offset(leftEyeCenter.dx + 6, leftEyeCenter.dy + 2), eyePaint);
        canvas.drawLine(Offset(rightEyeCenter.dx - 6, rightEyeCenter.dy + 2), Offset(rightEyeCenter.dx + 6, rightEyeCenter.dy + 2), eyePaint);
      } else {
        final eyePaint = Paint()..color = companion.eyeColor;
        canvas.drawCircle(Offset(leftEyeCenter.dx, leftEyeCenter.dy + 3), 4.5, eyePaint);
        canvas.drawCircle(Offset(rightEyeCenter.dx, rightEyeCenter.dy + 3), 4.5, eyePaint);
        final twinklePaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(leftEyeCenter.dx - 1.5, leftEyeCenter.dy + 1.5), 1.5, twinklePaint);
        canvas.drawCircle(Offset(rightEyeCenter.dx - 1.5, rightEyeCenter.dy + 1.5), 1.5, twinklePaint);
      }
    } else if (mood == PetMood.tickled) {
      // Joyful squinting arches (^ ^) with blushing cheeks
      final eyePaint = Paint()
        ..color = companion.eyeColor
        ..strokeWidth = 3.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final leftEye = Path()
        ..moveTo(leftEyeCenter.dx - 9, leftEyeCenter.dy + 4)
        ..quadraticBezierTo(leftEyeCenter.dx, leftEyeCenter.dy - 8, leftEyeCenter.dx + 9, leftEyeCenter.dy + 4);
      canvas.drawPath(leftEye, eyePaint);

      final rightEye = Path()
        ..moveTo(rightEyeCenter.dx - 9, rightEyeCenter.dy + 4)
        ..quadraticBezierTo(rightEyeCenter.dx, rightEyeCenter.dy - 8, rightEyeCenter.dx + 9, rightEyeCenter.dy + 4);
      canvas.drawPath(rightEye, eyePaint);

      // Pink blush cheeks
      final blushPaint = Paint()..color = const Color(0xFFFF4081).withValues(alpha: 0.55);
      canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 28, center.dy + 12), width: 16, height: 9), blushPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 28, center.dy + 12), width: 16, height: 9), blushPaint);
    } else if (activeTrickId == 'spin' && mood == PetMood.performingTrick) {
      // Dizzy spirals (@ @)
      _drawSpiralEye(canvas, leftEyeCenter);
      _drawSpiralEye(canvas, rightEyeCenter);
    } else if (activeTrickId == 'playDead' && mood == PetMood.performingTrick) {
      // Faint crosses (x x)
      final xPaint = Paint()
        ..color = companion.eyeColor
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(leftEyeCenter - const Offset(7, 7), leftEyeCenter + const Offset(7, 7), xPaint);
      canvas.drawLine(leftEyeCenter - const Offset(-7, 7), leftEyeCenter + const Offset(-7, 7), xPaint);
      canvas.drawLine(rightEyeCenter - const Offset(7, 7), rightEyeCenter + const Offset(7, 7), xPaint);
      canvas.drawLine(rightEyeCenter - const Offset(-7, 7), rightEyeCenter + const Offset(-7, 7), xPaint);
    } else {
      // NORMAL GAZE-TRACKING EYES!
      // The pupils smoothly shift towards gazeOffset (calculated from cursor)
      final pupilShift = Offset(
        gazeOffset.dx * 4.5,
        gazeOffset.dy * 3.5,
      );

      _drawGazeEye(canvas, leftEyeCenter, pupilShift);
      _drawGazeEye(canvas, rightEyeCenter, pupilShift);

      // Cute little blush
      final subtleBlush = Paint()..color = const Color(0xFFFF69B4).withValues(alpha: 0.28);
      canvas.drawCircle(Offset(center.dx - 26, center.dy + 8), 6, subtleBlush);
      canvas.drawCircle(Offset(center.dx + 26, center.dy + 8), 6, subtleBlush);
    }

    // Cute snout / nose & smile
    _drawSnoutAndMouth(canvas, center);
  }

  void _drawGazeEye(Canvas canvas, Offset eyePos, Offset pupilShift) {
    const eyeRadiusX = 11.0;
    const eyeRadiusY = 13.0;

    // Sclera (White eye background)
    final scleraPaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: eyePos, width: eyeRadiusX * 2, height: eyeRadiusY * 2),
      scleraPaint,
    );

    // Iris & Pupil (moves with cursor gaze)
    final pupilPos = eyePos + pupilShift;
    final irisPaint = Paint()..color = companion.eyeColor;
    canvas.drawOval(
      Rect.fromCenter(center: pupilPos, width: 14, height: 16),
      irisPaint,
    );

    final blackPupilPaint = Paint()..color = const Color(0xFF111111);
    canvas.drawCircle(pupilPos, 4.5, blackPupilPaint);

    // Catchlight reflections (shiny anime glint)
    final shinePos = pupilPos + const Offset(-2.8, -3.5);
    canvas.drawCircle(shinePos, 2.6, Paint()..color = Colors.white);
    canvas.drawCircle(pupilPos + const Offset(2.2, 2.8), 1.2, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  void _drawSpiralEye(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = companion.eyeColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (double theta = 0; theta < 4 * math.pi; theta += 0.2) {
      final r = theta * 1.0;
      final x = center.dx + r * math.cos(theta + animationTime * 10);
      final y = center.dy + r * math.sin(theta + animationTime * 10);
      if (theta == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawSnoutAndMouth(Canvas canvas, Offset center) {
    final noseCenter = Offset(center.dx, center.dy + 8);
    final darkPaint = Paint()..color = const Color(0xFF222222);

    // Tiny button nose
    canvas.drawOval(
      Rect.fromCenter(center: noseCenter, width: 6.5, height: 4.5),
      darkPaint,
    );

    // Smile (:3 mouth)
    final mouthPaint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(noseCenter.dx - 8, noseCenter.dy + 7)
      ..quadraticBezierTo(noseCenter.dx - 4, noseCenter.dy + 12, noseCenter.dx, noseCenter.dy + 7)
      ..quadraticBezierTo(noseCenter.dx + 4, noseCenter.dy + 12, noseCenter.dx + 8, noseCenter.dy + 7);
    canvas.drawPath(mouthPath, mouthPaint);
  }

  // --- DRAW ACCESSORIES ---

  void _drawAccessory(Canvas canvas, Offset center) {
    switch (companion.accessory) {
      case CompanionAccessory.none:
        break;

      case CompanionAccessory.wizardHat:
        final hatPaint = Paint()..color = companion.accessoryColor;
        final brimPath = Path()
          ..addOval(Rect.fromCenter(center: Offset(center.dx, center.dy - 38), width: 65, height: 16));
        canvas.drawPath(brimPath, hatPaint);

        final conePath = Path()
          ..moveTo(center.dx - 22, center.dy - 40)
          ..cubicTo(center.dx - 10, center.dy - 65, center.dx + 15, center.dy - 75, center.dx + 25, center.dy - 85)
          ..cubicTo(center.dx + 10, center.dy - 65, center.dx + 22, center.dy - 45, center.dx + 22, center.dy - 40)
          ..close();
        canvas.drawPath(conePath, hatPaint);

        // Gold star buckle
        _drawStar(canvas, Offset(center.dx + 25, center.dy - 85), 6, const Color(0xFFFFD700));
        break;

      case CompanionAccessory.starBadge:
        _drawStar(canvas, Offset(center.dx - 16, center.dy + 18), 9, companion.accessoryColor);
        break;

      case CompanionAccessory.cozyScarf:
        final scarfPaint = Paint()..color = companion.accessoryColor;
        final scarfRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, center.dy + 26), width: 68, height: 15),
          const Radius.circular(8),
        );
        canvas.drawRRect(scarfRect, scarfPaint);
        // Hanging tail
        final tailRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(center.dx + 12, center.dy + 26, 12, 25),
          const Radius.circular(5),
        );
        canvas.drawRRect(tailRect, scarfPaint);
        break;

      case CompanionAccessory.coolGlasses:
        final framePaint = Paint()
          ..color = companion.accessoryColor
          ..style = PaintingStyle.fill;
        final leftLens = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx - 18, center.dy - 4), width: 22, height: 18),
          const Radius.circular(5),
        );
        final rightLens = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx + 18, center.dy - 4), width: 22, height: 18),
          const Radius.circular(5),
        );
        canvas.drawRRect(leftLens, framePaint);
        canvas.drawRRect(rightLens, framePaint);
        // Bridge
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx, center.dy - 4), width: 14, height: 3), framePaint);
        // Lens shine
        final lensShine = Paint()..color = Colors.white.withValues(alpha: 0.45);
        canvas.drawLine(Offset(center.dx - 22, center.dy - 8), Offset(center.dx - 14, center.dy), lensShine);
        canvas.drawLine(Offset(center.dx + 14, center.dy - 8), Offset(center.dx + 22, center.dy), lensShine);
        break;

      case CompanionAccessory.tinyHorns:
        final hornPaint = Paint()..color = companion.accessoryColor;
        void drawHorn(double xOffset, bool left) {
          final sign = left ? -1.0 : 1.0;
          final hornPath = Path()
            ..moveTo(center.dx + xOffset, center.dy - 32)
            ..quadraticBezierTo(center.dx + xOffset + 12 * sign, center.dy - 52, center.dx + xOffset + 18 * sign, center.dy - 48)
            ..lineTo(center.dx + xOffset + 8 * sign, center.dy - 30)
            ..close();
          canvas.drawPath(hornPath, hornPaint);
        }
        drawHorn(-18, true);
        drawHorn(18, false);
        break;

      case CompanionAccessory.sakuraFlower:
        final flowerCenter = Offset(center.dx + 24, center.dy - 28);
        final petalPaint = Paint()..color = companion.accessoryColor;
        for (int i = 0; i < 5; i++) {
          final angle = (i * 2 * math.pi / 5) - math.pi / 2;
          final pX = flowerCenter.dx + math.cos(angle) * 7.0;
          final pY = flowerCenter.dy + math.sin(angle) * 7.0;
          canvas.drawCircle(Offset(pX, pY), 4.5, petalPaint);
        }
        canvas.drawCircle(flowerCenter, 3.0, Paint()..color = const Color(0xFFFFD700));
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = (i % 2 == 0) ? radius : radius * 0.45;
      final angle = (i * math.pi / 5) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // --- DRAW BURROW MOUND ---

  void _drawBurrowMound(Canvas canvas, Offset moundCenter) {
    canvas.save();
    canvas.translate(moundCenter.dx, moundCenter.dy);
    final rotation = switch (burrowEdge) {
      BurrowEdge.bottom => 0.0,
      BurrowEdge.left => math.pi / 2,
      BurrowEdge.right => -math.pi / 2,
    };
    canvas.rotate(rotation);

    // Dark burrow entry hole
    final shadowPaint = Paint()..color = const Color(0xFF1E100D);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -6), width: 74, height: 46),
      shadowPaint,
    );
    final holeBackdrop = Paint()..color = const Color(0xFF2D1B18);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -6), width: 68, height: 40),
      holeBackdrop,
    );

    // Dirt mound
    final dirtPaint = Paint()..color = const Color(0xFF795548);
    final moundPath = Path()
      ..moveTo(-85, 38)
      ..quadraticBezierTo(-80, -22, 0, -44)
      ..quadraticBezierTo(80, -22, 85, 38)
      ..close();
    canvas.drawPath(moundPath, dirtPaint);

    // Shading
    final highlightPaint = Paint()..color = const Color(0xFF8D6E63);
    final highlightPath = Path()
      ..moveTo(-65, 36)
      ..quadraticBezierTo(-60, -12, 0, -32)
      ..quadraticBezierTo(60, -12, 65, 36)
      ..close();
    canvas.drawPath(highlightPath, highlightPaint);

    // Little grass tufts
    final grassPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-52, -5), const Offset(-60, -18), grassPaint);
    canvas.drawLine(const Offset(-49, -5), const Offset(-52, -22), grassPaint);
    canvas.drawLine(const Offset(52, -5), const Offset(60, -18), grassPaint);
    canvas.drawLine(const Offset(49, -5), const Offset(52, -22), grassPaint);
    canvas.drawLine(const Offset(0, -34), const Offset(-4, -46), grassPaint);
    canvas.drawLine(const Offset(3, -34), const Offset(7, -45), grassPaint);

    canvas.restore();
  }

  // --- DRAW INCOMING FLYING SNACK ---

  void _drawIncomingSnack(Canvas canvas, IncomingSnack snackItem) {
    final pos = snackItem.currentPosition;
    final snack = snackItem.snack;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    // If fish, angle along flight path plus slight wriggle
    if (snack == SnackType.fish) {
      final wriggle = math.sin(snackItem.elapsedSeconds * 20.0) * 0.2;
      canvas.rotate(snackItem.rotation * 0.3 + wriggle);
    } else {
      canvas.rotate(snackItem.rotation);
    }

    // Gentle motion speed line / sparkle trailing behind snack
    final trailPaint = Paint()
      ..color = snack.color.withValues(alpha: 0.35)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 15), const Offset(0, 30), trailPaint);

    switch (snack) {
      case SnackType.fish:
        _drawSnackFish(canvas);
        break;
      case SnackType.berry:
        _drawSnackBerry(canvas);
        break;
      case SnackType.dumpling:
        _drawSnackDumpling(canvas);
        break;
      case SnackType.desktopCookie:
        _drawSnackCookie(canvas);
        break;
    }

    canvas.restore();
  }

  void _drawSnackFish(Canvas canvas) {
    // Golden Fish
    final fishPaint = Paint()..color = const Color(0xFFFFB300);
    final finPaint = Paint()..color = const Color(0xFFFFA000);
    final eyePaint = Paint()..color = const Color(0xFF212121);
    final shinePaint = Paint()..color = Colors.white;

    // Body (oval / teardrop)
    final bodyPath = Path()
      ..moveTo(0, -18)
      ..cubicTo(12, -8, 12, 10, 0, 16)
      ..cubicTo(-12, 10, -12, -8, 0, -18)
      ..close();
    canvas.drawPath(bodyPath, fishPaint);

    // Tail fin
    final tailPath = Path()
      ..moveTo(0, 14)
      ..lineTo(-10, 26)
      ..quadraticBezierTo(0, 22, 10, 26)
      ..close();
    canvas.drawPath(tailPath, finPaint);

    // Side pectoral fin
    final finPath = Path()
      ..moveTo(0, 0)
      ..lineTo(8, 4)
      ..lineTo(2, 8)
      ..close();
    canvas.drawPath(finPath, finPaint);

    // Cute eye
    canvas.drawCircle(const Offset(-3, -10), 2.8, eyePaint);
    canvas.drawCircle(const Offset(-3.6, -11), 1.0, shinePaint);
  }

  void _drawSnackBerry(Canvas canvas) {
    // Wild Crimson Berry with green stem & leaf
    final berryPaint = Paint()..color = const Color(0xFFE53935);
    final darkBerry = Paint()..color = const Color(0xFFC62828);
    final stemPaint = Paint()..color = const Color(0xFF43A047)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.7);

    // Berry cluster (plump Strawberry/Raspberry look)
    canvas.drawCircle(const Offset(0, 4), 14, berryPaint);
    canvas.drawCircle(const Offset(-5, 8), 6, darkBerry);
    canvas.drawCircle(const Offset(5, 8), 6, darkBerry);

    // Glossy highlight
    canvas.drawCircle(const Offset(-4, -2), 3.5, shinePaint);

    // Green leafy cap & stem
    canvas.drawLine(const Offset(0, -10), const Offset(0, -17), stemPaint);
    final leaf = Path()
      ..moveTo(0, -10)
      ..quadraticBezierTo(8, -14, 10, -8)
      ..quadraticBezierTo(4, -8, 0, -10)
      ..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF4CAF50));
  }

  void _drawSnackDumpling(Canvas canvas) {
    // Warm Dumpling / Gyoza
    final dumplingPaint = Paint()..color = const Color(0xFFFFF8E1);
    final creasePaint = Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final blushPaint = Paint()..color = const Color(0xFFFFCC80);

    // Crescent folded dumpling shape
    final dumplingPath = Path()
      ..moveTo(-16, 2)
      ..quadraticBezierTo(0, -16, 16, 2)
      ..quadraticBezierTo(0, 14, -16, 2)
      ..close();
    canvas.drawPath(dumplingPath, dumplingPaint);

    // Golden bottom sear
    final searPath = Path()
      ..moveTo(-12, 3)
      ..quadraticBezierTo(0, 13, 12, 3)
      ..quadraticBezierTo(0, 7, -12, 3)
      ..close();
    canvas.drawPath(searPath, blushPaint);

    // Pleated folds along top
    canvas.drawLine(const Offset(-8, -6), const Offset(-8, -1), creasePaint);
    canvas.drawLine(const Offset(0, -8), const Offset(0, -2), creasePaint);
    canvas.drawLine(const Offset(8, -6), const Offset(8, -1), creasePaint);
  }

  void _drawSnackCookie(Canvas canvas) {
    // Desktop File Cookie with chocolate chips
    final cookiePaint = Paint()..color = const Color(0xFFD7CCC8);
    final borderPaint = Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final chipPaint = Paint()..color = const Color(0xFF4E342E);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 26),
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect, cookiePaint);
    canvas.drawRRect(rrect, borderPaint);

    // Chocolate chips
    canvas.drawCircle(const Offset(-4, -4), 2.2, chipPaint);
    canvas.drawCircle(const Offset(4, -2), 2.0, chipPaint);
    canvas.drawCircle(const Offset(-2, 5), 2.4, chipPaint);
    canvas.drawCircle(const Offset(5, 6), 1.8, chipPaint);
  }

  // --- DRAW PARTICLES ---

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withValues(alpha: p.opacity);

      switch (p.type) {
        case ParticleType.heart:
          _drawHeart(canvas, p.position, p.size, paint);
          break;

        case ParticleType.dirt:
        case ParticleType.crumb:
          canvas.drawCircle(p.position, p.size, paint);
          break;

        case ParticleType.zzz:
          _drawZzz(canvas, p.position, p.size, paint);
          break;

        case ParticleType.sparkle:
          _drawStar(canvas, p.position, p.size, p.color.withValues(alpha: p.opacity));
          break;

        case ParticleType.musicNote:
          _drawMusicNote(canvas, p.position, p.size, paint);
          break;

        case ParticleType.waterDrop:
          _drawWaterDrop(canvas, p.position, p.size, paint);
          break;
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset pos, double size, Paint paint) {
    final path = Path();
    final width = size * 1.8;
    final height = size * 1.8;
    path.moveTo(pos.dx, pos.dy + height * 0.25);
    path.cubicTo(pos.dx - width * 0.5, pos.dy - height * 0.3, pos.dx - width * 0.5, pos.dy + height * 0.4, pos.dx, pos.dy + height * 0.85);
    path.cubicTo(pos.dx + width * 0.5, pos.dy + height * 0.4, pos.dx + width * 0.5, pos.dy - height * 0.3, pos.dx, pos.dy + height * 0.25);
    canvas.drawPath(path, paint);
  }

  void _drawZzz(Canvas canvas, Offset pos, double size, Paint paint) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Z',
        style: TextStyle(
          color: paint.color,
          fontSize: size * 1.8,
          fontWeight: FontWeight.bold,
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, pos);
  }

  void _drawMusicNote(Canvas canvas, Offset pos, double size, Paint paint) {
    canvas.drawCircle(pos, size * 0.7, paint);
    canvas.drawLine(pos + Offset(size * 0.7, 0), pos + Offset(size * 0.7, -size * 2), paint..strokeWidth = 2);
    canvas.drawLine(pos + Offset(size * 0.7, -size * 2), pos + Offset(size * 1.5, -size * 1.7), paint..strokeWidth = 2);
  }

  void _drawWaterDrop(Canvas canvas, Offset pos, double size, Paint paint) {
    final dropPath = Path()
      ..moveTo(pos.dx, pos.dy - size * 1.5)
      ..cubicTo(pos.dx + size, pos.dy, pos.dx + size, pos.dy + size, pos.dx, pos.dy + size)
      ..cubicTo(pos.dx - size, pos.dy + size, pos.dx - size, pos.dy, pos.dx, pos.dy - size * 1.5)
      ..close();
    canvas.drawPath(dropPath, paint);

    // Glint
    final glint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(pos.dx - size * 0.3, pos.dy + size * 0.2), size * 0.3, glint);
  }

  @override
  bool shouldRepaint(covariant PetPainter oldDelegate) => true;
}

enum BurrowMoundLayer {
  all,
  background, // Earthen glow and dark entry hole
  foreground, // Front dirt mound and grass tufts
}

class BurrowMoundPainter extends CustomPainter {
  final bool isDragging;
  final BurrowMoundLayer layer;
  final BurrowEdge edge;

  const BurrowMoundPainter({
    this.isDragging = false,
    this.layer = BurrowMoundLayer.all,
    this.edge = BurrowEdge.bottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final moundCenter = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(moundCenter.dx, moundCenter.dy);
    final rotation = switch (edge) {
      BurrowEdge.bottom => 0.0,
      BurrowEdge.left => math.pi / 2,
      BurrowEdge.right => -math.pi / 2,
    };
    canvas.rotate(rotation);

    // Subtle earthen glow when being dragged
    if (isDragging && (layer == BurrowMoundLayer.all || layer == BurrowMoundLayer.background)) {
      final glowPaint = Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(Offset.zero, 65, glowPaint);
    }

    // Background layer: Dark burrow entry hole (where pet crawls in)
    if (layer == BurrowMoundLayer.all || layer == BurrowMoundLayer.background) {
      final shadowPaint = Paint()..color = const Color(0xFF1E100D);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -6), width: 74, height: 46),
        shadowPaint,
      );
      final holeBackdrop = Paint()..color = const Color(0xFF2D1B18);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -6), width: 68, height: 40),
        holeBackdrop,
      );
    }

    // Foreground layer: Dirt mound & front rim overlapping the pet's lower body
    if (layer == BurrowMoundLayer.all || layer == BurrowMoundLayer.foreground) {
      final dirtPaint = Paint()..color = const Color(0xFF795548);
      final moundPath = Path()
        ..moveTo(-85, 38)
        ..quadraticBezierTo(-80, -22, 0, -44)
        ..quadraticBezierTo(80, -22, 85, 38)
        ..close();
      canvas.drawPath(moundPath, dirtPaint);

      // Subtle inner mound shading
      final highlightPaint = Paint()..color = const Color(0xFF8D6E63);
      final highlightPath = Path()
        ..moveTo(-65, 36)
        ..quadraticBezierTo(-60, -12, 0, -32)
        ..quadraticBezierTo(60, -12, 65, 36)
        ..close();
      canvas.drawPath(highlightPath, highlightPaint);

      // Front edge of entry hole cavity rim overlapping the pet's lower body
      final holePaint = Paint()..color = const Color(0xFF3E2723);
      final holePath = Path()
        ..moveTo(-34, -6)
        ..quadraticBezierTo(0, 14, 34, -6)
        ..quadraticBezierTo(0, 4, -34, -6)
        ..close();
      canvas.drawPath(holePath, holePaint);

      // Decorative pebbles on the mound
      final pebblePaint = Paint()..color = const Color(0xFFBCAAA4);
      canvas.drawCircle(const Offset(-48, 22), 3.5, pebblePaint);
      canvas.drawCircle(const Offset(52, 20), 4.0, pebblePaint);
      canvas.drawCircle(const Offset(38, 28), 2.5, pebblePaint);

      // Grass tufts on foreground mound
      final grassPaint = Paint()
        ..color = const Color(0xFF4CAF50)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;
      // Left tuft
      canvas.drawLine(const Offset(-52, -5), const Offset(-60, -18), grassPaint);
      canvas.drawLine(const Offset(-49, -5), const Offset(-52, -22), grassPaint);
      // Right tuft
      canvas.drawLine(const Offset(52, -5), const Offset(60, -18), grassPaint);
      canvas.drawLine(const Offset(49, -5), const Offset(52, -22), grassPaint);
      // Center top tuft
      canvas.drawLine(const Offset(0, -34), const Offset(-4, -46), grassPaint);
      canvas.drawLine(const Offset(3, -34), const Offset(7, -45), grassPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BurrowMoundPainter oldDelegate) =>
      oldDelegate.isDragging != isDragging ||
      oldDelegate.layer != layer ||
      oldDelegate.edge != edge;
}

