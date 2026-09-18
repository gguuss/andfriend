import 'dart:convert';
import 'package:flutter/material.dart';

enum CompanionArchetype {
  cat,
  fox,
  bunny,
  shiba,
  dragon,
  slime,
  customSprite,
}

enum CompanionAccessory {
  none,
  wizardHat,
  starBadge,
  cozyScarf,
  coolGlasses,
  tinyHorns,
  sakuraFlower,
}

enum PetPersonality {
  playful,
  sleepy,
  curious,
  energetic,
  foodie,
}

class CompanionModel {
  final String id;
  String name;
  CompanionArchetype archetype;
  Color primaryColor;
  Color secondaryColor;
  Color accentColor;
  Color eyeColor;
  CompanionAccessory accessory;
  Color accessoryColor;
  String? customSpritePath;
  PetPersonality personality;
  List<String> favoriteFileExtensions;
  Map<String, int> trickMastery; // trickId -> xp

  CompanionModel({
    required this.id,
    required this.name,
    required this.archetype,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.eyeColor,
    this.accessory = CompanionAccessory.none,
    this.accessoryColor = const Color(0xFFFFD700),
    this.customSpritePath,
    this.personality = PetPersonality.curious,
    List<String>? favoriteFileExtensions,
    Map<String, int>? trickMastery,
  })  : favoriteFileExtensions = favoriteFileExtensions ?? ['.dart', '.png', '.pdf', '.txt', '.json'],
        trickMastery = trickMastery ?? {
          'backflip': 0,
          'spin': 0,
          'playDead': 0,
          'beg': 0,
          'dance': 0,
          'highFive': 0,
        };

  /// Factory for default starter companion (Fox)
  factory CompanionModel.defaultCompanion() {
    return CompanionModel(
      id: 'default_kitsune',
      name: 'Liil Buddy',
      archetype: CompanionArchetype.fox,
      primaryColor: const Color(0xFFE67E22), // Warm Fox Orange
      secondaryColor: const Color(0xFFFFF8E7), // Cream belly
      accentColor: const Color(0xFFD35400), // Darker orange tail
      eyeColor: const Color(0xFF2C3E50), // Midnight navy eyes
      accessory: CompanionAccessory.starBadge,
      accessoryColor: const Color(0xFFFFD700),
      personality: PetPersonality.curious,
      favoriteFileExtensions: ['.dart', '.png', '.md', '.txt'],
    );
  }

