# And Friend - Product Roadmap 🐾

Welcome to the **And Friend** product roadmap. This document outlines the long-term vision, architectural specifications, and phased milestones for our cross-platform Flutter desktop companion.

Grounded in clinical psychology and behavioral science, **And Friend** integrates research from the *Virtual Pets Research Notebook (33 Academic & Clinical Sources, 2,200+ Pages)*—uniting executive dysfunction scaffolding, somatic nervous system regulation, cognitive reframing, and non-punitive exergaming into an empathetic desktop companion.

---

## 🧭 3-Phase Development Strategy

Development is structured into three distinct, research-backed phases:

1. **Phase 1: Core MVP Engine & Desktop Overlay (COMPLETED)**  
   *Focus: Low-friction desktop coexistence, the zero-guilt burrow sanctuary, wiggle-to-wake mechanics, executive dysfunction HALT prompts, forgiving streaks, and local encrypted storage.*
2. **Phase 2: Exergaming & Social Interdependence (CURRENT FOCUS)**  
   *Focus: Non-competitive physical step conversion (+20% activity buffer), cooperative park spaces, and mobile companion widget synchronization.*
3. **Phase 3: Somatic & Cognitive Wellness Suite**  
   *Focus: Polyvagal nervous system down-regulation, meridian tapping minigames, 4-7-8 diaphragmatic pacing, 5-sense grounding, and CBT cognitive reframing.*

---

## 🗺️ Detailed Roadmap Milestones

### Phase 1: Core MVP Engine & Desktop Overlay *(COMPLETED)*

- [x] **Flutter Transparent Desktop Overlay & Pet Roaming Physics**
  - Fullscreen borderless transparent overlay with mouse pass-through (`setIgnoreMouseEvents`).
  - Free desktop roaming, gravity, ledge detection, and draggable relocation.
  - Right-click contextual interaction ribbon on your companion.
  - Real-time eye gaze tracking to mouse cursor.
  - Desktop file & folder interaction (`~/Desktop` scanning, sniffing files, folder diving).
  - Procedural chiptune sound synthesizer with instant mute toggle.
  - 6 Trick training playbook with XP mastery tiers.

- [x] **HIGH PRIORITY: Draggable Burrow Mound ("Dig Corner Burrow")**
  - **Digging Pathfinding**: Selecting "Dig Corner Burrow" initiates intelligent pet pathfinding toward the nearest screen corner boundary (or falls back smoothly to digging in place if pathfinding is obstructed).
  - **Procedural Mound Spawning**: The pet executes a playful digging animation, spawns a charming procedural burrow mound widget, and retreats head-first inside.
  - **Complete Muting & Streak Decay Pause**: While burrowed, the pet avatar hides, all floating speech bubbles and sound chimes are fully muted, and daily streak decay timers automatically **PAUSE** to eliminate guilt, shame, and relapse anxiety during low-energy periods.
  - **Real-Time Drag-and-Follow**: Clicking and dragging the burrow mound across the screen causes the pet to emerge from its hole and actively walk/follow the moving mound in real time across single and multi-monitor setups.
  - **Auto-Resettle on Drop**: Releasing the mouse button drops the burrow mound at its new desktop location; the pet catches up to the mound and automatically climbs back inside to resume quiet resting.

- [x] **HIGH PRIORITY: Wiggle-to-Wake Interaction & Soil-Shake Animation**
  - **User-Initiated Return**: When the user is ready to resume active companion time, clicking or gently wiggling the burrow mound triggers a subtle, tactile soil-shake animation and dust particle effects.
  - **Welcome-Back Sequence**: The pet pops out of the burrow mound with a warm, non-judgmental greeting animation and resumes roaming the desktop overlay.
  - **Non-Penalty Re-Entry**: Waking the pet after an absence (whether hours, days, or months) never incurs sickness, health penalties, starving states, or scolding notifications. Unconditional positive regard is guaranteed.

