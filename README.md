# Liil Buddy 🐾

**Liil Buddy** is an interactive, lightweight desktop companion application for **macOS** and **Windows** built with Flutter.

![Liil Buddy Preview](https://img.shields.io/badge/Liil--Buddy-Desktop%20Companion-ff69b4?style=for-the-badge)

---

## ✨ Features

- **🐾 Tomodachi Care**:
  - **Feed**: Give snacks (Wild Berry, Golden Fish, Warm Dumpling, or crunchy File Cookies) with munching sound effects and flying crumbs.
  - **Sleep**: Put your companion to sleep with a cozy nightcap, rhythmic snores, and drifting "Zzz" particles; wakes up refreshed.
  - **Tickle / Pet**: Rapidly pet or rub your companion with the mouse cursor to make it blush, giggle, wiggle, and burst with hearts.
  - **Vitals & Stats**: Monitor Hunger, Energy, Happiness, Affection, and Level/XP in real-time.

- **📁 Real Desktop Interaction**:
  - **Sniff Files**: Reads files on your `~/Desktop` directory and shares cute, contextual commentary (*"Sniffs `report.pdf`... smells like serious paperwork!"*).
  - **Folder Diving**: Spots folders on your desktop, dives headfirst into them with a whoosh, and surfaces holding shiny bytes or trinkets.
  - **Favorite Files**: Each companion has favorite file types (e.g. `.dart`, `.png`, `.mp3`) that trigger special excited tail wags!

- **🕳️ Corner Burrows**:
  - Digs cozy little burrows in the corner of your screen with flying dirt clods and scratchy digging sounds.
  - The companion can snuggle inside, take naps, or peek out at your desktop.

- **👀 Mouse Gaze Tracking**:
  - The mascot's expressive anime eyes and pupils smoothly follow your mouse cursor wherever you move it across the desktop.

- **🎓 Trick Training Playbook**:
  - Train 6 unique tricks: **Backflip** (360° somersault), **Tornado Spin** (with dizzy spiral eyes), **Play Dead** (dramatic faint), **Beg** (waving paws), **Bop Dance** (musical groove), and **High Five** (paw tap).
  - XP and Mastery Tiers: *Novice* ➔ *Apprentice* ➔ *Master* with triumphant fanfare chimes!

- **🔊 Synthesized Audio & Instant Mute**:
  - Pure code, procedural sound synthesizer (chirps, giggles, crunches, snores, digging scratches, fanfares).
  - One-click global mute/unmute button right on the HUD.

- **🎨 Companion Builder Wizard**:
  - **Prompt Magic**: Describe your buddy in natural language (*"A sleepy matcha dragon with tiny golden horns who loves code files"*) to auto-generate archetype, colors, accessories, traits, and favorite files.
  - **Archetype & Palette Studio**: Choose from Cat (Neko), Fox (Kitsune), Bunny, Shiba Inu, Pocket Dragon, and Slime Blob, and customize fur, belly, accents, and eyes.
  - **Accessories**: Wizard Hat, Star Badge, Cozy Scarf, Cool Glasses, Tiny Horns, and Sakura Flower.
  - **Custom Sprite Importer**: Load any custom PNG/JPEG/GIF image to use as your companion.
  - **Live Preview Stage**: Test the mascot's real-time gaze tracking and animations as you design it!

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev) (v3.13+ or higher)
- macOS: CocoaPods (`brew install cocoapods`)
- Windows: Visual Studio with "Desktop development with C++"

### Running the App

```bash
# Get dependencies
flutter pub get

# Run on macOS Desktop
flutter run -d macos

# Run on Windows Desktop
flutter run -d windows
```

### Running Tests

```bash
flutter test
```

---

## 🏗️ Architecture

```
lib/
├── audio/
│   └── sound_service.dart         # Procedural WAV sound synthesizer & mute controller
├── controllers/
│   └── pet_controller.dart        # Core game loop, vitals decay, care actions, auto behaviors
├── core/
│   ├── cursor_tracker.dart        # Screen-wide & local mouse gaze tracker via FFI
│   └── desktop_scanner.dart       # Cross-platform ~/Desktop file sniffer & reactions
├── graphics/
│   ├── particle.dart              # Particle physics (hearts, dirt, crumbs, Zzz, sparkles)
│   └── pet_painter.dart           # 60fps CustomPainter vector mascot renderer & rig
├── models/
│   ├── companion_model.dart       # Archetypes, colors, accessories, prompt generator, JSON
│   ├── pet_state.dart             # Moods, vitals (hunger, energy, happiness), snacks, bubbles
│   └── trick_system.dart          # Tricks playbook, duration, and mastery tiers
├── ui/
│   ├── builder/
│   │   └── companion_builder_dialog.dart  # Companion Builder Wizard modal
│   └── pet_overlay_screen.dart            # Main desktop overlay & floating HUD
└── main.dart                      # WindowManager setup (transparent, frameless, floating)
```