  /// AI / Prompt-based Generator that translates natural language prompts into a unique companion
  factory CompanionModel.fromPrompt(String prompt) {
    final lower = prompt.toLowerCase();

    // 1. Determine Archetype
    CompanionArchetype archetype = CompanionArchetype.fox;
    if (lower.contains('cat') || lower.contains('neko') || lower.contains('kitten')) {
      archetype = CompanionArchetype.cat;
    } else if (lower.contains('bunny') || lower.contains('rabbit') || lower.contains('hare')) {
      archetype = CompanionArchetype.bunny;
    } else if (lower.contains('shiba') || lower.contains('dog') || lower.contains('puppy') || lower.contains('inu')) {
      archetype = CompanionArchetype.shiba;
    } else if (lower.contains('dragon') || lower.contains('dino') || lower.contains('lizard')) {
      archetype = CompanionArchetype.dragon;
    } else if (lower.contains('slime') || lower.contains('blob') || lower.contains('jelly')) {
      archetype = CompanionArchetype.slime;
    } else if (lower.contains('fox') || lower.contains('kitsune')) {
      archetype = CompanionArchetype.fox;
    }

    // 2. Determine Colors
    Color primary = const Color(0xFFE67E22);
    Color secondary = const Color(0xFFFFF8E7);
    Color accent = const Color(0xFFD35400);
    Color eyes = const Color(0xFF2C3E50);

    if (lower.contains('matcha') || lower.contains('green') || lower.contains('leaf') || lower.contains('forest') || lower.contains('mint')) {
      primary = const Color(0xFF58D68D);
      secondary = const Color(0xFFEAFAF1);
      accent = const Color(0xFF27AE60);
      eyes = const Color(0xFF1E8449);
    } else if (lower.contains('cyber') || lower.contains('neon') || lower.contains('blue') || lower.contains('galaxy') || lower.contains('space') || lower.contains('astro')) {
      primary = const Color(0xFF3498DB);
      secondary = const Color(0xFFEBF5FB);
      accent = const Color(0xFF8E44AD);
      eyes = const Color(0xFF00FFFF);
    } else if (lower.contains('pink') || lower.contains('sakura') || lower.contains('cherry') || lower.contains('sweet') || lower.contains('rose')) {
      primary = const Color(0xFFFF8DA1);
      secondary = const Color(0xFFFFF0F5);
      accent = const Color(0xFFFF5277);
      eyes = const Color(0xFF8E1B54);
    } else if (lower.contains('purple') || lower.contains('lavender') || lower.contains('violet') || lower.contains('mystic') || lower.contains('shadow')) {
      primary = const Color(0xFFA569BD);
      secondary = const Color(0xFFF4ECF7);
      accent = const Color(0xFF6C3483);
      eyes = const Color(0xFFFFD700);
    } else if (lower.contains('golden') || lower.contains('yellow') || lower.contains('sun') || lower.contains('honey') || lower.contains('lemon')) {
      primary = const Color(0xFFF4D03F);
      secondary = const Color(0xFFFEF9E7);
      accent = const Color(0xFFF39C12);
      eyes = const Color(0xFF7D6608);
    } else if (lower.contains('white') || lower.contains('snow') || lower.contains('cloud') || lower.contains('frost') || lower.contains('arctic')) {
      primary = const Color(0xFFF2F4F4);
      secondary = const Color(0xFFFFFFFF);
      accent = const Color(0xFFBDC3C7);
      eyes = const Color(0xFF3498DB);
    } else if (lower.contains('black') || lower.contains('dark') || lower.contains('goth') || lower.contains('midnight') || lower.contains('noir')) {
      primary = const Color(0xFF2C3E50);
      secondary = const Color(0xFF34495E);
      accent = const Color(0xFF1A252F);
      eyes = const Color(0xFFF1C40F);
    }

    // 3. Accessory
    CompanionAccessory accessory = CompanionAccessory.none;
    Color accessoryColor = const Color(0xFFFFD700);
    if (lower.contains('wizard') || lower.contains('magic') || lower.contains('witch') || lower.contains('sorcerer')) {
      accessory = CompanionAccessory.wizardHat;
      accessoryColor = const Color(0xFF5B2C6F);
    } else if (lower.contains('star') || lower.contains('astro') || lower.contains('badge') || lower.contains('medal')) {
      accessory = CompanionAccessory.starBadge;
      accessoryColor = const Color(0xFFFFD700);
    } else if (lower.contains('scarf') || lower.contains('cozy') || lower.contains('winter')) {
      accessory = CompanionAccessory.cozyScarf;
      accessoryColor = const Color(0xFFE74C3C);
    } else if (lower.contains('glasses') || lower.contains('shades') || lower.contains('cool') || lower.contains('nerd') || lower.contains('smart')) {
      accessory = CompanionAccessory.coolGlasses;
      accessoryColor = const Color(0xFF17202A);
    } else if (lower.contains('horn') || lower.contains('dragon') || lower.contains('devil')) {
      accessory = CompanionAccessory.tinyHorns;
      accessoryColor = const Color(0xFFC0392B);
    } else if (lower.contains('flower') || lower.contains('sakura') || lower.contains('blossom') || lower.contains('flora')) {
      accessory = CompanionAccessory.sakuraFlower;
      accessoryColor = const Color(0xFFFF69B4);
    }

    // 4. Personality
    PetPersonality personality = PetPersonality.curious;
    if (lower.contains('sleep') || lower.contains('lazy') || lower.contains('cozy') || lower.contains('calm')) {
      personality = PetPersonality.sleepy;
    } else if (lower.contains('play') || lower.contains('silly') || lower.contains('fun')) {
      personality = PetPersonality.playful;
    } else if (lower.contains('energy') || lower.contains('fast') || lower.contains('hyper') || lower.contains('zoom')) {
      personality = PetPersonality.energetic;
    } else if (lower.contains('food') || lower.contains('hungry') || lower.contains('snack') || lower.contains('sweet')) {
      personality = PetPersonality.foodie;
    }

    // 5. Name generation from prompt
    String name = 'Buddy';
    final words = prompt.trim().split(RegExp(r'\s+'));
    for (int i = 0; i < words.length; i++) {
      if (words[i].toLowerCase() == 'named' || words[i].toLowerCase() == 'called') {
        if (i + 1 < words.length) {
          name = words[i + 1].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          if (name.isNotEmpty) {
            name = name[0].toUpperCase() + name.substring(1);
            break;
          }
        }
      }
    }
    if (name == 'Buddy') {
      if (archetype == CompanionArchetype.dragon) {
        name = 'Draco';
      } else if (archetype == CompanionArchetype.cat) {
        name = 'Luna';
      } else if (archetype == CompanionArchetype.bunny) {
        name = 'Pip';
      } else if (archetype == CompanionArchetype.shiba) {
        name = 'Hachi';
      } else if (archetype == CompanionArchetype.slime) {
        name = 'Jelly';
      } else if (archetype == CompanionArchetype.fox) {
        name = 'Kitsu';
      }
    }

    // 6. Favorite files based on prompt
    List<String> favs = ['.png', '.jpg', '.dart', '.md', '.txt'];
    if (lower.contains('code') || lower.contains('dev') || lower.contains('hacker')) {
      favs = ['.dart', '.js', '.py', '.ts', '.html'];
    } else if (lower.contains('art') || lower.contains('draw') || lower.contains('photo')) {
      favs = ['.png', '.jpg', '.svg', '.gif', '.psd'];
    } else if (lower.contains('music') || lower.contains('sound') || lower.contains('beat')) {
      favs = ['.mp3', '.wav', '.flac', '.midi'];
    } else if (lower.contains('doc') || lower.contains('book') || lower.contains('read') || lower.contains('writer')) {
      favs = ['.pdf', '.docx', '.txt', '.md'];
    }

    return CompanionModel(
      id: 'companion_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      archetype: archetype,
      primaryColor: primary,
      secondaryColor: secondary,
      accentColor: accent,
      eyeColor: eyes,
      accessory: accessory,
      accessoryColor: accessoryColor,
      personality: personality,
      favoriteFileExtensions: favs,
    );
  }

