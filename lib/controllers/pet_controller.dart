import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/sound_service.dart';
import '../core/desktop_scanner.dart';
import '../graphics/particle.dart';
import '../models/companion_model.dart';
import '../models/pet_state.dart';
import '../models/trick_system.dart';

class PetController extends ChangeNotifier {
  CompanionModel companion;
  PetVitals vitals;
  PetMood mood = PetMood.idle;

  // Visual & Animation State
  double animationTime = 0.0;
  double trickProgress = 0.0;
  String? activeTrickId;
  BurrowCorner burrowCorner = BurrowCorner.bottomRight;
  bool hasBurrow = false;
  bool isInsideBurrow = false;

  ThoughtBubble? thoughtBubble;
  final List<Particle> particles = [];

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
  }) : vitals = vitals ?? PetVitals() {
    _startLoops();
  }

  static Future<PetController> create() async {
    CompanionModel companion = CompanionModel.defaultCompanion();
    PetVitals vitals = PetVitals();

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
    } catch (_) {}

    return PetController(companion: companion, vitals: vitals);
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
      if (nextX <= 80 || nextX >= screenSize.width - 80) {
        wanderDirection = -wanderDirection;
      }
      screenPosition = Offset(
        nextX.clamp(80.0, screenSize.width - 80.0),
        screenPosition.dy,
      );
    }

    // Check thought bubble expiry
    if (thoughtBubble != null && thoughtBubble!.isExpired) {
      thoughtBubble = null;
    }

    notifyListeners();
  }

  void setScreenBounds(Size size) {
    screenSize = size;
    if (screenPosition == const Offset(800, 600)) {
      screenPosition = Offset(size.width - 160, size.height - 120);
    }
  }

  void startDragging() {
    isDragging = true;
    notifyListeners();
  }

  void updateDragging(Offset newScreenPos) {
    screenPosition = Offset(
      newScreenPos.dx.clamp(60.0, screenSize.width - 60.0),
      newScreenPos.dy.clamp(60.0, screenSize.height - 60.0),
    );
    notifyListeners();
  }

  void stopDragging() {
    isDragging = false;
    SoundService.instance.playChirp();
    notifyListeners();
  }

  // --- TOMODACHI ACTIONS: FEED, SLEEP, TICKLE ---

  void feed(SnackType snack) {
    if (mood == PetMood.sleeping) {
      wakeUp();
    }

    mood = PetMood.eating;
    vitals.feed(snack.hungerRestore);
    SoundService.instance.playMunch();

    // Spawn Food Crumbs
    final rng = math.Random();
    for (int i = 0; i < 14; i++) {
      particles.add(Particle(
        position: const Offset(150, 165),
        velocity: Offset((rng.nextDouble() - 0.5) * 120, -rng.nextDouble() * 100),
        size: 3.0 + rng.nextDouble() * 2.5,
        maxLife: 0.6 + rng.nextDouble() * 0.4,
        type: ParticleType.crumb,
        color: snack.color,
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
        // Spawn Zzz particle
        particles.add(Particle(
          position: const Offset(165, 120),
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

  void handlePointerMove(Offset localPos) {
    final now = DateTime.now();
    if (_lastPointerPos != null && _lastPointerTime != null) {
      final dtMs = now.difference(_lastPointerTime!).inMilliseconds;
      if (dtMs > 0 && dtMs < 100) {
        final dist = (localPos - _lastPointerPos!).distance;
        // Check if cursor is over pet body (approx center at 150, 160)
        final petDist = (localPos - const Offset(150, 160)).distance;
        if (petDist < 55) {
          _accumulatedPetDistance += dist;
          if (_accumulatedPetDistance > 120.0) {
            _triggerTickle(localPos);
            _accumulatedPetDistance = 0.0;
          }
        }
      }
    }
    _lastPointerPos = localPos;
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
        position: const Offset(150, 140),
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
    burrowCorner = BurrowCorner.bottomRight;
    isInsideBurrow = false;

    SoundService.instance.playDig();
    setThought('Digging a cozy den in the corner! *scritch scratch*', icon: Icons.landscape);

    // Spawn Flying Dirt Clods
    final rng = math.Random();
    for (int i = 0; i < 20; i++) {
      particles.add(Particle(
        position: const Offset(150, 185),
        velocity: Offset((rng.nextDouble() - 0.8) * 180, -rng.nextDouble() * 140),
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
    if (!hasBurrow) {
      digBurrow();
      return;
    }

    isInsideBurrow = !isInsideBurrow;
    mood = isInsideBurrow ? PetMood.peekingBurrow : PetMood.idle;
    if (isInsideBurrow) {
      setThought('Snuggled deep inside the burrow!', icon: Icons.home);
    } else {
      setThought('Popping out of the burrow to explore!', icon: Icons.arrow_upward);
      SoundService.instance.playChirp();
    }
    notifyListeners();
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
        position: const Offset(150, 160),
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
    final actionRoll = rng.nextInt(5);

    switch (actionRoll) {
      case 0:
        // Sniff desktop autonomously
        sniffDesktop();
        break;
      case 1:
        // Happy chirp
        SoundService.instance.playChirp();
        final idleQuotes = [
          'Watching your cursor move... it looks fast!',
          'Having lots of fun on your desktop!',
          'Your desktop wallpaper looks nice today!',
          'Remember to take a sip of water!',
        ];
        setThought(idleQuotes[rng.nextInt(idleQuotes.length)], icon: Icons.chat_bubble);
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
      default:
        break;
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
      // save vitals
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