- [x] **Floating HALT Speech Bubbles with Grounded, Non-Toxic Copy**
  - **Dynamic Anchoring**: Reactive speech bubbles float directly above the roaming pet overlay, smoothly following pet locomotion without blocking active workflows.
  - **HALT Vulnerability Presets**: Pre-loaded micro-check-ins targeting fundamental physiological and psychological triggers:
    - 🍎 **Hungry**: Water/snack check-in (*"Water check whenever you're ready"*).
    - 😤 **Angry / Overwhelmed**: 3-breath pause to break sympathetic arousal (*"Let's pause together for 3 deep breaths"*).
    - 🫂 **Lonely**: Gentle social micro-prompt (*"Sending a warm thought your way. You're not alone"*).
    - 🥱 **Tired**: Eye rest or burrow invitation (*"Taking things slow today is enough"*).
  - **Grounded Copy Standard**: Zero toxic positivity, zero preachy lecturing, and zero guilt triggers.

- [x] **1-Click Completion Celebrations (Confetti, Victory Dance)**
  - **Immediate Dopamine Feedback**: Single-click "Done!" buttons embedded inside speech bubbles close the prompt and instantly trigger celebratory animations:
    - Confetti particle explosion radiating from companion.
    - Party hat pop and playful bouncy spring physics.
    - Cheerful victory dance.
    - Special snack or collectible treat drop.
  - **Energy & Item Drops**: Goal completions replenish companion energy and award collectible items for room decoration and pet customization.

- [x] **Forgiving Streak Protection System**
  - **3-Day Habit Rule**: Completing daily check-ins for 3 consecutive days automatically awards **1 "Streak Shield"** item (stackable up to 3).
  - **Automated Shield Consumption**: Missed days automatically consume 1 Streak Shield to preserve streak counters without breaking habit momentum.
  - **Welcome-Back & Streak Repair**: Returning after an extended hiatus awards a gentle welcome gift and a **"Streak Repair"** item, allowing users to restore broken streaks without penalty.
  - **Burrow Freeze**: Entering the burrow mound automatically halts all streak decay timers.

- [x] **SQLCipher / Pure-Dart AES-256 Local Encrypted Database Storage**
  - Complete local zero-cloud AES-256-CBC encryption for all journal logs, user habits, daily streak records, and companion states.
  - Cryptographically secure dynamic 128-bit IV generation with SHA-256 derived master key.
  - Graceful legacy migration fallback ensuring pre-existing unencrypted state files are read without corruption.
  - Zero cloud leakage, zero telemetry, full offline functionality.

---

### Phase 2: Exergaming & Social Interdependence *(CURRENT FOCUS)*

- [x] **Mobile/Desktop Step Counter Integration (+20% Activity Exergaming Loop)**
  - Ingests steps via live "Walk with Friend" active pacing sessions, smartwatch/mobile quick-logging (+500, +1,000, +2,500, custom), and encrypted local persistence.
  - Converts daily steps into companion experience points (XP), stamina buffers (fatigue protection), and health metrics (km, kcal, active minutes).
  - Leverages behavioral research demonstrating a **+20% increase in baseline physical activity** through non-punitive virtual companion exergaming.

- [x] **Step-Driven Pet Growth Stages, Fitness Stats & Burrow Treasure Drops**
  - Tier progression milestones: **Bronze Stride (2.5k)**, **Silver Target / +20% Lift (5k)**, **Gold Odyssey (8k)**, **Platinum Champion (10k)**.
  - Reaching step milestones dynamically unearths rare burrow treasures (*Golden 4-Leaf Clover, Glowing River Pebble, Ancient Sunlit Acorn, Tiny Running Shoe Pin, Cosmic Blossom Seed*) that the companion carries back to the burrow.
  - Celebratory confetti and sparkle particle cascades with zero guilt or penalties for low-movement days.

