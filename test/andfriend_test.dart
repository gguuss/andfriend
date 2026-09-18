import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andfriend/controllers/pet_controller.dart';
import 'package:andfriend/core/desktop_scanner.dart';
import 'package:andfriend/models/companion_model.dart';
import 'package:andfriend/models/mindfulness_state.dart';
import 'package:andfriend/models/pet_state.dart';
import 'package:andfriend/models/routine_state.dart';
import 'package:andfriend/models/trick_system.dart';
import 'package:andfriend/graphics/particle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

      // Drag burrow to new coordinate
      ctrl.startBurrowDragging();
      expect(ctrl.isBurrowDragging, isTrue);

      ctrl.updateBurrowDragging(const Offset(400, 700));
      expect(ctrl.burrowPosition, equals(const Offset(400, 700)));

      ctrl.stopBurrowDragging();
      expect(ctrl.isBurrowDragging, isFalse);

      ctrl.dispose();
    });

    test('Dragging burrow while friend is inside moves friend along with it', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.hasBurrow = true;
      ctrl.burrowPosition = const Offset(500, 800);
      ctrl.isInsideBurrow = true;
      ctrl.screenPosition = const Offset(500, 785);

      ctrl.startBurrowDragging();
      ctrl.updateBurrowDragging(const Offset(900, 600));

      expect(ctrl.burrowPosition, equals(const Offset(900, 600)));
      expect(ctrl.screenPosition, equals(const Offset(900, 585)));

      ctrl.stopBurrowDragging();
      ctrl.dispose();
    });

    test('When friend burrows from a distance, friend travels to the burrow', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.hasBurrow = true;
      ctrl.burrowPosition = const Offset(200, 800);
      ctrl.isInsideBurrow = false;
      ctrl.screenPosition = const Offset(1200, 800); // 1000px away!

      ctrl.toggleBurrowPeek();

      // Travel has been initiated
      expect(ctrl.travelTarget, isNotNull);
      expect(ctrl.travelTarget, equals(const Offset(200, 785)));
      expect(ctrl.mood, equals(PetMood.wandering));
      expect(ctrl.wanderDirection, equals(-1.0)); // Facing left towards burrow

      // Fast-forward position to destination
      ctrl.screenPosition = ctrl.travelTarget!;
      ctrl.toggleBurrowPeek(); // Arrives & hops in
      expect(ctrl.isInsideBurrow, isTrue);
      expect(ctrl.mood, equals(PetMood.peekingBurrow));

      ctrl.dispose();
    });

    test('Tucking inside burrow starts burrow nap, recovers energy, and unsnugs cleanly', () {
      final ctrl = PetController(companion: CompanionModel.defaultCompanion());
      ctrl.setScreenBounds(const Size(1920, 1080));
      ctrl.hasBurrow = true;
      ctrl.burrowPosition = const Offset(300, 600);
      ctrl.screenPosition = const Offset(300, 585);
      ctrl.vitals.energy = 50.0;

      // Hop into burrow
      ctrl.toggleBurrowPeek();
      expect(ctrl.isInsideBurrow, isTrue);
      expect(ctrl.mood, equals(PetMood.peekingBurrow));

      // Fast-forward or trigger unsnug
      ctrl.unsnugFromBurrow();
      expect(ctrl.isInsideBurrow, isFalse);
      expect(ctrl.mood, equals(PetMood.idle));
      expect(ctrl.thoughtBubble?.text, contains('Popped out of the burrow'));
      expect(ctrl.particles.any((p) => p.type == ParticleType.sparkle || p.type == ParticleType.dirt), isTrue);

      ctrl.dispose();
    });
  });
}
