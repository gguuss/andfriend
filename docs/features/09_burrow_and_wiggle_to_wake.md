# Feature 09: Burrow Behavior & Interactive Wiggle-to-Wake 🐾🕳️

## 1. Overview & Clinical Grounding
In digital pet systems and habit apps, abandonment guilt, relapse shame, and executive overload are primary drivers of permanent user churn. Derived from clinical research on executive dysfunction, sensory overload, and compassionate computing, the **Burrow Behavior** provides a low-energy, zero-guilt sanctuary for both pet and owner.

When life becomes overwhelming or deep focus is required, the user can command their friend to dig into a cozy burrow mound. While burrowed:
- The pet sleeps peacefully underground.
- All floating speech bubbles, sound chimes, and autonomous nudges are completely muted.
- Streak decay timers are **strictly paused** so users never face penalties or guilt when taking a necessary mental health break.

When the user is ready to re-engage, the interactive **Wiggle-to-Wake** mechanic invites a joyful, non-judgmental return with zero scolding.

---

## 2. Core Mechanics

### A. Draggable Burrow System ("Dig Corner Burrow")
1. **Digging Pathfinding**:
   - Selecting "Dig Corner Burrow" from the companion context ribbon initiates autonomous pathfinding towards the nearest screen corner boundary.
   - If pathfinding is obstructed (e.g., active screen edges or window obstacles), the companion intelligently falls back to digging in place.
2. **Procedural Mound Spawning**:
   - The pet plays an animated soil-tossing digging sequence.
   - A procedural burrow mound widget spawns at the digging site, and the companion dives head-first inside, occluding their sprite.
3. **Complete Muting & Streak Decay Pause**:
   - Pet avatar is hidden inside the den.
   - All notifications, sound triggers, and floating speech bubbles are fully suppressed.
   - Daily habit streak decay timers automatically pause. No missed days are logged while resting in the burrow.
4. **Real-Time Drag-and-Follow**:
   - Users can click and drag the burrow mound widget across desktop displays.
   - Dragging causes the pet to poke its head out and actively walk/follow the moving mound in real time across single and multi-monitor setups.
5. **Auto-Resettle on Drop**:
   - Releasing the mouse button drops the burrow mound at its new screen coordinates.
   - The pet catches up to the mound and automatically climbs back inside to resume peaceful resting.

---

### B. High Priority: Wiggle-to-Wake Interaction
1. **User-Initiated Return**:
   - Clicking or gently wiggling the burrow mound triggers a subtle soil-shake and dust particle animation.
2. **Welcome-Back Sequence**:
   - The pet pops out of the burrow with an enthusiastic, warm greeting animation (e.g., joyful hop, tail wag, heart emotes).
   - Autonomous desktop roaming resumes across the transparent overlay.
3. **Non-Penalty Re-Entry Standard**:
   - Waking the pet after hours, days, or weeks of absence never incurs sickness, health penalties, dying states, or guilt-tripping dialogue.
   - Always greets the user with unconditional positive regard (*"Welcome back! I had a cozy nap and I'm happy to see you."*).

---

## 3. Architecture & State Management

```dart
enum BurrowState {
  emerged,          // Freely roaming overlay
  pathfinding,      // Navigating toward target corner/burrow point
  digging,          // Playing soil digging animation
  buried,           // Occluded inside mound, fully muted, streaks paused
  followingMound,   // Real-time walking behind dragged mound
}

class BurrowController extends ChangeNotifier {
  Offset moundPosition;
  BurrowState state = BurrowState.emerged;
  bool isDraggingMound = false;
  double shakeIntensity = 0.0;

  void digCornerBurrow(Size screenSize);
  void onMoundDragStart(Offset globalPos);
  void onMoundDragUpdate(Offset globalPos);
  void onMoundDragEnd();
  void wiggleToWake();
}
```

---

## 4. UI & Visual Assets
- **Burrow Mound Widget**: Pixel-art or procedural vector soil mound with grassy rim and shadow depth.
- **Occlusion Layering**: Z-index ordering where the pet sits behind the mound foreground layer when buried.
- **Shake & Pop Keyframes**: Spring physics animation on wiggle click with dirt particle burst.
