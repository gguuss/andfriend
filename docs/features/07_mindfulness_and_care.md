# Feature Spec: Mindfulness & Owner Caretaker Module 🧘🌱

## Overview
While the owner cares for their companion through feeding, petting, and trick training, **And Friend** is built on reciprocal companionship: our friend also actively looks after the owner's mental and physical health.

The **Mindfulness Module** encapsulates all proactive and on-demand wellness features, ensuring the companion is a positive, calming presence throughout long work and study sessions.

---

## 🌟 Pillars of Owner Care

### 1. Periodic Well-Being Reminders (Autonomous)
The companion quietly monitors session duration and gently surfaces thoughts with accompanying visual cues and soothing chimes:
- 💧 **Hydration Checks**: *"Remember to take a refreshing sip of water! Stay hydrated, friend."* (Water droplet particles)
- 🪟 **Fresh Air & Rest**: *"You've been focused for a while. Let's look out the window for 20 seconds or step outside for fresh air."* (Gentle leaf breeze particles)
- 🧘 **Posture & Shoulder Drop**: *"Friendly check-in: unclench your jaw and gently roll your shoulders back."* (Soft stretching wobble animation)
- 💖 **Affirmations & Love**: *"You're doing great today. I'm so glad to be sharing a desk with you."* (Warm heart bursts)
- 🌙 **Late-Night Care**: When working past midnight, the companion whispers: *"It's getting late. Make sure to get plenty of rest so you feel refreshed tomorrow."*

### 2. Interactive Mindfulness Sanctuary (Modal)
Accessible anytime from the companion's right-click menu (**Mindfulness & Rest**):
- 🌬️ **Box Breathing Exercise (4-4-4-4)**:
  - An expanding and contracting breathing orb.
  - The companion synchronizes their own breathing and gentle scale animations with the rhythm (`Inhale` ➔ `Hold` ➔ `Exhale` ➔ `Rest`).
  - Procedural singing bowl / chime audio guiding each breath phase.
- 💧 **Hydration Log**:
  - One-click button: *"I drank a cup of water!"*
  - The companion jumps with excitement, squirts water droplets, and both owner and companion gain affection & happiness XP.
- 🧘 **1-Minute Eye Rest Break**:
  - Soft ambient darkness mode with calming particles to let the owner rest their eyes.
- 💬 **Daily Affirmation Jar**:
  - Tap the jar to receive an uplifting thought card tailored to the day.

### 3. Frequency & Customization Settings
- Users can customize reminder intervals: Every 30 mins, 45 mins, 60 mins, or Silent mode.
- Sound chimes can be individually toggled or muted.

---

## 🏗️ Architecture Integration

```
lib/
├── models/
│   └── mindfulness_state.dart      # Mindfulness reminder categories, stats, quotes, and settings
├── audio/
│   └── sound_service.dart          # Zen chime / singing bowl procedural synthesizer
├── controllers/
│   └── pet_controller.dart         # Mindfulness timer loop & autonomous thought triggers
└── ui/
    └── mindfulness_dialog.dart     # Interactive sanctuary modal (breathing circle, water counter)
```

---

## 🎮 Gameplay & Reciprocal Care Loops
- Logging hydration or completing a breathing exercise rewards both the owner and the companion:
  - Owner gets a moment of calm and focus.
  - Companion gains +10 Affection and +15 Happiness.
  - Unlocks milestone badges: *"Hydration Hero"*, *"Deep Breather"*, and *"Balanced Mind"*.
