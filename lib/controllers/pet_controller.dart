import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/sound_service.dart';
import '../core/desktop_scanner.dart';
import '../graphics/particle.dart';
import '../models/companion_model.dart';
import '../models/mindfulness_state.dart';
import '../models/pet_state.dart';
import '../models/routine_state.dart';
import '../models/trick_system.dart';

class PetController extends ChangeNotifier {
  CompanionModel companion;
  PetVitals vitals;
  DailyRoutineTracker routineTracker;
  PetMood mood = PetMood.idle;

  // Visual & Animation State
  double animationTime = 0.0;
  double trickProgress = 0.0;
  String? activeTrickId;
  Offset? burrowPosition;
  bool hasBurrow = false;
  bool isInsideBurrow = false;
  bool isBurrowDragging = false;

  // Active Pathing / Travel Target (e.g. running to burrow)
  Offset? travelTarget;
  VoidCallback? onTravelArrived;
  double travelSpeed = 460.0;

  ThoughtBubble? thoughtBubble;
  final List<Particle> particles = [];
  IncomingSnack? incomingSnack;

  // Desktop Screen Coordinates & Roaming Physics
  Offset screenPosition = const Offset(800, 600);
  bool isDragging = false;
  double wanderDirection = -1.0;
  double wanderSpeed = 45.0;
  Size screenSize = const Size(1920, 1080);

  // Tickle detection tracking
  Offset? _lastPointerPos;
  DateTime? _lastPointerTime;
  double _accumulatedPetDistance = 0.0;

  // Timers
  Timer? _gameLoopTimer;
  Timer? _decayTimer;
  Timer? _snoreTimer;
  Timer? _autonomousTimer;

  PetController({
    required this.companion,
    PetVitals? vitals,
    DailyRoutineTracker? routineTracker,
  })  : vitals = vitals ?? PetVitals(),
        routineTracker = routineTracker ?? DailyRoutineTracker() {
    _startLoops();
  }

  static Future<PetController> create() async {
    CompanionModel companion = CompanionModel.defaultCompanion();
    PetVitals vitals = PetVitals();
    DailyRoutineTracker routineTracker = DailyRoutineTracker();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('active_companion');
      if (savedData != null) {
        companion = CompanionModel.deserialize(savedData);
      }
      final savedVitals = prefs.getString('pet_vitals');
      if (savedVitals != null) {
        vitals = PetVitals.fromJson(Map<String, dynamic>.from(
          (await SharedPreferences.getInstance()).getString('pet_vitals') != null
              ? (PetVitals.fromJson(Map<String, dynamic>.from(
                  // simple decode
                  {}
                ))).toJson()
              : {}
        ));
      }
      final savedRoutine = prefs.getString('daily_routine_tracker');
      if (savedRoutine != null) {
        routineTracker = DailyRoutineTracker.deserialize(savedRoutine);
      }
      routineTracker.checkDayRollover();
    } catch (_) {}

