# Feature 08: Daily Routine & Habit Tracker ("Eat Your Vitamins")

## 1. Overview
The **Daily Routine & Habit Tracker** deepens the reciprocal care relationship between owner and companion. While the owner cares for their companion through feeding, petting, and tricks, the companion actively partners with the owner to maintain daily wellness habits.

The owner can open their **Daily Routine** checklist with one click, check off habits like taking vitamins, drinking morning water, fixing posture, and having a nourishing lunch. In return, the companion celebrates each victory with celebratory particle bursts, chiptune fanfares, bonding XP, and heartwarming praise.

---

## 2. Core Pillars

### A. "Eat Your Vitamins" (💊)
- **Primary Habit**: A dedicated, prominent daily habit reminding and celebrating taking vitamins, medicine, or daily supplements.
- **Rewarding Feedback**: Checking off vitamins triggers gold and turquoise sparkle bursts, a chime, and joyful companion quotes ("Yay! Vitamins taken! Super healthy today! 💊✨").

### B. Daily Routine Checklist
- **Pre-configured Essentials**:
  1. 💊 **Eat Daily Vitamins**: "Fuel body & mind for the day ahead."
  2. 💧 **Morning Hydration Boost**: "Start fresh with a tall glass of water."
  3. 🧘 **Posture & Spine Reset**: "Drop shoulders, unclench jaw, sit tall."
  4. 🥗 **Nourishing Meal Break**: "Step away from screen for a good lunch."
  5. 🪟 **20-20-20 Eye Rest**: "Rest eyes on distant greenery for 20 seconds."
  6. 🌙 **Evening Wind-Down & Gratitude**: "Unplug and reflect on one good thing."
- **Custom Habits**:
  - Ability to add personalized daily goals (e.g. "Duolingo lesson", "10-minute walk", "Read 10 pages").
  - Can be deleted or toggled anytime.

### C. Streaks & Progression
- **Daily Rollover**: The checklist automatically resets on a new calendar day (`checkDayRollover`).
- **Streak Counter**: Consecutive active days increment the user's Streak flame (`🔥 N-Day Streak`).
- **Bonding XP**: Every completed routine item grants **+25 Companion XP**, contributing to leveling up your pet and raising happiness & affection.

### D. Autonomous Companion Reminders
- During idle wandering, Liil Buddy checks if core daily habits (such as vitamins) remain unchecked.
- If incomplete, the companion displays a caring speech bubble nudge:
  - *"Did you remember your daily vitamins yet? 💊"*
  - *"How's your daily routine going today? Let's check in together! 📋"*

---

## 3. Architecture & Data Model

```dart
enum RoutineCategory {
  health,
  mindfulness,
  focus,
  custom,
}

class RoutineItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final RoutineCategory category;
  bool isCompleted;
  DateTime? completedAt;
  final int xpReward;
  final String companionQuote;
  final bool isCustom;
}

class DailyRoutineTracker {
  List<RoutineItem> items;
  DateTime lastCheckedDate;
  int currentStreak;
  int bestStreak;
  DateTime? lastCompletedDate;
  ...
}
```

---

## 4. UI & Interaction
- **Context Menu Integration**: Direct right-click item **"Daily Routine & Habits"** (with `Icons.checklist_rtl`).
- **Desktop Modal Dialog**:
  - Dark cyber-cozy aesthetic with blur and glow effects.
  - Companion avatar with dynamic speech bubble.
  - Linear daily progress bar with percentage and streak badge.
  - Interactive checkboxes with smooth toggle animations.
  - Custom habit creation input bar.