- [ ] **"The Park" Safe Community Space (Non-Competitive Socializing)**
  - **Non-Competitive Social Spaces**: Relaxing, opt-in gathering zones with zero high-pressure competitive leaderboards or public ranking.
  - **Prosocial Reciprocal Mechanics**:
    - Gifting decorative items and snacks.
    - Sending **"Warm Fuzzies"** (wholesome visual affirmations and sparkle particles).
    - Community care tree sponsorship to celebrate shared wellness milestones.
  - Robust safety filters, preset communication cards, and comprehensive privacy controls.

- [ ] **Mobile Companion Widget Sync (Living Pet State & Appointment Mechanics)**
  - iOS Lock Screen / Dynamic Island & Android Home Screen companion glanceable widgets.
  - Two-way state synchronization (burrow state, vitals, daily streak protection).
  - Gentle scheduled check-ins and appointment notifications without intrusive alert fatigue.

---

### Phase 3: Somatic & Cognitive Wellness Suite

- [x] **Somatic EFT (Emotional Freedom Technique) "Tap with Friend"**
  - **Meridian Tapping Minigame**: An interactive co-regulation routine where the companion guides gentle rhythmic tapping across 5 clinical somatic meridian endpoints:
    1. *Top of Head (Crown)*: Restores cognitive clarity and breaks cognitive fatigue.
    2. *Eyebrow Point*: Releases mental tension, eye fatigue, and sensory overload.
    3. *Side of Eye Point*: Clears emotional frustration and visual strain.
    4. *Under Eye Point*: Grounds somatic anxiety and soothes nervous agitation.
    5. *Collarbone Point*: Down-regulates fight-or-flight sympathetic arousal.
  - Synchronized with gentle chimes, ascending audio tones, somatic affirmations, visual progress badges, and celebratory zen blessing particles (+35 XP, +25 happiness, +20 affection).

- [x] **Guided 4-7-8 Diaphragmatic Breathing Pet Pacing Animations**
  - **Visual Breathing Bubbles & Concentric Aura Rings**: Paced visual expansion and contraction animations with concentric aura rings to regulate the parasympathetic nervous system during panic or hyperventilation:
    - **4s Inhale**: Smooth expansion through nose as concentric aura rings bloom.
    - **7s Hold**: Gentle hold as the orb pulses softly with soothing chimes.
    - **8s Exhale**: Smooth whoosh exhale through mouth as concentric rings relax and contract.
  - Toggleable technique modes between **4-7-8 Diaphragmatic (19s cycle)** and **4-4-4-4 Box Breathing (16s cycle)**.

- [ ] **5-Sense Environmental Grounding 1-Minute Mindfulness Scans**
  - **Grounding Exercises**: Quick 1-minute guided sensory scans prompting the user to observe physical surroundings to immediately interrupt anxious rumination:
    - 👁️ *5 Things You See*
    - ✋ *4 Things You Can Feel*
    - 👂 *3 Things You Hear*
    - 👃 *2 Things You Smell*
    - 👅 *1 Thing You Taste*
  - Frictionless step-through with particle rewards on completion.

- [ ] **Positive Mental Attitude (PMA) Affirmation Card Engine**
  - **Cognitive Reprogramming**: Interactive affirmation prompts that catch Negative Mental Attitudes (NMA) and replace them with present-tense positive affirmations:
    - *Catastrophizing / Overwhelm* ➔ *"Doing one small step right now is enough."*
    - *Imposter Feelings* ➔ *"I choose to value myself today regardless of productivity metrics."*
  - Illustrated aesthetic card deck with procedural shimmer shaders.

- [ ] **Local Encrypted 1-Sentence Micro-Gratitude Logger**
  - Frictionless 1-sentence prompt following task completion or waking from burrow.
  - Stored securely in the local SQLCipher AES-256 encrypted database with zero external network transmission.

---

## 🛠️ Architecture & Development Structure

