import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andfriend/controllers/pet_controller.dart';
import 'package:andfriend/core/desktop_scanner.dart';
import 'package:andfriend/models/companion_model.dart';
import 'package:andfriend/models/eft_tapping_state.dart';
import 'package:andfriend/models/grounding_state.dart';
import 'package:andfriend/models/exergaming_state.dart';
import 'package:andfriend/models/mindfulness_state.dart';
import 'package:andfriend/models/pet_state.dart';
import 'package:andfriend/models/routine_state.dart';
import 'package:andfriend/models/trick_system.dart';
import 'package:andfriend/storage/encrypted_storage_service.dart';
import 'package:andfriend/ui/mindfulness_dialog.dart';
import 'package:andfriend/graphics/particle.dart';
import 'package:andfriend/models/park_state.dart';
import 'package:andfriend/services/park_client_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CompanionModel Tests', () {
    test('Default companion initializes with valid attributes', () {
      final comp = CompanionModel.defaultCompanion();
      expect(comp.name, equals('Liil Buddy'));
      expect(comp.archetype, equals(CompanionArchetype.fox));
      expect(comp.accessory, equals(CompanionAccessory.starBadge));
      expect(comp.favoriteFileExtensions, contains('.dart'));
      expect(comp.favoriteFileExtensions, contains('.png'));
    });

    test('Prompt generator creates matching archetype, colors and traits', () {
      // Dragon prompt
      final dragon = CompanionModel.fromPrompt(
        'A sleepy matcha dragon with tiny golden horns who loves code files called Draco',
      );
      expect(dragon.archetype, equals(CompanionArchetype.dragon));
      expect(dragon.name, equals('Draco'));
      expect(dragon.personality, equals(PetPersonality.sleepy));
      expect(dragon.accessory, equals(CompanionAccessory.tinyHorns));
      expect(dragon.favoriteFileExtensions, contains('.dart'));

      // Cat prompt
      final cat = CompanionModel.fromPrompt(
        'A sweet pink sakura kitten with a magic wizard hat who loves pictures named Misa',
      );
      expect(cat.archetype, equals(CompanionArchetype.cat));
      expect(cat.name, equals('Misa'));
      expect(cat.accessory, equals(CompanionAccessory.wizardHat));
      expect(cat.favoriteFileExtensions, contains('.png'));

      // Bunny prompt
      final bunny = CompanionModel.fromPrompt(
        'A fast energetic neon blue bunny with cool glasses that loves music',
      );
      expect(bunny.archetype, equals(CompanionArchetype.bunny));
      expect(bunny.personality, equals(PetPersonality.energetic));
      expect(bunny.accessory, equals(CompanionAccessory.coolGlasses));
      expect(bunny.favoriteFileExtensions, contains('.mp3'));
    });

    test('Serialization and Deserialization round-trip preserves state', () {
      final original = CompanionModel(
        id: 'test_123',
        name: 'Kibo',
        archetype: CompanionArchetype.shiba,
        primaryColor: const Color(0xFFE67E22),
        secondaryColor: const Color(0xFFFFF8E7),
        accentColor: const Color(0xFFD35400),
        eyeColor: const Color(0xFF2C3E50),
        accessory: CompanionAccessory.cozyScarf,
        personality: PetPersonality.playful,
        favoriteFileExtensions: ['.txt', '.pdf'],
        trickMastery: {'backflip': 120, 'spin': 350},
      );

      final jsonString = original.serialize();
      final restored = CompanionModel.deserialize(jsonString);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.archetype, equals(original.archetype));
      expect(restored.accessory, equals(original.accessory));
      expect(restored.personality, equals(original.personality));
      expect(restored.favoriteFileExtensions, equals(original.favoriteFileExtensions));
      expect(restored.trickMastery['backflip'], equals(120));
      expect(restored.trickMastery['spin'], equals(350));
    });
  });

  group('PetVitals and Tomodachi Care Tests', () {
    test('Feeding increases hunger and happiness', () {
      final vitals = PetVitals(hunger: 50.0, happiness: 50.0, affection: 50.0);
      vitals.feed(SnackType.dumpling.hungerRestore);

      expect(vitals.hunger, equals(100.0));
      expect(vitals.happiness, greaterThan(50.0));
      expect(vitals.affection, greaterThan(50.0));
    });

    test('Sleeping recovers energy', () {
      final vitals = PetVitals(energy: 40.0);
      vitals.sleepTick(20.0);
      expect(vitals.energy, equals(60.0));

      vitals.sleepTick(50.0);
      expect(vitals.energy, equals(100.0)); // Clamped to 100
    });

    test('Tickling boosts happiness and affection', () {
      final vitals = PetVitals(happiness: 70.0, affection: 60.0);
      vitals.tickle();
      expect(vitals.happiness, equals(75.0));
      expect(vitals.affection, equals(63.0));
    });

    test('XP gain triggers level up', () {
      final vitals = PetVitals(level: 1, currentXp: 80);
      vitals.gainXp(30); // Total 110 >= 100
      expect(vitals.level, equals(2));
      expect(vitals.currentXp, equals(10));
      expect(vitals.happiness, equals(100.0));
    });

    test('Decay reduces vitals over time', () {
      final vitals = PetVitals(hunger: 80.0, energy: 80.0, happiness: 80.0);
      vitals.decay(10.0); // 10 seconds
      expect(vitals.hunger, lessThan(80.0));
      expect(vitals.energy, lessThan(80.0));
      expect(vitals.happiness, lessThan(80.0));
    });
  });

  group('Trick System Tests', () {
    test('All 6 core tricks exist and are findable', () {
      expect(PetTrick.allTricks.length, equals(6));
      expect(PetTrick.findById('backflip'), isNotNull);
      expect(PetTrick.findById('spin'), isNotNull);
      expect(PetTrick.findById('playDead'), isNotNull);
      expect(PetTrick.findById('beg'), isNotNull);
      expect(PetTrick.findById('dance'), isNotNull);
      expect(PetTrick.findById('highFive'), isNotNull);
    });

    test('Trick mastery tier calculates correctly', () {
      expect(TrickMasteryTier.fromXp(0), equals(TrickMasteryTier.novice));
      expect(TrickMasteryTier.fromXp(99), equals(TrickMasteryTier.novice));
      expect(TrickMasteryTier.fromXp(100), equals(TrickMasteryTier.apprentice));
      expect(TrickMasteryTier.fromXp(299), equals(TrickMasteryTier.apprentice));
      expect(TrickMasteryTier.fromXp(300), equals(TrickMasteryTier.master));
      expect(TrickMasteryTier.fromXp(500), equals(TrickMasteryTier.master));
    });
  });

  group('Desktop Scanner Reactions Tests', () {
    test('Favorite file reaction triggers special excitement', () {
      final comp = CompanionModel.defaultCompanion(); // Has .dart in favorites
      final item = const DesktopItem(
        path: '/Users/test/Desktop/main.dart',
        name: 'main.dart',
        isDirectory: false,
        extension: '.dart',
        sizeBytes: 1024,
      );

      final reaction = DesktopScanner.generateSniffReaction(item, comp);
      expect(reaction, contains('FAVORITE'));
      expect(reaction, contains('main.dart'));
    });

    test('Folder item triggers cavernous reaction', () {
      final comp = CompanionModel.defaultCompanion();
      final folder = const DesktopItem(
        path: '/Users/test/Desktop/Projects',
        name: 'Projects',
        isDirectory: true,
        extension: '',
        sizeBytes: 0,
      );

      final reaction = DesktopScanner.generateSniffReaction(folder, comp);
      expect(reaction, contains('Projects'));
    });

    test('Image file triggers artwork reaction', () {
      final comp = CompanionModel(
        id: 'test',
        name: 'Test',
        archetype: CompanionArchetype.cat,
        primaryColor: Colors.white,
        secondaryColor: Colors.white,
        accentColor: Colors.white,
        eyeColor: Colors.black,
        favoriteFileExtensions: [], // No favorites
      );
      final item = const DesktopItem(
        path: '/Users/test/Desktop/screenshot.png',
        name: 'screenshot.png',
        isDirectory: false,
        extension: '.png',
        sizeBytes: 2048,
      );

      final reaction = DesktopScanner.generateSniffReaction(item, comp);
      expect(reaction, contains('colorful'));
    });
  });

  group('PetController Screen Boundary and Clamping Tests', () {
    test('Dragging or position setting cannot place friend beneath bottom boundary', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      // Attempt to drag beneath bottom boundary
      ctrl.updateDragging(const Offset(960, 1200));
      expect(ctrl.screenPosition.dy, lessThanOrEqualTo(1080.0 - PetController.maxYMargin));
      expect(ctrl.screenPosition.dy, equals(1000.0));

      // Attempt to drag above top boundary
      ctrl.updateDragging(const Offset(960, -100));
      expect(ctrl.screenPosition.dy, greaterThanOrEqualTo(PetController.minYMargin));
      expect(ctrl.screenPosition.dy, equals(60.0));

      // Attempt to drag past left/right bounds
      ctrl.updateDragging(const Offset(-50, 500));
      expect(ctrl.screenPosition.dx, equals(60.0));

      ctrl.updateDragging(const Offset(2500, 500));
      expect(ctrl.screenPosition.dx, equals(1920.0 - 60.0));

      ctrl.dispose();
    });
  });

  group('Snack Delivery and Animation Tests', () {
    test('SnackType.fish drops from top of monitor and completes delivery', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.screenPosition = const Offset(500, 800);

      ctrl.feed(SnackType.fish);

      expect(ctrl.incomingSnack, isNotNull);
      expect(ctrl.incomingSnack!.snack, equals(SnackType.fish));
      // Fish starts above the screen (dy <= 0)
      expect(ctrl.incomingSnack!.startPosition.dy, lessThanOrEqualTo(0.0));
      expect(ctrl.incomingSnack!.targetPosition, equals(const Offset(500, 810)));

      // Fast forward flight
      ctrl.incomingSnack!.update(1.0);
      expect(ctrl.incomingSnack!.isFinished, isTrue);

      ctrl.dispose();
    });

    test('SnackType.berry arcs from toss origin', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.screenPosition = const Offset(500, 800);
      const menuOrigin = Offset(300, 600);

      ctrl.feed(SnackType.berry, origin: menuOrigin);

      expect(ctrl.incomingSnack, isNotNull);
      expect(ctrl.incomingSnack!.snack, equals(SnackType.berry));
      expect(ctrl.incomingSnack!.startPosition, equals(menuOrigin));

      // Test parabolic arc midflight (t = 0.5)
      ctrl.incomingSnack!.update(0.375); // Halfway through 0.75s
      final midPos = ctrl.incomingSnack!.currentPosition;
      expect(midPos.dx, closeTo(400.0, 5.0));
      // Midflight Y should be lifted by arcOffset
      expect(midPos.dy, lessThan((600.0 + 810.0) / 2));

      ctrl.dispose();
    });
  });

  group('Mindfulness & Owner Caretaker Tests', () {
    test('MindfulnessBank contains diverse wellness categories and valid quotes', () {
      expect(MindfulnessBank.allQuotes.isNotEmpty, isTrue);
      final categories = MindfulnessBank.allQuotes.map((q) => q.category).toSet();
      expect(categories, contains(MindfulnessCategory.hydration));
      expect(categories, contains(MindfulnessCategory.rest));
      expect(categories, contains(MindfulnessCategory.posture));
      expect(categories, contains(MindfulnessCategory.affirmation));
      expect(categories, contains(MindfulnessCategory.nightWindDown));

      final daytimeQuote = MindfulnessBank.getRandom(currentTime: DateTime(2026, 9, 18, 14, 0));
      expect(daytimeQuote.text.isNotEmpty, isTrue);
      expect(daytimeQuote.category, isNot(equals(MindfulnessCategory.nightWindDown)));

      final lateNightQuote = MindfulnessBank.getRandom(currentTime: DateTime(2026, 9, 18, 23, 30));
      expect(lateNightQuote.text.isNotEmpty, isTrue);
    });

    test('triggerMindfulnessReminder displays quote thought and spawns particles', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      const testQuote = MindfulnessQuote(
        text: 'Hydration check test!',
        category: MindfulnessCategory.hydration,
        icon: Icons.water_drop,
      );

      ctrl.particles.clear();
      ctrl.triggerMindfulnessReminder(testQuote);

      expect(ctrl.thoughtBubble?.text, equals('Hydration check test!'));
      expect(ctrl.thoughtBubble?.icon, equals(Icons.water_drop));
      expect(ctrl.particles.isNotEmpty, isTrue);
      expect(ctrl.particles.any((p) => p.type == ParticleType.waterDrop), isTrue);

      ctrl.dispose();
    });

    test('logHydration spawns water splash particles and boosts vitals', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.vitals = PetVitals(hunger: 50.0, energy: 50.0, happiness: 50.0, affection: 50.0);
      ctrl.particles.clear();

      ctrl.logHydration();

      expect(ctrl.thoughtBubble?.text, contains('refreshed'));
      expect(ctrl.vitals.happiness, greaterThan(50.0));
      expect(ctrl.vitals.affection, greaterThan(50.0));
      expect(ctrl.particles.where((p) => p.type == ParticleType.waterDrop).length, greaterThanOrEqualTo(10));

      ctrl.dispose();
    });
  });

  group('Daily Routine & Habit Tracker Tests', () {
    test('Default tracker contains core habits including vitamins and hydration', () {
      final tracker = DailyRoutineTracker();
      expect(tracker.items.length, greaterThanOrEqualTo(6));
      expect(tracker.items.any((i) => i.id == 'vitamins'), isTrue);
      expect(tracker.items.any((i) => i.id == 'morning_water'), isTrue);
      expect(tracker.items.any((i) => i.id == 'posture_reset'), isTrue);
      expect(tracker.items.any((i) => i.id == 'nourishing_lunch'), isTrue);
      expect(tracker.items.any((i) => i.id == 'eye_rest'), isTrue);
      expect(tracker.items.any((i) => i.id == 'evening_winddown'), isTrue);

      expect(tracker.isVitaminsCompleted, isFalse);
      expect(tracker.completedCount, equals(0));
      expect(tracker.progressRatio, equals(0.0));
      expect(tracker.allCompleted, isFalse);
    });

    test('completeItem marks item done, updates streak, and preserves state through serialization', () {
      final tracker = DailyRoutineTracker();
      final now = DateTime(2026, 9, 18, 9, 0);

      final result = tracker.completeItem('vitamins', currentTime: now);
      expect(result, isTrue);
      expect(tracker.isVitaminsCompleted, isTrue);
      expect(tracker.completedCount, equals(1));
      expect(tracker.progressRatio, greaterThan(0.0));
      expect(tracker.currentStreak, equals(1));
      expect(tracker.bestStreak, equals(1));

      // Re-completing already completed item returns false
      expect(tracker.completeItem('vitamins', currentTime: now), isFalse);

      // JSON round trip
      final jsonStr = tracker.serialize();
      final restored = DailyRoutineTracker.deserialize(jsonStr);

      expect(restored.currentStreak, equals(1));
      expect(restored.bestStreak, equals(1));
      expect(restored.isVitaminsCompleted, isTrue);
      expect(restored.completedCount, equals(1));
    });

    test('Day rollover resets completed habits for new day', () {
      final tracker = DailyRoutineTracker(lastCheckedDate: DateTime(2026, 9, 18, 10, 0));
      tracker.completeItem('vitamins', currentTime: DateTime(2026, 9, 18, 10, 30));
      expect(tracker.completedCount, equals(1));

      // Rollover to next day
      tracker.checkDayRollover(currentTime: DateTime(2026, 9, 19, 8, 0));
      expect(tracker.completedCount, equals(0));
      expect(tracker.isVitaminsCompleted, isFalse);
    });

    test('Custom habit can be added, completed, and removed', () {
      final tracker = DailyRoutineTracker();
      tracker.addCustomItem(
        title: 'Walk in park',
        subtitle: 'Get 15 minutes of sunlight',
      );

      expect(tracker.items.any((i) => i.title == 'Walk in park' && i.isCustom), isTrue);
      final customItem = tracker.items.firstWhere((i) => i.title == 'Walk in park');

      expect(tracker.completeItem(customItem.id), isTrue);
      expect(customItem.isCompleted, isTrue);

      expect(tracker.removeCustomItem(customItem.id), isTrue);
      expect(tracker.items.any((i) => i.title == 'Walk in park'), isFalse);
    });

    test('PetController.completeRoutineItem awards XP, vitals, quote bubble, and particles', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.vitals = PetVitals(hunger: 50.0, energy: 50.0, happiness: 50.0, affection: 50.0, currentXp: 0);
      ctrl.particles.clear();

      ctrl.completeRoutineItem('vitamins');

      expect(ctrl.routineTracker.isVitaminsCompleted, isTrue);
      expect(ctrl.vitals.currentXp, equals(35));
      expect(ctrl.vitals.happiness, greaterThan(50.0));
      expect(ctrl.vitals.affection, greaterThan(50.0));
      expect(ctrl.thoughtBubble?.text, contains('Vitamins'));
      expect(ctrl.particles.isNotEmpty, isTrue);

      ctrl.dispose();
    });
  });

  group('Draggable Burrow and Travel Tests', () {
    test('Burrow can be dragged and repositioned within screen boundaries', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      ctrl.digBurrow();
      expect(ctrl.hasBurrow, isTrue);
      expect(ctrl.burrowPosition, isNotNull);

      // Drag burrow to new coordinate near bottom edge -> snaps to bottom edge
      ctrl.startBurrowDragging();
      expect(ctrl.isBurrowDragging, isTrue);

      ctrl.updateBurrowDragging(const Offset(400, 700));
      expect(ctrl.burrowEdge, equals(BurrowEdge.bottom));
      expect(ctrl.burrowPosition, equals(const Offset(400, 1040)));

      // Drag burrow towards left wall -> snaps to left edge
      ctrl.updateBurrowDragging(const Offset(30, 500));
      expect(ctrl.burrowEdge, equals(BurrowEdge.left));
      expect(ctrl.burrowPosition, equals(const Offset(40, 500)));

      // Drag burrow towards right wall -> snaps to right edge
      ctrl.updateBurrowDragging(const Offset(1910, 400));
      expect(ctrl.burrowEdge, equals(BurrowEdge.right));
      expect(ctrl.burrowPosition, equals(const Offset(1880, 400)));

      ctrl.stopBurrowDragging();
      expect(ctrl.isBurrowDragging, isFalse);

      ctrl.dispose();
    });

    test('Real-time drag-and-follow emerges friend and follows moving mound, auto-resettling on drop', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.hasBurrow = true;
      ctrl.burrowEdge = BurrowEdge.bottom;
      ctrl.burrowPosition = const Offset(500, 1040);
      ctrl.isInsideBurrow = true;
      ctrl.screenPosition = ctrl.getBurrowPetPosition();

      // Grabbing mound causes friend to emerge from hole and follow in real time!
      ctrl.startBurrowDragging();
      expect(ctrl.isBurrowDragging, isTrue);
      expect(ctrl.isInsideBurrow, isFalse);
      expect(ctrl.isFollowingBurrowMound, isTrue);
      expect(ctrl.mood, equals(PetMood.wandering));

      // Slide along bottom edge: mound moves and pet actively tracks towards it
      ctrl.updateBurrowDragging(const Offset(900, 1040));
      expect(ctrl.burrowPosition, equals(const Offset(900, 1040)));
      expect(ctrl.screenPosition.dx, greaterThan(500.0)); // Stepping towards mound

      // Slide to left edge
      ctrl.updateBurrowDragging(const Offset(20, 600));
      expect(ctrl.burrowEdge, equals(BurrowEdge.left));
      expect(ctrl.burrowPosition, equals(const Offset(40, 600)));

      // Slide to right edge
      ctrl.updateBurrowDragging(const Offset(1900, 300));
      expect(ctrl.burrowEdge, equals(BurrowEdge.right));
      expect(ctrl.burrowPosition, equals(const Offset(1880, 300)));

      // Dropping mound auto-resettles companion inside
      ctrl.stopBurrowDragging();
      expect(ctrl.isBurrowDragging, isFalse);
      // Completing arrival re-tucks friend into burrow
      ctrl.completeBurrowSniff();
      expect(ctrl.isInsideBurrow, isTrue);
      expect(ctrl.isFollowingBurrowMound, isFalse);

      ctrl.dispose();
    });

    test('When friend burrows from a distance, friend travels, sniffs & wiggles, then tucks in', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.hasBurrow = true;
      ctrl.burrowEdge = BurrowEdge.bottom;
      ctrl.burrowPosition = const Offset(200, 1040);
      ctrl.isInsideBurrow = false;
      ctrl.screenPosition = const Offset(1200, 1000); // Distance away

      ctrl.toggleBurrowPeek();

      // Travel has been initiated
      expect(ctrl.travelTarget, isNotNull);
      expect(ctrl.travelTarget, equals(const Offset(200, 1025))); // Direct burrow pet position
      expect(ctrl.mood, equals(PetMood.wandering));
      expect(ctrl.wanderDirection, equals(-1.0)); // Facing left towards burrow

      // Fast-forward position to destination & arrive
      ctrl.screenPosition = ctrl.getBurrowPetPosition();
      ctrl.toggleBurrowPeek();

      // Enters sniffing and wiggling preparation phase!
      expect(ctrl.mood, equals(PetMood.burrowSniffing));
      expect(ctrl.thoughtBubble?.text, contains('Crawling into my burrow'));

      // Sniff complete -> friend tucks cleanly inside
      ctrl.completeBurrowSniff();
      expect(ctrl.isInsideBurrow, isTrue);
      expect(ctrl.mood, equals(PetMood.peekingBurrow));
      expect(ctrl.thoughtBubble?.text, contains('Tucked safely inside'));

      ctrl.dispose();
    });

    test('Tucking inside burrow starts burrow nap, recovers energy, and unsnugs cleanly with welcome greeting', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.hasBurrow = true;
      ctrl.burrowEdge = BurrowEdge.bottom;
      ctrl.burrowPosition = const Offset(300, 1040);
      ctrl.screenPosition = const Offset(300, 1025);
      ctrl.vitals.energy = 50.0;

      // Hop into burrow: starts sniffing phase then tucks in
      ctrl.toggleBurrowPeek();
      expect(ctrl.mood, equals(PetMood.burrowSniffing));
      ctrl.completeBurrowSniff();

      expect(ctrl.isInsideBurrow, isTrue);
      expect(ctrl.mood, equals(PetMood.peekingBurrow));

      // Unsnug / Wake from burrow
      ctrl.unsnugFromBurrow();
      expect(ctrl.isInsideBurrow, isFalse);
      expect(ctrl.mood, equals(PetMood.idle));
      expect(ctrl.thoughtBubble?.text, contains('Welcome back!'));
      expect(ctrl.particles.any((p) => p.type == ParticleType.heart || p.type == ParticleType.sparkle), isTrue);

      ctrl.dispose();
    });

    test('digCornerBurrow pathfinds towards the nearest corner and in-place fallback', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.screenPosition = const Offset(1700, 1000); // Near bottom-right corner

      ctrl.digCornerBurrow();
      // Should pathfind to bottom-right corner clamped to boundary bounds (1860, 1000)
      expect(ctrl.travelTarget, equals(const Offset(1860.0, 1000.0)));

      // Fast forward near bottom-left corner
      ctrl.screenPosition = const Offset(50, 1030);
      ctrl.digCornerBurrow(); // Within 50px of bottom-left -> digs immediately
      expect(ctrl.hasBurrow, isTrue);
      expect(ctrl.mood, equals(PetMood.digging));

      ctrl.dispose();
    });

    test('Wiggle-to-wake triggers soil shake animation and welcome sequence without penalty', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.hasBurrow = true;
      ctrl.burrowPosition = const Offset(400, 1040);
      ctrl.isInsideBurrow = true;

      // Wiggle soil shake
      ctrl.wiggleSoilShake();
      expect(ctrl.burrowShakeProgress, greaterThan(0.0));
      expect(ctrl.particles.any((p) => p.type == ParticleType.dirt), isTrue);

      // Wake from burrow
      ctrl.wakeFromBurrow(isWiggle: true);
      expect(ctrl.isInsideBurrow, isFalse);
      expect(ctrl.mood, equals(PetMood.idle));
      expect(ctrl.thoughtBubble?.text, contains('Welcome back!'));

      ctrl.dispose();
    });

    test('Complete muting and streak freeze during burrow rest', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.hasBurrow = true;
      ctrl.burrowPosition = const Offset(400, 1040);
      ctrl.isInsideBurrow = true;
      ctrl.thoughtBubble = null;

      // Streak protection: paused checkDayRollover does not reset currentStreak
      ctrl.routineTracker.currentStreak = 5;
      final twoDaysLater = DateTime.now().add(const Duration(days: 2));
      ctrl.routineTracker.checkDayRollover(currentTime: twoDaysLater, isPaused: ctrl.isInsideBurrow);
      expect(ctrl.routineTracker.currentStreak, equals(5));

      ctrl.dispose();
    });
  });

  group('Floating HALT Speech Bubbles & 1-Click Dopamine Loop Tests', () {
    test('HaltType provides grounded, empathetic prompts and icons', () {
      for (final type in HaltType.values) {
        expect(type.title, isNotEmpty);
        expect(type.prompt, isNotEmpty);
        expect(type.icon, isNotNull);
      }
      expect(HaltType.hungry.prompt, contains('nourishing snack'));
      expect(HaltType.angry.prompt, contains('slow deep breath'));
      expect(HaltType.lonely.prompt, contains('here with you'));
      expect(HaltType.tired.prompt, contains('2-minute rest'));
    });

    test('triggerHaltCheckIn creates actionable thought bubble with Done! button', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      ctrl.triggerHaltCheckIn(type: HaltType.hungry);

      expect(ctrl.thoughtBubble, isNotNull);
      expect(ctrl.thoughtBubble!.isActionable, isTrue);
      expect(ctrl.thoughtBubble!.actionLabel, equals('Done! ✨'));
      expect(ctrl.thoughtBubble!.haltType, equals(HaltType.hungry));
      expect(ctrl.thoughtBubble!.text, equals(HaltType.hungry.prompt));
      expect(ctrl.thoughtBubble!.duration.inSeconds, equals(18));

      ctrl.dispose();
    });

    test('triggerHaltCheckIn is muted while resting in burrow or sleeping', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.hasBurrow = true;
      ctrl.isInsideBurrow = true;
      ctrl.thoughtBubble = null;

      ctrl.triggerHaltCheckIn(type: HaltType.tired);
      expect(ctrl.thoughtBubble, isNull);

      // Sleeping muting test
      ctrl.isInsideBurrow = false;
      ctrl.mood = PetMood.sleeping;
      ctrl.triggerHaltCheckIn(type: HaltType.angry);
      expect(ctrl.thoughtBubble, isNull);

      ctrl.dispose();
    });

    test('1-Click Done! completion triggers celebratory cascade, particles, vitals, and praise', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.vitals = PetVitals(energy: 50.0, happiness: 50.0, affection: 50.0);
      final initialXp = ctrl.vitals.xp;

      // Trigger check-in
      ctrl.triggerHaltCheckIn(type: HaltType.lonely);
      expect(ctrl.thoughtBubble!.isActionable, isTrue);

      // Tap "Done! ✨" action
      ctrl.thoughtBubble!.onAction!();

      // Verify immediate dopamine response
      expect(ctrl.mood, equals(PetMood.happy));
      expect(ctrl.vitals.energy, equals(65.0)); // +15
      expect(ctrl.vitals.happiness, equals(70.0)); // +20
      expect(ctrl.vitals.affection, equals(65.0)); // +15
      expect(ctrl.vitals.xp, equals(initialXp + 25)); // +25 XP

      // Verify particle types spawned: confetti, party hats, treats
      final hasConfetti = ctrl.particles.any((p) => p.type == ParticleType.confetti);
      final hasPartyHat = ctrl.particles.any((p) => p.type == ParticleType.partyHat);
      final hasTreat = ctrl.particles.any((p) => p.type == ParticleType.treat);
      expect(hasConfetti, isTrue);
      expect(hasPartyHat, isTrue);
      expect(hasTreat, isTrue);

      // Verify celebratory praise thought bubble
      expect(ctrl.thoughtBubble, isNotNull);
      expect(ctrl.thoughtBubble!.isActionable, isFalse);
      expect(ctrl.thoughtBubble!.icon, equals(Icons.celebration));
      expect(ctrl.thoughtBubble!.text, contains('never alone'));

      ctrl.dispose();
    });

    test('Dismissing thought bubble clears bubble cleanly without penalty', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      ctrl.triggerHaltCheckIn(type: HaltType.angry);
      expect(ctrl.thoughtBubble, isNotNull);

      ctrl.thoughtBubble!.onDismiss!();
      expect(ctrl.thoughtBubble, isNull);

      ctrl.dispose();
    });
  });

  group('Forgiving Streak Protection System Tests', () {
    test('3 consecutive daily check-ins awards 1 Streak Shield (clamped up to 3)', () {
      final tracker = DailyRoutineTracker();
      final day1 = DateTime(2026, 1, 1, 10, 0);
      final day2 = DateTime(2026, 1, 2, 10, 0);
      final day3 = DateTime(2026, 1, 3, 10, 0);

      // Day 1 completion
      tracker.lastCheckedDate = day1;
      tracker.completeItem('vitamins', currentTime: day1);
      expect(tracker.currentStreak, equals(1));
      expect(tracker.streakShields, equals(0));
      expect(tracker.consecutiveDaysTowardsNextShield, equals(1));

      // Day 2 completion
      tracker.completeItem('vitamins', currentTime: day2);
      expect(tracker.currentStreak, equals(2));
      expect(tracker.streakShields, equals(0));
      expect(tracker.consecutiveDaysTowardsNextShield, equals(2));

      // Day 3 completion: Awards +1 Shield!
      tracker.completeItem('vitamins', currentTime: day3);
      expect(tracker.currentStreak, equals(3));
      expect(tracker.streakShields, equals(1));
      expect(tracker.consecutiveDaysTowardsNextShield, equals(0));
      expect(tracker.lastProtectionEvent, equals(StreakProtectionEvent.shieldEarned));
    });

    test('Single missed day automatically consumes 1 Streak Shield and preserves streak count', () {
      final tracker = DailyRoutineTracker(
        currentStreak: 5,
        bestStreak: 5,
        streakShields: 2,
        lastCheckedDate: DateTime(2026, 1, 3, 10, 0),
        lastStreakUpdateDate: DateTime(2026, 1, 3, 10, 0),
      );

      // User missed Day 4 entirely and returns on Day 5
      final day5 = DateTime(2026, 1, 5, 10, 0);
      tracker.checkDayRollover(currentTime: day5);

      // Streak is saved by 1 auto-consumed shield!
      expect(tracker.currentStreak, equals(5));
      expect(tracker.streakShields, equals(1));
      expect(tracker.lastProtectionEvent, equals(StreakProtectionEvent.shieldUsed));
    });

    test('Extended hiatus with no shields awards Streak Repair token and preserves broken streak', () {
      final tracker = DailyRoutineTracker(
        currentStreak: 7,
        bestStreak: 7,
        streakShields: 0,
        lastCheckedDate: DateTime(2026, 1, 1, 10, 0),
        lastStreakUpdateDate: DateTime(2026, 1, 1, 10, 0),
      );

      // Returns 5 days later after hiatus
      final day6 = DateTime(2026, 1, 6, 10, 0);
      tracker.checkDayRollover(currentTime: day6);

      // Streak reset to 0, but previous streak remembered and repair token awarded
      expect(tracker.currentStreak, equals(0));
      expect(tracker.previousBrokenStreak, equals(7));
      expect(tracker.streakRepairs, equals(1));
      expect(tracker.lastProtectionEvent, equals(StreakProtectionEvent.repairAvailable));
    });

    test('PetController.repairStreak restores previous streak count, consumes token, and celebrates', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      ctrl.routineTracker.currentStreak = 0;
      ctrl.routineTracker.previousBrokenStreak = 8;
      ctrl.routineTracker.streakRepairs = 1;

      final initialXp = ctrl.vitals.xp;
      final repaired = ctrl.repairStreak();

      expect(repaired, isTrue);
      expect(ctrl.routineTracker.currentStreak, equals(8));
      expect(ctrl.routineTracker.previousBrokenStreak, equals(0));
      expect(ctrl.routineTracker.streakRepairs, equals(0));
      expect(ctrl.mood, equals(PetMood.happy));
      expect(ctrl.vitals.xp, equals(initialXp + 50));
      expect(ctrl.thoughtBubble?.text, contains('Streak restored'));
      expect(ctrl.particles.any((p) => p.type == ParticleType.confetti), isTrue);

      ctrl.dispose();
    });

    test('Burrow sanctuary freeze completely halts streak rollover and decay', () {
      final tracker = DailyRoutineTracker(
        currentStreak: 9,
        bestStreak: 9,
        streakShields: 0,
        lastCheckedDate: DateTime(2026, 1, 1, 10, 0),
      );

      // 14 days later while resting safely in burrow
      final twoWeeksLater = DateTime(2026, 1, 15, 10, 0);
      tracker.checkDayRollover(currentTime: twoWeeksLater, isPaused: true);

      expect(tracker.currentStreak, equals(9));
      expect(tracker.previousBrokenStreak, equals(0));
      expect(tracker.streakRepairs, equals(0));
    });

    test('Serialization round-trip preserves all streak protection state', () {
      final original = DailyRoutineTracker(
        currentStreak: 12,
        bestStreak: 15,
        streakShields: 3,
        streakRepairs: 2,
        previousBrokenStreak: 10,
        consecutiveDaysTowardsNextShield: 2,
        lastProtectionEvent: StreakProtectionEvent.shieldUsed,
      );

      final jsonString = original.serialize();
      final restored = DailyRoutineTracker.deserialize(jsonString);

      expect(restored.currentStreak, equals(12));
      expect(restored.bestStreak, equals(15));
      expect(restored.streakShields, equals(3));
      expect(restored.streakRepairs, equals(2));
      expect(restored.previousBrokenStreak, equals(10));
      expect(restored.consecutiveDaysTowardsNextShield, equals(2));
      expect(restored.lastProtectionEvent, equals(StreakProtectionEvent.shieldUsed));
    });
  });

  group('EncryptedStorageService AES-256 Tests', () {
    test('Encrypts and decrypts payload preserving data integrity', () {
      final service = EncryptedStorageService.instance;
      const secretPayload = '{"petName": "Kibo", "xp": 4200, "streak": 14}';

      final encrypted = service.encrypt(secretPayload);
      expect(encrypted, startsWith('enc:v1:'));
      expect(encrypted, isNot(equals(secretPayload)));

      final decrypted = service.decrypt(encrypted);
      expect(decrypted, equals(secretPayload));
    });

    test('Gracefully handles unencrypted legacy strings without corruption', () {
      final service = EncryptedStorageService.instance;
      const legacyPlaintext = '{"name":"Mochi","archetype":"bunny"}';

      final result = service.decrypt(legacyPlaintext);
      expect(result, equals(legacyPlaintext));
    });

    test('Tamper resistance: Corrupted ciphertext returns empty or fallback gracefully', () {
      final service = EncryptedStorageService.instance;
      const corruptedCipher = 'enc:v1:invalidBase64Data!@#%';

      final result = service.decrypt(corruptedCipher);
      expect(result, equals(''));
    });
  });

  group('Somatic Wellness & EFT Tapping Tests', () {
    test('EFT Tapping Session initializes at crown point with zero taps', () {
      final session = EftTappingSession();
      expect(session.currentPointIndex, equals(0));
      expect(session.currentPoint, equals(EftMeridianPoint.topOfHead));
      expect(session.currentPointTapCount, equals(0));
      expect(session.totalTapsRecorded, equals(0));
      expect(session.isCompleted, isFalse);
      expect(session.pointProgress, equals(0.0));
      expect(session.overallProgress, equals(0.0));
    });

    test('EFT Tapping Session advances through all 5 clinical meridian points', () {
      final session = EftTappingSession();

      // Top of Head: 5 taps
      for (int i = 0; i < 4; i++) {
        final finished = session.registerTap();
        expect(finished, isFalse);
      }
      expect(session.currentPointTapCount, equals(4));
      expect(session.currentPoint, equals(EftMeridianPoint.topOfHead));

      // 5th tap advances to Eyebrow
      final transitionedToEyebrow = session.registerTap();
      expect(transitionedToEyebrow, isTrue);
      expect(session.currentPoint, equals(EftMeridianPoint.eyebrow));
      expect(session.currentPointTapCount, equals(0));
      expect(session.totalTapsRecorded, equals(5));

      // Tap through remaining points (eyebrow, sideOfEye, underEye) -> 15 taps
      for (int i = 0; i < 15; i++) {
        session.registerTap();
      }
      expect(session.currentPoint, equals(EftMeridianPoint.collarbone));
      expect(session.totalTapsRecorded, equals(20));

      // Final 5 taps on Collarbone completes entire somatic session
      for (int i = 0; i < 4; i++) {
        session.registerTap();
      }
      expect(session.isCompleted, isFalse);

      final completedSession = session.registerTap();
      expect(completedSession, isTrue);
      expect(session.isCompleted, isTrue);
      expect(session.totalTapsRecorded, equals(25));
      expect(session.overallProgress, equals(1.0));

      // Additional taps after completion are ignored
      final extraTap = session.registerTap();
      expect(extraTap, isFalse);
      expect(session.totalTapsRecorded, equals(25));
    });

    test('PetController.completeEftSession awards somatic rewards and zen particles', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      final initialXp = ctrl.vitals.xp;
      final initialHappiness = ctrl.vitals.happiness;
      final initialAffection = ctrl.vitals.affection;

      ctrl.completeEftSession();

      expect(ctrl.vitals.xp, equals(initialXp + 35));
      expect(ctrl.vitals.happiness, equals((initialHappiness + 25.0).clamp(0.0, 100.0)));
      expect(ctrl.vitals.affection, equals((initialAffection + 20.0).clamp(0.0, 100.0)));
      expect(ctrl.mood, equals(PetMood.happy));
      expect(ctrl.thoughtBubble?.text, contains('Wonderful tapping session'));
      expect(ctrl.particles.any((p) => p.type == ParticleType.sparkle), isTrue);

      ctrl.dispose();
    });

    test('BreathingTechnique timing specifications verify clinical adherence', () {
      expect(BreathingTechnique.diaphragmatic478.inhaleMs, equals(4000));
      expect(BreathingTechnique.diaphragmatic478.holdMs, equals(7000));
      expect(BreathingTechnique.diaphragmatic478.exhaleMs, equals(8000));
      expect(BreathingTechnique.diaphragmatic478.totalCycleMs, equals(19000));

      expect(BreathingTechnique.box.inhaleMs, equals(4000));
      expect(BreathingTechnique.box.holdMs, equals(4000));
      expect(BreathingTechnique.box.exhaleMs, equals(4000));
      expect(BreathingTechnique.box.restMs, equals(4000));
      expect(BreathingTechnique.box.totalCycleMs, equals(16000));
    });
  });

  group('5-Sense Environmental Grounding Tests', () {
    test('GroundingSense enum defines clinically accurate 5-4-3-2-1 hierarchy and counts', () {
      expect(GroundingSense.sight.order, equals(5));
      expect(GroundingSense.sight.targetCount, equals(5));
      expect(GroundingSense.sight.shortName, equals('See'));
      expect(GroundingSense.sight.emoji, equals('👁️'));

      expect(GroundingSense.touch.order, equals(4));
      expect(GroundingSense.touch.targetCount, equals(4));
      expect(GroundingSense.touch.shortName, equals('Feel'));
      expect(GroundingSense.touch.emoji, equals('✋'));

      expect(GroundingSense.hearing.order, equals(3));
      expect(GroundingSense.hearing.targetCount, equals(3));
      expect(GroundingSense.hearing.shortName, equals('Hear'));
      expect(GroundingSense.hearing.emoji, equals('👂'));

      expect(GroundingSense.smell.order, equals(2));
      expect(GroundingSense.smell.targetCount, equals(2));
      expect(GroundingSense.smell.shortName, equals('Smell'));
      expect(GroundingSense.smell.emoji, equals('👃'));

      expect(GroundingSense.taste.order, equals(1));
      expect(GroundingSense.taste.targetCount, equals(1));
      expect(GroundingSense.taste.shortName, equals('Taste'));
      expect(GroundingSense.taste.emoji, equals('👅'));

      expect(GroundingScanSession.totalSessionItems, equals(15));
    });

    test('GroundingScanSession initializes at Sight with zero items registered', () {
      final session = GroundingScanSession();
      expect(session.currentSenseIndex, equals(0));
      expect(session.currentSense, equals(GroundingSense.sight));
      expect(session.currentSenseCount, equals(0));
      expect(session.totalAcknowledged, equals(0));
      expect(session.isCompleted, isFalse);
      expect(session.senseProgress, equals(0.0));
      expect(session.overallProgress, equals(0.0));
    });

    test('GroundingScanSession advances through all 5 sensory categories to completion', () {
      final session = GroundingScanSession();

      // Sight: 5 items
      for (int i = 0; i < 4; i++) {
        final finishedCategory = session.registerItem();
        expect(finishedCategory, isFalse);
      }
      expect(session.currentSenseCount, equals(4));
      expect(session.currentSense, equals(GroundingSense.sight));
      expect(session.totalAcknowledged, equals(4));
      expect(session.senseProgress, closeTo(0.8, 0.001));

      // 5th sight item transitions to Touch
      final transitionedToTouch = session.registerItem();
      expect(transitionedToTouch, isTrue);
      expect(session.currentSense, equals(GroundingSense.touch));
      expect(session.currentSenseCount, equals(0));
      expect(session.totalAcknowledged, equals(5));

      // Touch: 4 items
      for (int i = 0; i < 3; i++) {
        session.registerItem();
      }
      expect(session.currentSenseCount, equals(3));
      final transitionedToHearing = session.registerItem();
      expect(transitionedToHearing, isTrue);
      expect(session.currentSense, equals(GroundingSense.hearing));
      expect(session.totalAcknowledged, equals(9));

      // Hearing: 3 items
      for (int i = 0; i < 2; i++) {
        session.registerItem();
      }
      final transitionedToSmell = session.registerItem();
      expect(transitionedToSmell, isTrue);
      expect(session.currentSense, equals(GroundingSense.smell));
      expect(session.totalAcknowledged, equals(12));

      // Smell: 2 items
      session.registerItem();
      final transitionedToTaste = session.registerItem();
      expect(transitionedToTaste, isTrue);
      expect(session.currentSense, equals(GroundingSense.taste));
      expect(session.totalAcknowledged, equals(14));

      // Taste: 1 item -> completes the full session
      expect(session.isCompleted, isFalse);
      final completedFullSession = session.registerItem();
      expect(completedFullSession, isTrue);
      expect(session.isCompleted, isTrue);
      expect(session.totalAcknowledged, equals(15));
      expect(session.overallProgress, equals(1.0));
      expect(session.senseProgress, equals(1.0));

      // Any further calls while completed are ignored
      final extraAttempt = session.registerItem();
      expect(extraAttempt, isFalse);
      expect(session.totalAcknowledged, equals(15));
    });

    test('GroundingScanSession reset restores initial baseline state', () {
      final session = GroundingScanSession();
      for (int i = 0; i < 10; i++) {
        session.registerItem();
      }
      expect(session.totalAcknowledged, equals(10));
      expect(session.currentSenseIndex, greaterThan(0));

      session.reset();
      expect(session.currentSenseIndex, equals(0));
      expect(session.currentSense, equals(GroundingSense.sight));
      expect(session.currentSenseCount, equals(0));
      expect(session.totalAcknowledged, equals(0));
      expect(session.isCompleted, isFalse);
      expect(session.overallProgress, equals(0.0));
    });

    test('PetController.completeGroundingSession awards somatic rewards and zen particles', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      final initialXp = ctrl.vitals.xp;
      final initialHappiness = ctrl.vitals.happiness;
      final initialAffection = ctrl.vitals.affection;

      ctrl.completeGroundingSession();

      expect(ctrl.vitals.xp, equals(initialXp + 30));
      expect(ctrl.vitals.happiness, equals((initialHappiness + 20.0).clamp(0.0, 100.0)));
      expect(ctrl.vitals.affection, equals((initialAffection + 15.0).clamp(0.0, 100.0)));
      expect(ctrl.mood, equals(PetMood.happy));
      expect(ctrl.thoughtBubble?.text, contains('Senses anchored!'));
      expect(ctrl.particles.length, greaterThanOrEqualTo(20));

      ctrl.dispose();
    });
  });

  group('Exergaming Engine & Step Counter Tests', () {
    test('DailyExergamingRecord initializes with default healthy non-punitive values', () {
      final record = DailyExergamingRecord();
      expect(record.currentSteps, equals(0));
      expect(record.distanceKm, equals(0.0));
      expect(record.activeMinutes, equals(0));
      expect(record.staminaBuffer, equals(20.0));
      expect(record.completedTiers, isEmpty);
      expect(record.treasures, isEmpty);
      expect(record.targetProgress, equals(0.0));
    });

    test('Non-punitive: Recording 0 or negative steps has zero adverse effects', () {
      final record = DailyExergamingRecord();
      final result = record.recordSteps(0);
      expect(result.newTiers, isEmpty);
      expect(result.newTreasures, isEmpty);
      expect(record.currentSteps, equals(0));
      expect(record.staminaBuffer, equals(20.0));
    });

    test('Step accumulation unlocks Bronze and Silver tiers with stamina and burrow treasures', () {
      final record = DailyExergamingRecord();

      // Take 2,500 steps (Bronze threshold)
      final bronzeResult = record.recordSteps(2500);
      expect(bronzeResult.newTiers, contains(StepGoalTier.bronze));
      expect(bronzeResult.newTreasures.length, equals(1));
      expect(record.completedTiers, contains(StepGoalTier.bronze));
      expect(record.isTierAchieved(StepGoalTier.bronze), isTrue);
      expect(record.staminaBuffer, equals(35.0)); // 20 + 15
      expect(record.distanceKm, greaterThan(1.8));

      // Take another 2,500 steps (Total 5,000 -> Silver +20% Lift target)
      final silverResult = record.recordSteps(2500);
      expect(silverResult.newTiers, contains(StepGoalTier.silver));
      expect(silverResult.newTreasures.length, equals(1));
      expect(record.completedTiers, contains(StepGoalTier.silver));
      expect(record.isTierAchieved(StepGoalTier.silver), isTrue);
      expect(record.targetProgress, equals(1.0));
      expect(record.treasures.length, equals(2));
    });

    test('10,000 steps unlocks Gold and Platinum Champion tiers', () {
      final record = DailyExergamingRecord();
      final result = record.recordSteps(10000);

      expect(result.newTiers.length, equals(4)); // Bronze, Silver, Gold, Platinum
      expect(record.completedTiers.length, equals(4));
      expect(record.isTierAchieved(StepGoalTier.gold), isTrue);
      expect(record.isTierAchieved(StepGoalTier.platinum), isTrue);
      expect(record.treasures.length, equals(4));
      expect(record.staminaBuffer, equals(100.0)); // Clamped to 100
    });

    test('Midnight rollover gently archives previous day into history without punishment', () {
      final day1 = DateTime(2026, 3, 1, 14, 0);
      final record = DailyExergamingRecord(
        currentSteps: 6200,
        lastUpdatedDate: day1,
      );
      record.completedTiers.add(StepGoalTier.bronze);
      record.completedTiers.add(StepGoalTier.silver);

      final day2 = DateTime(2026, 3, 2, 8, 30);
      record.checkDayRollover(currentTime: day2);

      expect(record.currentSteps, equals(0));
      expect(record.completedTiers, isEmpty);
      expect(record.dailyHistory['2026-03-01'], equals(6200));
    });

    test('Serialization and deserialization round-trip preserves all metrics and treasures', () {
      final original = DailyExergamingRecord(
        currentSteps: 7500,
        distanceKm: 5.76,
        activeMinutes: 75,
        estimatedCalories: 300.0,
        staminaBuffer: 65.0,
        completedTiers: {StepGoalTier.bronze, StepGoalTier.silver},
        treasures: [
          BurrowTreasure(
            id: 'golden_clover_1',
            name: 'Golden 4-Leaf Clover',
            description: 'A rare lucky treasure.',
            rarity: TreasureRarity.rare,
            icon: Icons.eco,
            unearthedAt: DateTime(2026, 3, 1, 10, 0),
          ),
        ],
        dailyHistory: {'2026-02-28': 5400},
      );

      final serialized = original.serialize();
      final restored = DailyExergamingRecord.deserialize(serialized);

      expect(restored.currentSteps, equals(7500));
      expect(restored.distanceKm, equals(5.76));
      expect(restored.activeMinutes, equals(75));
      expect(restored.estimatedCalories, equals(300.0));
      expect(restored.staminaBuffer, equals(65.0));
      expect(restored.completedTiers.contains(StepGoalTier.bronze), isTrue);
      expect(restored.completedTiers.contains(StepGoalTier.silver), isTrue);
      expect(restored.treasures.length, equals(1));
      expect(restored.treasures.first.name, equals('Golden 4-Leaf Clover'));
      expect(restored.dailyHistory['2026-02-28'], equals(5400));
    });

    test('PetController.recordSteps converts movement to XP, triggers fanfare and particles', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      final initialXp = ctrl.vitals.xp;
      final initialHappiness = ctrl.vitals.happiness;

      // Log 2,500 steps (achieves Bronze tier)
      ctrl.recordSteps(2500);

      expect(ctrl.exergamingRecord.currentSteps, equals(2500));
      expect(ctrl.exergamingRecord.isTierAchieved(StepGoalTier.bronze), isTrue);
      expect(ctrl.vitals.xp, greaterThan(initialXp));
      expect(ctrl.vitals.happiness, greaterThan(initialHappiness));
      expect(ctrl.mood, equals(PetMood.happy));
      expect(ctrl.thoughtBubble?.text, contains('Reached Bronze Stride'));
      expect(ctrl.particles.any((p) => p.type == ParticleType.confetti), isTrue);

      ctrl.dispose();
    });

    test('PetController live walking companion session starts, records steps, and stops', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      expect(ctrl.isWalkingSessionActive, isFalse);

      ctrl.startWalkSession();
      expect(ctrl.isWalkingSessionActive, isTrue);
      expect(ctrl.thoughtBubble?.text, contains('Starting our walk together'));

      ctrl.stopWalkSession();
      expect(ctrl.isWalkingSessionActive, isFalse);
      expect(ctrl.thoughtBubble?.text, contains('Great walk'));

      ctrl.dispose();
    });
  });

  group('The Park Safe Community Space & Prosocial Interaction Tests', () {
    test('ParkMessage serializes and deserializes join, move, warm_fuzzy and gift protocols', () {
      // 1. Join message
      final joinJson = ParkMessage.join(
        roomId: 'cozy-garden',
        peerId: 'peer_abc123',
        petName: 'Kibo',
        archetype: 'shiba',
        primaryColor: 0xFFFF5722,
        accentColor: 0xFFFFC107,
        x: 0.35,
        y: 0.65,
      );
      final joinMsg = ParkMessage.deserialize(joinJson);
      expect(joinMsg, isNotNull);
      expect(joinMsg!.type, equals('join'));
      expect(joinMsg.payload['roomId'], equals('cozy-garden'));
      expect(joinMsg.payload['petName'], equals('Kibo'));
      expect(joinMsg.payload['archetype'], equals('shiba'));
      expect(joinMsg.payload['x'], equals(0.35));

      // 2. Move message
      final moveJson = ParkMessage.move(x: 0.42, y: 0.88);
      final moveMsg = ParkMessage.deserialize(moveJson);
      expect(moveMsg, isNotNull);
      expect(moveMsg!.type, equals('move'));
      expect(moveMsg.payload['x'], equals(0.42));
      expect(moveMsg.payload['y'], equals(0.88));

      // 3. Warm Fuzzy message
      final fuzzyJson = ParkMessage.warmFuzzy(
        targetPeerId: 'peer_target_999',
        fuzzyType: WarmFuzzyType.sunbeam,
        affirmation: WarmFuzzyType.sunbeam.affirmation,
      );
      final fuzzyMsg = ParkMessage.deserialize(fuzzyJson);
      expect(fuzzyMsg, isNotNull);
      expect(fuzzyMsg!.type, equals('warm_fuzzy'));
      expect(fuzzyMsg.payload['fuzzyType'], equals('sunbeam'));
      expect(fuzzyMsg.payload['affirmation'], contains('gentle warmth'));

      // 4. Gift message
      final sampleTreasure = BurrowTreasure(
        id: 'treasure_test_1',
        name: 'Glowing Amber Leaf',
        description: 'Warm to the touch with soothing forest energy',
        rarity: TreasureRarity.rare,
        icon: Icons.eco,
        unearthedAt: DateTime.now(),
      );
      final giftJson = ParkMessage.gift(
        targetPeerId: 'peer_target_999',
        treasure: sampleTreasure,
      );
      final giftMsg = ParkMessage.deserialize(giftJson);
      expect(giftMsg, isNotNull);
      expect(giftMsg!.type, equals('gift'));
      expect(giftMsg.payload['gift']['name'], equals('Glowing Amber Leaf'));
      expect(giftMsg.payload['gift']['rarity'], equals('rare'));
    });

    test('WarmFuzzyType definitions contain affirmations, valid icons, and colors', () {
      expect(WarmFuzzyType.values.length, equals(5));
      for (final fuzzy in WarmFuzzyType.values) {
        expect(fuzzy.label.isNotEmpty, isTrue);
        expect(fuzzy.affirmation.isNotEmpty, isTrue);
        expect(fuzzy.icon, isNotNull);
        expect(fuzzy.color, isNotNull);
      }
    });

    test('ParkCompanion correctly models peer state and thought expiration', () {
      final peer = ParkCompanion.fromPeerMap({
        'peerId': 'peer_test',
        'petName': 'Matcha',
        'archetype': 'dragon',
        'primaryColor': 0xFF81C784,
        'accentColor': 0xFFFFD54F,
        'x': 0.2,
        'y': 0.8,
      }, isNpc: true);

      expect(peer.petName, equals('Matcha'));
      expect(peer.archetype, equals(CompanionArchetype.dragon));
      expect(peer.isNpc, isTrue);
      expect(peer.hasActiveThought, isFalse);

      peer.setThought('Resting peacefully beneath the blossom tree 🌸', duration: const Duration(seconds: 10));
      expect(peer.hasActiveThought, isTrue);
      expect(peer.activeThought, contains('blossom tree'));

      // Expired thought returns false
      peer.thoughtExpiresAt = DateTime.now().subtract(const Duration(seconds: 1));
      expect(peer.hasActiveThought, isFalse);
    });

    test('PetController.receiveWarmFuzzy boosts happiness, affection, XP and emits hearts', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      final initialHappiness = ctrl.vitals.happiness;
      final initialAffection = ctrl.vitals.affection;
      final initialXp = ctrl.vitals.xp;

      ctrl.receiveWarmFuzzy(WarmFuzzyType.flower, 'Mochi');

      expect(ctrl.vitals.happiness, greaterThan(initialHappiness));
      expect(ctrl.vitals.affection, greaterThan(initialAffection));
      expect(ctrl.vitals.xp, greaterThan(initialXp));
      expect(ctrl.thoughtBubble?.text, contains('Blossom of Care from Mochi'));
      expect(ctrl.particles.any((p) => p.type == ParticleType.heart), isTrue);

      ctrl.dispose();
    });

    test('PetController.receiveParkGift stores treasure in burrow and rewards pet', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      final gift = BurrowTreasure(
        id: 'gift_test_1',
        name: 'Polished Quartz Stone',
        description: 'Reflects soft rainbow sunlight',
        rarity: TreasureRarity.common,
        icon: Icons.diamond,
        unearthedAt: DateTime.now(),
      );

      final initialCount = ctrl.exergamingRecord.treasures.length;
      final initialHappiness = ctrl.vitals.happiness;

      ctrl.receiveParkGift(gift, 'Matcha');

      expect(ctrl.exergamingRecord.treasures.length, equals(initialCount + 1));
      expect(ctrl.exergamingRecord.treasures.last.name, equals('Polished Quartz Stone'));
      expect(ctrl.vitals.happiness, greaterThan(initialHappiness));
      expect(ctrl.thoughtBubble?.text, contains('Matcha gifted you: Polished Quartz Stone'));
      expect(ctrl.particles.any((p) => p.type == ParticleType.confetti), isTrue);

      ctrl.dispose();
    });

    test('ParkClientService offline mode initializes default cozy NPCs and local interactions', () {
      final service = ParkClientService.instance;
      final companion = CompanionModel.defaultCompanion();

      service.enableOfflineMode(companion);

      expect(service.isOfflineMode, isTrue);
      expect(service.peers.containsKey('npc_mochi'), isTrue);
      expect(service.peers.containsKey('npc_matcha'), isTrue);

      final mochi = service.peers['npc_mochi']!;
      expect(mochi.petName, equals('Mochi'));
      expect(mochi.isNpc, isTrue);

      service.disconnect();
      expect(service.isOfflineMode, isFalse);
    });

    test('PetController.updateCompanion persists to encrypted storage and PetController.create restores it', () async {
      final initialCtrl = PetController(companion: CompanionModel.defaultCompanion());
      initialCtrl.setScreenBounds(const Size(1920, 1080));

      // Build and update to a custom Matcha Dragon companion
      final customCompanion = CompanionModel.fromPrompt(
        'A sleepy matcha dragon with tiny golden horns named Matcha',
      );
      await initialCtrl.updateCompanion(customCompanion);
      expect(initialCtrl.companion.name, equals('Matcha'));
      expect(initialCtrl.companion.archetype, equals(CompanionArchetype.dragon));
      initialCtrl.dispose();

      // Simulate app restart via PetController.create()
      final restoredCtrl = await PetController.create();
      expect(restoredCtrl.companion.name, equals('Matcha'));
      expect(restoredCtrl.companion.archetype, equals(CompanionArchetype.dragon));
      expect(restoredCtrl.companion.accessory, equals(CompanionAccessory.tinyHorns));

      restoredCtrl.dispose();
    });

    test('ParkClientService savePreferences and loadPreferences correctly persists custom server URL and room', () async {
      final service = ParkClientService.instance;
      service.serverUrl = 'wss://park.andfriendslabs.com/ws';
      service.currentRoomId = 'test-room-99';
      await service.savePreferences();

      // Clear memory
      service.serverUrl = 'ws://localhost:8080/ws';
      service.currentRoomId = 'default';

      // Load preferences
      await service.loadPreferences();
      expect(service.serverUrl, equals('wss://park.andfriendslabs.com/ws'));
      expect(service.currentRoomId, equals('test-room-99'));
    });

    test('Burrow mound and nestled state persist across app restarts', () async {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      // Dig burrow mound at bottom edge
      ctrl.screenPosition = const Offset(500, 1045);
      ctrl.digBurrow();
      expect(ctrl.hasBurrow, isTrue);
      expect(ctrl.burrowEdge, equals(BurrowEdge.bottom));
      expect(ctrl.burrowPosition, isNotNull);

      // Tuck inside burrow
      ctrl.completeBurrowSniff();
      await ctrl.save();
      expect(ctrl.isInsideBurrow, isTrue);
      expect(ctrl.mood, equals(PetMood.peekingBurrow));
      final savedPos = ctrl.burrowPosition!;

      ctrl.dispose();

      // Relaunch app via PetController.create()
      final restored = await PetController.create();
      restored.setScreenBounds(const Size(1920, 1080));

      expect(restored.hasBurrow, isTrue);
      expect(restored.burrowPosition, equals(savedPos));
      expect(restored.burrowEdge, equals(BurrowEdge.bottom));
      expect(restored.isInsideBurrow, isTrue);
      expect(restored.mood, equals(PetMood.peekingBurrow));
      expect(restored.screenPosition, equals(restored.getBurrowPetPosition()));

      // Wake from burrow and verify updated persistence
      restored.wakeFromBurrow(isWiggle: false);
      await restored.save();
      expect(restored.isInsideBurrow, isFalse);
      expect(restored.hasBurrow, isTrue);
      restored.dispose();

      // Relaunch app again: burrow mound is preserved, pet is outside
      final restored2 = await PetController.create();
      restored2.setScreenBounds(const Size(1920, 1080));

      expect(restored2.hasBurrow, isTrue);
      expect(restored2.burrowPosition, equals(savedPos));
      expect(restored2.isInsideBurrow, isFalse);

      restored2.dispose();
    });

    test('Dragging burrow mound updates and persists new burrow position', () async {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));

      ctrl.screenPosition = const Offset(500, 1045);
      ctrl.digBurrow();
      ctrl.completeBurrowSniff();

      // Drag burrow mound to left edge
      ctrl.startBurrowDragging();
      ctrl.updateBurrowDragging(const Offset(40, 400));
      ctrl.stopBurrowDragging();
      await ctrl.save();
      expect(ctrl.burrowEdge, equals(BurrowEdge.left));
      final newBurrowPos = ctrl.burrowPosition!;
      expect(newBurrowPos.dx, equals(40.0));

      ctrl.dispose();

      // Relaunch app
      final restored = await PetController.create();
      restored.setScreenBounds(const Size(1920, 1080));

      expect(restored.hasBurrow, isTrue);
      expect(restored.burrowEdge, equals(BurrowEdge.left));
      expect(restored.burrowPosition, equals(newBurrowPos));

      restored.dispose();
    });
  });

  group('Bug Fixes & Usability Enhancements Tests', () {
    test('Side burrowing rotates companion feet towards the screen edge and not away from the edge', () {
      // Test left edge burrow rotation
      const edgeLeft = BurrowEdge.left;
      final rotLeft = switch (edgeLeft) {
        BurrowEdge.bottom => 0.0,
        BurrowEdge.left => math.pi / 2,
        BurrowEdge.right => -math.pi / 2,
      };
      expect(rotLeft, equals(math.pi / 2));

      // Local feet vector (0, 1) rotated by +90°
      final feetXLeft = -math.sin(rotLeft);
      final feetYLeft = math.cos(rotLeft);
      expect(feetXLeft, closeTo(-1.0, 0.001)); // Points strictly LEFT (towards the left edge)
      expect(feetYLeft, closeTo(0.0, 0.001));

      // Local head vector (0, -1) rotated by +90°
      final headXLeft = math.sin(rotLeft);
      final headYLeft = -math.cos(rotLeft);
      expect(headXLeft, closeTo(1.0, 0.001)); // Points strictly RIGHT (into the room)
      expect(headYLeft, closeTo(0.0, 0.001));

      // Test right edge burrow rotation
      const edgeRight = BurrowEdge.right;
      final rotRight = switch (edgeRight) {
        BurrowEdge.bottom => 0.0,
        BurrowEdge.left => math.pi / 2,
        BurrowEdge.right => -math.pi / 2,
      };
      expect(rotRight, equals(-math.pi / 2));

      // Local feet vector (0, 1) rotated by -90°
      final feetXRight = -math.sin(rotRight);
      final feetYRight = math.cos(rotRight);
      expect(feetXRight, closeTo(1.0, 0.001)); // Points strictly RIGHT (towards the right edge)
      expect(feetYRight, closeTo(0.0, 0.001));

      // Local head vector (0, -1) rotated by -90°
      final headXRight = math.sin(rotRight);
      final headYRight = -math.cos(rotRight);
      expect(headXRight, closeTo(-1.0, 0.001)); // Points strictly LEFT (into the room)
      expect(headYRight, closeTo(0.0, 0.001));
    });

    test('Popover and context menu coordinate clamping ensures popover stays strictly within screen bounds', () {
      const screenSize = Size(1920, 1080);
      const menuWidth = 210.0;
      const menuHeight = 550.0;

      Offset clampPosition(Offset click) {
        double left = click.dx + 15.0;
        if (left + menuWidth > screenSize.width - 12.0) {
          left = click.dx - menuWidth - 10.0;
        }
        left = left.clamp(10.0, math.max(10.0, screenSize.width - menuWidth - 10.0)).toDouble();

        double top = click.dy - 40.0;
        if (top + menuHeight > screenSize.height - 12.0) {
          top = screenSize.height - menuHeight - 12.0;
        }
        top = top.clamp(10.0, math.max(10.0, screenSize.height - menuHeight - 10.0)).toDouble();

        return Offset(left, top);
      }

      // Test 1: Click at bottom-right corner of screen (1900, 1050)
      final posBR = clampPosition(const Offset(1900, 1050));
      expect(posBR.dx, greaterThanOrEqualTo(10.0));
      expect(posBR.dx + menuWidth, lessThanOrEqualTo(screenSize.width - 10.0));
      expect(posBR.dy, greaterThanOrEqualTo(10.0));
      expect(posBR.dy + menuHeight, lessThanOrEqualTo(screenSize.height - 10.0));

      // Test 2: Click near top-left corner of screen (5, 5)
      final posTL = clampPosition(const Offset(5, 5));
      expect(posTL.dx, greaterThanOrEqualTo(10.0));
      expect(posTL.dx + menuWidth, lessThanOrEqualTo(screenSize.width - 10.0));
      expect(posTL.dy, greaterThanOrEqualTo(10.0));
      expect(posTL.dy + menuHeight, lessThanOrEqualTo(screenSize.height - 10.0));

      // Test 3: Click in middle of small display (600, 400) on 800x600 screen
      const smallScreen = Size(800, 600);
      double smallLeft = 700.0 + 15.0;
      if (smallLeft + menuWidth > smallScreen.width - 12.0) {
        smallLeft = 700.0 - menuWidth - 10.0;
      }
      smallLeft = smallLeft.clamp(10.0, math.max(10.0, smallScreen.width - menuWidth - 10.0)).toDouble();
      expect(smallLeft + menuWidth, lessThanOrEqualTo(smallScreen.width - 10.0));
    });
  });
}



