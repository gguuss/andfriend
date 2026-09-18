import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liil_buddy/core/desktop_scanner.dart';
import 'package:liil_buddy/models/companion_model.dart';
import 'package:liil_buddy/models/pet_state.dart';
import 'package:liil_buddy/models/trick_system.dart';

void main() {
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
}