Feature specifications are modularized under `docs/features/`:

```
docs/
├── features/
│   ├── 01_lifecycle_and_aging.md              # Egg, Baby, Teen, Adult state machine
│   ├── 02_vet_and_health.md                   # Dr. Paws Vet Clinic & diagnostics
│   ├── 03_personality_evolution.md            # Encouragement traits & personality engine
│   ├── 04_adoption_onboarding.md              # Interactive onboarding & adoption certificates
│   ├── 05_galleries_and_badges.md             # Achievements, badges & cosmetic unlocks
│   ├── 06_online_spaces_and_social.md         # Multiplayer WebSocket hubs & viral sharing
│   ├── 07_mindfulness_and_care.md             # Mindfulness reminders, guided breathing & owner care
│   ├── 08_daily_routine_and_habits.md         # Daily routine, vitamins tracker & habit streaks
│   ├── 09_burrow_and_wiggle_to_wake.md        # Draggable burrow, streak pauses & wiggle-to-wake
│   ├── 10_executive_dysfunction_and_halt.md   # Floating HALT bubbles, 1-click confetti, shields
│   ├── 11_somatic_and_stress_interventions.md # Somatic EFT tapping, 4-7-8 breathing, 5-sense scans
│   ├── 12_cognitive_reframing_and_gratitude.md# PMA vs NMA cards & AES-256 micro-gratitude logger
│   └── 13_exergaming_and_the_park.md          # Step counter sync (+20% buffer) & "The Park" space
```

---

## 📊 Milestone Status Board

| Milestone | Phase | Priority | Target | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Transparent Desktop Overlay & Physics** | Phase 1 | P0 | v1.0 | ✅ Completed |
| **Right-Click Interaction Ribbon** | Phase 1 | P0 | v1.0 | ✅ Completed |
| **Desktop Roaming & Draggable Relocation**| Phase 1 | P0 | v1.0 | ✅ Completed |
| **Mindfulness & Owner Care Module** | Phase 1 | P1 | v1.1 | ✅ Completed |
| **Daily Routine & Vitamins Tracker** | Phase 1 | P1 | v1.1 | ✅ Completed |
| **Draggable Burrow Mound System** | Phase 1 | P0 | v1.2 | ✅ Completed |
| **Wiggle-to-Wake & Soil-Shake Animation** | Phase 1 | P0 | v1.2 | ✅ Completed |
| **Floating HALT Speech Bubbles** | Phase 1 | P1 | v1.2 | ✅ Completed |
| **1-Click Completion Celebrations** | Phase 1 | P1 | v1.2 | ✅ Completed |
| **Forgiving Streak Protection & Shields** | Phase 1 | P1 | v1.2 | ✅ Completed |
| **SQLCipher / AES-256 Encrypted Storage** | Phase 1 | P1 | v1.3 | ✅ Completed |
| **Step Counter Exergaming Sync (+20%)** | Phase 2 | P1 | v2.0 | ✅ Completed |
| **Step Growth & Burrow Treasures** | Phase 2 | P2 | v2.0 | ✅ Completed |
| **"The Park" Safe Social Space** | Phase 2 | P2 | v2.1 | 🚀 Next Focus |
| **Mobile Companion Widget Sync** | Phase 2 | P2 | v2.2 | 📋 Planned |
| **Somatic EFT "Tap with Friend"** | Phase 3 | P1 | v3.0 | ✅ Completed |
| **4-7-8 Diaphragmatic Breathing Pacing** | Phase 3 | P1 | v3.0 | ✅ Completed |
| **5-Sense Environmental Grounding** | Phase 3 | P2 | v3.0 | 📋 Planned |
| **PMA Affirmation Card Engine** | Phase 3 | P2 | v3.1 | 📋 Planned |
| **Encrypted 1-Sentence Micro-Gratitude** | Phase 3 | P2 | v3.1 | 📋 Planned |