    return PetController(
      companion: companion,
      vitals: vitals,
      routineTracker: routineTracker,
    );
  }

  void _startLoops() {
    // 60fps Animation Loop (dt ≈ 16ms)
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _update(0.016);
    });

    // Vitals Decay Loop (every 3 seconds)
    _decayTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mood == PetMood.sleeping) {
        vitals.sleepTick(2.0);
      } else {
        vitals.decay(3.0);
      }
      notifyListeners();
    });

    // Autonomous behavior loop (every 12 seconds)
    _autonomousTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _triggerAutonomousBehavior();
    });
  }

  void _update(double dt) {
    animationTime += dt;

    // Update Particles
    particles.removeWhere((p) => !p.update(dt));

    // Update Incoming Snack animation
    if (incomingSnack != null) {
      incomingSnack!.update(dt);
      if (incomingSnack!.isFinished) {
        _onSnackArrived(incomingSnack!.snack);
        incomingSnack = null;
      }
    }

    // Handle Active Travel Target (e.g. running across desktop to burrow)
    if (travelTarget != null && !isDragging) {
      final diff = travelTarget! - screenPosition;
      final dist = diff.distance;
      if (dist <= 14.0) {
        screenPosition = travelTarget!;
        final callback = onTravelArrived;
        travelTarget = null;
        onTravelArrived = null;
        callback?.call();
      } else {
        wanderDirection = diff.dx.sign;
        if (wanderDirection == 0) wanderDirection = 1.0;
        final step = travelSpeed * dt;
        screenPosition = screenPosition + (diff / dist) * math.min(step, dist);
      }
      notifyListeners();
      return;
    }

    // Handle Active Trick Progress
    if (mood == PetMood.performingTrick && activeTrickId != null) {
      final trick = PetTrick.findById(activeTrickId!);
      if (trick != null) {
        trickProgress += dt / (trick.duration.inMilliseconds / 1000.0);
        if (trickProgress >= 1.0) {
          _completeTrick(trick);
        }
      } else {
        mood = PetMood.idle;
      }
    }

    // Handle Wandering along desktop
    if (mood == PetMood.wandering && !isDragging) {
      final nextX = screenPosition.dx + (wanderDirection * wanderSpeed * dt);
      if (nextX <= minXMargin || nextX >= screenSize.width - maxXMargin) {
        wanderDirection = -wanderDirection;
      }
      screenPosition = clampPositionToBounds(Offset(nextX, screenPosition.dy));
    }

    // Check thought bubble expiry
    if (thoughtBubble != null && thoughtBubble!.isExpired) {
      thoughtBubble = null;
    }

    notifyListeners();
  }

  // Mascot bounding constraints:
  // Center is at (width/2, height*0.65) = (100, 130) within a 200x200 box.
  // Paws extend downwards to center.dy + 35 = 165px (leaving 35px bottom margin).
  // Digging and peeking burrow adds up to 30px downwards shift during transforms.
  // To keep the entire mascot and its paws safely on-screen above the bottom edge:
  static const double minXMargin = 60.0;
  static const double maxXMargin = 60.0;
  static const double minYMargin = 60.0;
  static const double maxYMargin = 80.0; // Paws/belly cannot dip beneath bottom screen edge

  Offset clampPositionToBounds(Offset pos) {
    return Offset(
      pos.dx.clamp(minXMargin, (screenSize.width - maxXMargin).clamp(minXMargin, double.infinity)),
      pos.dy.clamp(minYMargin, (screenSize.height - maxYMargin).clamp(minYMargin, double.infinity)),
    );
  }

  void setScreenBounds(Size size) {
    screenSize = size;
    if (screenPosition == const Offset(800, 600)) {
      screenPosition = clampPositionToBounds(Offset(size.width - 160, size.height - 120));
    } else {
      // Re-clamp in case screen resolution or window resized
      screenPosition = clampPositionToBounds(screenPosition);
    }
  }

  void startDragging() {
    cancelTravel();
    isDragging = true;
    if (isInsideBurrow) {
      isInsideBurrow = false;
      mood = PetMood.idle;
    }
    notifyListeners();
  }

  void updateDragging(Offset newScreenPos) {
    screenPosition = clampPositionToBounds(newScreenPos);
    notifyListeners();
  }

  void stopDragging() {
    isDragging = false;
    // Ensure on release the friend remains strictly within screen boundaries
    screenPosition = clampPositionToBounds(screenPosition);
    SoundService.instance.playChirp();
    notifyListeners();
  }

  // --- TRAVEL & PATHING ---

  void travelTo(
    Offset target, {
    required VoidCallback onArrived,
    String? travelThought,
    IconData? thoughtIcon,
  }) {
    travelTarget = clampPositionToBounds(target);
    onTravelArrived = onArrived;
    mood = PetMood.wandering;
    wanderDirection = (travelTarget!.dx - screenPosition.dx).sign;
    if (wanderDirection == 0) wanderDirection = 1.0;
    if (travelThought != null) {
      setThought(travelThought, icon: thoughtIcon ?? Icons.directions_run);
    }
    notifyListeners();
  }

  void cancelTravel() {
    travelTarget = null;
    onTravelArrived = null;
  }

  // --- BURROW DRAGGING & PLACEMENT ---

  void startBurrowDragging() {
    if (!hasBurrow) return;
    isBurrowDragging = true;
    notifyListeners();
  }

  void updateBurrowDragging(Offset newScreenPos) {
    if (!hasBurrow) return;
    final clampedPos = Offset(
      newScreenPos.dx.clamp(minXMargin, (screenSize.width - maxXMargin).clamp(minXMargin, double.infinity)),
      newScreenPos.dy.clamp(minYMargin, (screenSize.height - 40.0).clamp(minYMargin, double.infinity)),
    );
    burrowPosition = clampedPos;

    // If the friend is inside or peeking out of the burrow, they move with it!
    if (isInsideBurrow) {
      screenPosition = burrowPosition! - const Offset(0, 15);
    }
    notifyListeners();
  }

  void stopBurrowDragging() {
    isBurrowDragging = false;
    notifyListeners();
  }

  // --- TOMODACHI ACTIONS: FEED, SLEEP, TICKLE ---

  void feed(SnackType snack, {Offset? origin}) {
    if (mood == PetMood.sleeping) {
      wakeUp();
    }

    // Determine start position for snack delivery:
    // If fish: dives gracefully down from the top of the monitor above the friend!
    // If berry/cookie/dumpling: tossed in an enthusiastic arc from the menu origin or side
    final Offset startPos;
    if (snack == SnackType.fish) {
      startPos = Offset(screenPosition.dx + (math.Random().nextDouble() - 0.5) * 60.0, -30.0);
    } else if (origin != null) {
      startPos = origin;
    } else {
      // Default: tossed from the top-left or top-right above the companion
      startPos = Offset(
        (screenPosition.dx - 180.0).clamp(50.0, screenSize.width - 50.0),
        (screenPosition.dy - 220.0).clamp(20.0, screenSize.height - 200.0),
      );
    }

    final targetPos = screenPosition + const Offset(0, 10);

    incomingSnack = IncomingSnack(
      snack: snack,
      startPosition: startPos,
      targetPosition: targetPos,
      durationSeconds: snack == SnackType.fish ? 0.95 : 0.75,
    );

    // Play whoosh / toss sound as the snack flies through the air
    SoundService.instance.playWhoosh();
    setThought('Catching a ${snack.name}!', icon: snack.icon);
    notifyListeners();
  }

  void _onSnackArrived(SnackType snack) {
    mood = PetMood.eating;
    vitals.feed(snack.hungerRestore);
    SoundService.instance.playMunch();

    // Spawn Food Crumbs + Sparkles at impact/mouth
    final rng = math.Random();
    for (int i = 0; i < 18; i++) {
      particles.add(Particle(
        position: screenPosition + const Offset(0, 10),
        velocity: Offset((rng.nextDouble() - 0.5) * 140, -rng.nextDouble() * 120),
        size: 3.0 + rng.nextDouble() * 3.0,
        maxLife: 0.6 + rng.nextDouble() * 0.4,
        type: ParticleType.crumb,
        color: snack.color,
      ));
    }
    // A couple joyous heart particles
    for (int i = 0; i < 4; i++) {
      particles.add(Particle(
        position: screenPosition + const Offset(0, -15),
        velocity: Offset((rng.nextDouble() - 0.5) * 60, -50 - rng.nextDouble() * 40),
        size: 7.0,
        maxLife: 0.9,
        type: ParticleType.heart,
        color: const Color(0xFFFF4081),
      ));
    }

    setThought('Mmm, yummy ${snack.name}! *crunch crunch*', icon: snack.icon);

    Timer(const Duration(milliseconds: 1200), () {
      if (mood == PetMood.eating) {
        mood = isInsideBurrow ? PetMood.peekingBurrow : PetMood.idle;
        notifyListeners();
      }
    });

    save();
  }

  void toggleSleep() {
    if (mood == PetMood.sleeping) {
      wakeUp();
    } else {
      goToSleep();
    }
  }

  void goToSleep() {
    mood = PetMood.sleeping;
    setThought('Taking a cozy catnap... zzz', icon: Icons.bedtime);
    SoundService.instance.playSnore();

    _snoreTimer?.cancel();
    _snoreTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mood == PetMood.sleeping) {
        SoundService.instance.playSnore();
        // Spawn Zzz particle above pet's head
        particles.add(Particle(
          position: screenPosition + const Offset(15, -45),
          velocity: const Offset(15, -35),
          size: 14.0,
          maxLife: 2.2,
          type: ParticleType.zzz,
          color: const Color(0xFF64B5F6),
        ));
      }
    });

    notifyListeners();
  }

  void wakeUp() {
    _snoreTimer?.cancel();
    mood = isInsideBurrow ? PetMood.peekingBurrow : PetMood.idle;
    SoundService.instance.playChirp(pitchMultiplier: 1.2);
    setThought('Yaaawn! Ready to play!', icon: Icons.wb_sunny);
    notifyListeners();
  }

  void handlePointerMove(Offset pointerPos) {
    final now = DateTime.now();
    if (_lastPointerPos != null && _lastPointerTime != null) {
      final dtMs = now.difference(_lastPointerTime!).inMilliseconds;
      if (dtMs > 0 && dtMs < 100) {
        final dist = (pointerPos - _lastPointerPos!).distance;
        // Check if cursor is over pet body at screenPosition
        final petDist = (pointerPos - screenPosition).distance;
        if (petDist < 65) {
          _accumulatedPetDistance += dist;
          if (_accumulatedPetDistance > 120.0) {
            _triggerTickle(pointerPos);
            _accumulatedPetDistance = 0.0;
          }
        }
      }
    }
    _lastPointerPos = pointerPos;
    _lastPointerTime = now;
  }

  void _triggerTickle(Offset pos) {
    if (mood == PetMood.sleeping) {
      wakeUp();
      return;
    }

    mood = PetMood.tickled;
    vitals.tickle();
    SoundService.instance.playGiggle();

    // Spawn Heart particles
    final rng = math.Random();
    for (int i = 0; i < 3; i++) {
      particles.add(Particle(
        position: pos + Offset((rng.nextDouble() - 0.5) * 20, (rng.nextDouble() - 0.5) * 10),
        velocity: Offset((rng.nextDouble() - 0.5) * 40, -45 - rng.nextDouble() * 30),
        size: 8.0 + rng.nextDouble() * 5.0,
        maxLife: 1.4,
        type: ParticleType.heart,
        color: const Color(0xFFFF4081),
      ));
    }

    setThought('Teehee! That tickles!! *purr purr*', icon: Icons.favorite);

    Timer(const Duration(milliseconds: 1000), () {
      if (mood == PetMood.tickled) {
        mood = isInsideBurrow ? PetMood.peekingBurrow : PetMood.idle;
        notifyListeners();
      }
    });

    save();
  }

  // --- TRICK TRAINING SYSTEM ---

  void trainTrick(PetTrick trick) {
    if (mood == PetMood.sleeping) wakeUp();
    if (vitals.energy < trick.energyCost) {
      setThought("I'm too sleepy for tricks right now... *yawn*", icon: Icons.battery_alert);
      return;
    }

    mood = PetMood.performingTrick;
    activeTrickId = trick.id;
    trickProgress = 0.0;

    vitals.energy = (vitals.energy - trick.energyCost).clamp(0.0, 100.0);
    setThought('Performing ${trick.name}!', icon: trick.icon);

    if (trick.id == 'highFive') {
      SoundService.instance.playHighFive();
    } else if (trick.id == 'dance') {
      SoundService.instance.playChirp(pitchMultiplier: 1.3);
    }

    notifyListeners();
  }

  void _completeTrick(PetTrick trick) {
    final currentXp = companion.trickMastery[trick.id] ?? 0;
    final newXp = currentXp + trick.xpReward;
    companion.trickMastery[trick.id] = newXp;

    final oldTier = TrickMasteryTier.fromXp(currentXp);
    final newTier = TrickMasteryTier.fromXp(newXp);

    vitals.gainXp(trick.xpReward);
    vitals.happiness = (vitals.happiness + 20.0).clamp(0.0, 100.0);

    SoundService.instance.playFanfare();

    // Spawn Sparkle and Music Note particles
    final rng = math.Random();
    for (int i = 0; i < 18; i++) {
      particles.add(Particle(
        position: screenPosition + const Offset(0, -10),
        velocity: Offset((rng.nextDouble() - 0.5) * 160, (rng.nextDouble() - 0.5) * 160),
        size: 5.0 + rng.nextDouble() * 4.0,
        maxLife: 1.2,
        type: (i % 3 == 0) ? ParticleType.musicNote : ParticleType.sparkle,
        color: [Colors.amber, Colors.cyan, Colors.pinkAccent, Colors.purpleAccent][rng.nextInt(4)],
      ));
    }

    if (newTier.index > oldTier.index) {
      setThought('🎉 LEVEL UP! Mastered ${trick.name} (${newTier.name} tier)!', icon: Icons.military_tech);
    } else {
      setThought('Ta-da! Did you see my ${trick.name}? Reward please!', icon: Icons.star);
    }

    mood = isInsideBurrow ? PetMood.peekingBurrow : PetMood.idle;
    activeTrickId = null;
    trickProgress = 0.0;

    save();
    notifyListeners();
  }

  // --- CORNER BURROW SYSTEM ---

  void digBurrow() {
    if (mood == PetMood.sleeping) wakeUp();

    mood = PetMood.digging;
    hasBurrow = true;
    // Burrow is created right where the friend is standing on screen!
    burrowPosition = screenPosition + const Offset(0, 15);
    isInsideBurrow = false;

    SoundService.instance.playDig();
    setThought('Digging a cozy den right here! *scritch scratch*', icon: Icons.landscape);

    // Spawn Flying Dirt Clods right at the friend's feet
    final rng = math.Random();
    final dirtOrigin = burrowPosition!;
    for (int i = 0; i < 22; i++) {
      particles.add(Particle(
        position: dirtOrigin,
        velocity: Offset((rng.nextDouble() - 0.5) * 200, -rng.nextDouble() * 160),
        size: 3.5 + rng.nextDouble() * 4.0,
        maxLife: 0.8 + rng.nextDouble() * 0.4,
        type: ParticleType.dirt,
        color: const Color(0xFF5D4037),
      ));
    }

    Timer(const Duration(milliseconds: 2200), () {
      mood = PetMood.peekingBurrow;
      isInsideBurrow = true;
      setThought('Cozy burrow finished! Peeking out from my home!', icon: Icons.home);
      SoundService.instance.playChirp();
      notifyListeners();
    });

    notifyListeners();
  }

  void toggleBurrowPeek() {
    if (!hasBurrow || burrowPosition == null) {
      digBurrow();
      return;
    }

    if (isInsideBurrow) {
      // Pop out of the burrow to explore
      isInsideBurrow = false;
      mood = PetMood.idle;
      setThought('Popping out of the burrow to explore!', icon: Icons.arrow_upward);
      SoundService.instance.playChirp();
      notifyListeners();
      return;
    }

    // Outside the burrow: go to the burrow!
    final targetPos = burrowPosition! - const Offset(0, 15);
    final dist = (screenPosition - targetPos).distance;

    if (dist > 30.0) {
      travelTo(
        targetPos,
        travelThought: 'Dashing over to my cozy burrow! 🐾',
        thoughtIcon: Icons.landscape,
        onArrived: () {
          isInsideBurrow = true;
          mood = PetMood.peekingBurrow;
          _spawnBurrowArriveParticles();
          SoundService.instance.playChirp(pitchMultiplier: 1.2);
          setThought('Snuggled deep inside the burrow!', icon: Icons.home);
          notifyListeners();
        },
      );
    } else {
      screenPosition = targetPos;
      isInsideBurrow = true;
      mood = PetMood.peekingBurrow;
      _spawnBurrowArriveParticles();
      SoundService.instance.playChirp();
      setThought('Snuggled deep inside the burrow!', icon: Icons.home);
      notifyListeners();
    }
  }

  void _spawnBurrowArriveParticles() {
    if (burrowPosition == null) return;
    final rng = math.Random();
    for (int i = 0; i < 12; i++) {
      particles.add(Particle(
        position: burrowPosition!,
        velocity: Offset((rng.nextDouble() - 0.5) * 130, -rng.nextDouble() * 95),
        size: 3.0 + rng.nextDouble() * 3.5,
        maxLife: 0.7,
        type: ParticleType.dirt,
        color: const Color(0xFF5D4037),
      ));
    }
  }

  // --- DESKTOP FILE SNIFFING & FOLDER DIVING ---

  Future<void> sniffDesktop() async {
    if (mood == PetMood.sleeping) wakeUp();

    mood = PetMood.sniffing;
    setThought('Scanning our desktop for files...', icon: Icons.search);
    SoundService.instance.playChirp();

    final items = await DesktopScanner.scanDesktop();
    if (items.isEmpty) {
      setThought('The desktop is completely spotless! Clean desk, happy pet!', icon: Icons.cleaning_services);
      mood = PetMood.idle;
      notifyListeners();
      return;
    }

    // Pick an interesting item or favorite
    final rng = math.Random();
    DesktopItem chosen = items[rng.nextInt(items.length)];
    // If there's a favorite file, prioritize it!
    for (final it in items) {
      if (companion.favoriteFileExtensions.contains(it.extension)) {
        chosen = it;
        break;
      }
    }

    if (chosen.isDirectory) {
      // Jump into folder dive
      await jumpIntoFolder(chosen);
    } else {
      final reaction = DesktopScanner.generateSniffReaction(chosen, companion);
      setThought(reaction, icon: Icons.description);
      SoundService.instance.playChirp(pitchMultiplier: 1.1);

      Timer(const Duration(milliseconds: 3500), () {
        if (mood == PetMood.sniffing) {
          mood = isInsideBurrow ? PetMood.peekingBurrow : PetMood.idle;
          notifyListeners();
        }
      });
    }
  }

  Future<void> jumpIntoFolder(DesktopItem folder) async {
    mood = PetMood.digging;
    setThought('Diving headfirst into "${folder.name}"! *whoooosh!*', icon: Icons.folder);
    SoundService.instance.playHighFive();

    // Dive animation delay
    await Future.delayed(const Duration(milliseconds: 1400));
    // Pop back out
    mood = PetMood.idle;
    SoundService.instance.playChirp(pitchMultiplier: 1.25);

    // Spurt sparkles
    final rng = math.Random();
    for (int i = 0; i < 10; i++) {
      particles.add(Particle(
        position: screenPosition,
        velocity: Offset((rng.nextDouble() - 0.5) * 140, -rng.nextDouble() * 120),
        size: 5.0,
        maxLife: 1.0,
        type: ParticleType.sparkle,
        color: Colors.amber,
      ));
    }

    setThought('Popped out of "${folder.name}" with a shiny byte!', icon: Icons.auto_awesome);
    vitals.happiness = (vitals.happiness + 15.0).clamp(0.0, 100.0);
    notifyListeners();
  }

  // --- AUTONOMOUS BEHAVIOR ---

  void _triggerAutonomousBehavior() {
    if (mood != PetMood.idle && mood != PetMood.peekingBurrow) return;

    final rng = math.Random();
    final actionRoll = rng.nextInt(6);

    switch (actionRoll) {
      case 0:
        // Sniff desktop autonomously
        sniffDesktop();
        break;
      case 1:
        // Mindfulness wellness nudge or happy chirp
        triggerMindfulnessReminder();
        break;
      case 2:
        // Wandering hop
        mood = PetMood.wandering;
        Timer(const Duration(seconds: 4), () {
          if (mood == PetMood.wandering) {
            mood = isInsideBurrow ? PetMood.peekingBurrow : PetMood.idle;
            notifyListeners();
          }
        });
        break;
      case 3:
        if (hasBurrow && !isInsideBurrow && rng.nextBool()) {
          toggleBurrowPeek();
        }
        break;
      case 4:
        // Autonomous check-in on vitamins or daily routine
        checkRoutineReminders();
        break;
      default:
        break;
    }
  }

  void triggerMindfulnessReminder([MindfulnessQuote? specificQuote]) {
    final quote = specificQuote ?? MindfulnessBank.getRandom();
    SoundService.instance.playZenChime();

    // Spawn themed particles around friend for the reminder
    final rng = math.Random();
    if (quote.category == MindfulnessCategory.hydration) {
      for (int i = 0; i < 8; i++) {
        particles.add(Particle(
          position: screenPosition + const Offset(0, -10),
          velocity: Offset((rng.nextDouble() - 0.5) * 80, -rng.nextDouble() * 90),
          size: 4.0 + rng.nextDouble() * 3.0,
          maxLife: 1.0,
          type: ParticleType.waterDrop,
          color: const Color(0xFF29B6F6),
        ));
      }
    } else if (quote.category == MindfulnessCategory.affirmation) {
      for (int i = 0; i < 6; i++) {
        particles.add(Particle(
          position: screenPosition + const Offset(0, -15),
          velocity: Offset((rng.nextDouble() - 0.5) * 70, -rng.nextDouble() * 80),
          size: 6.0,
          maxLife: 1.2,
          type: ParticleType.heart,
          color: const Color(0xFFFF4081),
        ));
      }
    } else {
      for (int i = 0; i < 8; i++) {
        particles.add(Particle(
          position: screenPosition,
          velocity: Offset((rng.nextDouble() - 0.5) * 90, -rng.nextDouble() * 90),
          size: 5.0,
          maxLife: 0.9,
          type: ParticleType.sparkle,
          color: Colors.lightGreenAccent,
        ));
      }
    }

    setThought(quote.text, icon: quote.icon, duration: const Duration(seconds: 6));
  }

  void logHydration() {
    SoundService.instance.playChirp(pitchMultiplier: 1.3);
    SoundService.instance.playZenChime();

    final rng = math.Random();
    for (int i = 0; i < 16; i++) {
      particles.add(Particle(
        position: screenPosition + const Offset(0, -10),
        velocity: Offset((rng.nextDouble() - 0.5) * 130, -rng.nextDouble() * 120),
        size: 4.5 + rng.nextDouble() * 3.5,
        maxLife: 1.1,
        type: ParticleType.waterDrop,
        color: const Color(0xFF29B6F6),
      ));
    }

    vitals.happiness = (vitals.happiness + 15.0).clamp(0.0, 100.0);
    vitals.affection = (vitals.affection + 5.0).clamp(0.0, 100.0);
    setThought('Yay! Thanks for drinking water, friend! Stay refreshed 💧✨', icon: Icons.water_drop, duration: const Duration(seconds: 5));
    notifyListeners();
  }

  void completeRoutineItem(String id) {
    routineTracker.checkDayRollover();
    final item = routineTracker.items.firstWhere(
      (i) => i.id == id,
      orElse: () => throw ArgumentError('Routine item not found: $id'),
    );

    if (item.isCompleted) return;

    final success = routineTracker.completeItem(id);
    if (!success) return;

    // Celebratory chimes & chirp
    SoundService.instance.playChirp(pitchMultiplier: 1.3);
    SoundService.instance.playZenChime();

    // Rewards
    vitals.gainXp(item.xpReward);
    vitals.happiness = (vitals.happiness + 15.0).clamp(0.0, 100.0);
    vitals.affection = (vitals.affection + 5.0).clamp(0.0, 100.0);

    // Celebratory particles
    final rng = math.Random();
    for (int i = 0; i < 16; i++) {
      particles.add(Particle(
        position: screenPosition + const Offset(0, -10),
        velocity: Offset((rng.nextDouble() - 0.5) * 120, -rng.nextDouble() * 110),
        size: 5.0 + rng.nextDouble() * 4.0,
        maxLife: 1.1,
        type: item.id == 'vitamins' ? ParticleType.sparkle : ParticleType.heart,
        color: item.id == 'vitamins' ? const Color(0xFFFFD54F) : const Color(0xFF81C784),
      ));
    }

    setThought(item.companionQuote, icon: item.icon, duration: const Duration(seconds: 5));
    save();
    notifyListeners();
  }

  void toggleRoutineItem(String id) {
    routineTracker.checkDayRollover();
    final item = routineTracker.items.firstWhere((i) => i.id == id);
    if (item.isCompleted) {
      routineTracker.uncompleteItem(id);
      save();
      notifyListeners();
    } else {
      completeRoutineItem(id);
    }
  }

  void checkRoutineReminders() {
    routineTracker.checkDayRollover();
    if (!routineTracker.isVitaminsCompleted) {
      setThought('Did you remember to take your daily vitamins? 💊', icon: Icons.medication, duration: const Duration(seconds: 5));
      SoundService.instance.playChirp(pitchMultiplier: 1.1);
      return;
    }

    if (routineTracker.completedCount < routineTracker.totalCount) {
      final pending = routineTracker.items.firstWhere((i) => !i.isCompleted);
      setThought('How\'s your routine going today? Next up: ${pending.title}! 📋', icon: pending.icon, duration: const Duration(seconds: 5));
      SoundService.instance.playChirp(pitchMultiplier: 1.1);
    }
  }

  void setThought(String text, {IconData? icon, Duration duration = const Duration(seconds: 4)}) {
    thoughtBubble = ThoughtBubble(text: text, icon: icon, duration: duration);
    notifyListeners();
  }

  void updateCompanion(CompanionModel newModel) {
    companion = newModel;
    save();
    notifyListeners();
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_companion', companion.serialize());
      await prefs.setString('daily_routine_tracker', routineTracker.serialize());
    } catch (_) {}
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _decayTimer?.cancel();
    _snoreTimer?.cancel();
    _autonomousTimer?.cancel();
    super.dispose();
  }
}