  CompanionModel copyWith({
    String? id,
    String? name,
    CompanionArchetype? archetype,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? eyeColor,
    CompanionAccessory? accessory,
    Color? accessoryColor,
    String? customSpritePath,
    PetPersonality? personality,
    List<String>? favoriteFileExtensions,
    Map<String, int>? trickMastery,
  }) {
    return CompanionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      archetype: archetype ?? this.archetype,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      eyeColor: eyeColor ?? this.eyeColor,
      accessory: accessory ?? this.accessory,
      accessoryColor: accessoryColor ?? this.accessoryColor,
      customSpritePath: customSpritePath ?? this.customSpritePath,
      personality: personality ?? this.personality,
      favoriteFileExtensions: favoriteFileExtensions ?? List.from(this.favoriteFileExtensions),
      trickMastery: trickMastery ?? Map.from(this.trickMastery),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'archetype': archetype.index,
      'primaryColor': primaryColor.toARGB32(),
      'secondaryColor': secondaryColor.toARGB32(),
      'accentColor': accentColor.toARGB32(),
      'eyeColor': eyeColor.toARGB32(),
      'accessory': accessory.index,
      'accessoryColor': accessoryColor.toARGB32(),
      'customSpritePath': customSpritePath,
      'personality': personality.index,
      'favoriteFileExtensions': favoriteFileExtensions,
      'trickMastery': trickMastery,
    };
  }

  factory CompanionModel.fromJson(Map<String, dynamic> json) {
    return CompanionModel(
      id: json['id'] as String? ?? 'default_companion',
      name: json['name'] as String? ?? 'Buddy',
      archetype: CompanionArchetype.values[json['archetype'] as int? ?? 1],
      primaryColor: Color(json['primaryColor'] as int? ?? 0xFFE67E22),
      secondaryColor: Color(json['secondaryColor'] as int? ?? 0xFFFFF8E7),
      accentColor: Color(json['accentColor'] as int? ?? 0xFFD35400),
      eyeColor: Color(json['eyeColor'] as int? ?? 0xFF2C3E50),
      accessory: CompanionAccessory.values[json['accessory'] as int? ?? 0],
      accessoryColor: Color(json['accessoryColor'] as int? ?? 0xFFFFD700),
      customSpritePath: json['customSpritePath'] as String?,
      personality: PetPersonality.values[json['personality'] as int? ?? 2],
      favoriteFileExtensions: (json['favoriteFileExtensions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['.dart', '.png', '.pdf'],
      trickMastery: (json['trickMastery'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }

  String serialize() => jsonEncode(toJson());
  static CompanionModel deserialize(String data) =>
      CompanionModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
}
