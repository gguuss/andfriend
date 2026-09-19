import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../audio/sound_service.dart';
import '../controllers/pet_controller.dart';
import '../core/cursor_tracker.dart';
import '../graphics/pet_painter.dart';
import '../models/pet_state.dart';
import '../models/trick_system.dart';
import 'builder/companion_builder_dialog.dart';
import 'daily_routine_dialog.dart';
import 'mindfulness_dialog.dart';

class PetOverlayScreen extends StatefulWidget {
  final PetController controller;

  const PetOverlayScreen({super.key, required this.controller});

  @override
  State<PetOverlayScreen> createState() => _PetOverlayScreenState();
}

class _PetOverlayScreenState extends State<PetOverlayScreen> {
  bool _isContextMenuOpen = false;
  Offset _menuPosition = Offset.zero;
  bool _showSnacks = false;
  bool _showTricks = false;
  bool _showVetDialog = false;
  bool _showMindfulnessDialog = false;
  bool _showRoutineDialog = false;

  bool _isCurrentlyInteractive = false;
  Timer? _hitTestTimer;

  @override
  void initState() {
    super.initState();

    // Hit-testing loop: toggles setIgnoreMouseEvents based on whether cursor is over pet or menu
    _hitTestTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _checkHitTestAndToggleMouseEvents();
    });
  }

  @override
  void dispose() {
    _hitTestTimer?.cancel();
    super.dispose();
  }

  void _checkHitTestAndToggleMouseEvents() async {
    final ctrl = widget.controller;

    // Keep CursorTracker's DPI ratio in sync so Win32 physical pixels are
    // correctly converted to Flutter logical pixels before any comparison.
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    CursorTracker.instance.setDevicePixelRatio(pixelRatio);

    final globalCursor = CursorTracker.instance.getGlobalCursorPosition();

    bool shouldBeInteractive = _isContextMenuOpen ||
        _showSnacks ||
        _showTricks ||
        _showVetDialog ||
        _showMindfulnessDialog ||
        _showRoutineDialog;

    if (globalCursor != null && !shouldBeInteractive) {
      final petCenter = ctrl.screenPosition;
      final dist = (globalCursor - petCenter).distance;
      if (dist < 85.0) {
        shouldBeInteractive = true;
      }

      // Hit-test burrow mound if it exists
      if (ctrl.hasBurrow && ctrl.burrowPosition != null) {
        final burrowDist = (globalCursor - ctrl.burrowPosition!).distance;
        if (burrowDist < 65.0) {
          shouldBeInteractive = true;
        }
      }
    }

    if (shouldBeInteractive != _isCurrentlyInteractive) {
      _isCurrentlyInteractive = shouldBeInteractive;
      try {
        if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
          await windowManager.setIgnoreMouseEvents(!_isCurrentlyInteractive, forward: true);
        }
      } catch (_) {}
    }

    // Update eye gaze tracking towards cursor
    if (globalCursor != null) {
      CursorTracker.instance.updateGazeFromScreen(petScreenPos: ctrl.screenPosition);
    }
  }

  void _openContextMenu(Offset globalPos) {
    setState(() {
      _isContextMenuOpen = true;
      _showSnacks = false;
      _showTricks = false;
      // Position menu slightly offset from the pet
      _menuPosition = globalPos;
    });
    SoundService.instance.playChirp();
  }

  void _closeContextMenu() {
    setState(() {
      _isContextMenuOpen = false;
      _showSnacks = false;
      _showTricks = false;
    });
  }

  void _openBuilderWizard() {
    _closeContextMenu();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => CompanionBuilderDialog(
        currentCompanion: widget.controller.companion,
        onSave: (newComp) {
          widget.controller.updateCompanion(newComp);
        },
      ),
    );
  }

  void _showVetInspection() {
    _closeContextMenu();
    setState(() => _showVetDialog = true);
    SoundService.instance.playChirp(pitchMultiplier: 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    widget.controller.setScreenBounds(size);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Fullscreen CustomPaint rendering Particles across entire display
              Positioned.fill(
                child: CustomPaint(
                  painter: PetPainter(
                    companion: ctrl.companion,
                    mood: PetMood.idle,
                    animationTime: ctrl.animationTime,
                    gazeOffset: Offset.zero,
                    gazeDistance: 100,
                    trickProgress: 0,
                    activeTrickId: null,
                    particles: ctrl.particles,
                    hasBurrow: false, // Handled in dedicated draggable layer below
                    burrowPosition: null,
                    incomingSnack: ctrl.incomingSnack,
                    drawMascot: false,
                  ),
                ),
              ),

              // 2. Burrow Hole Background (drawn behind mascot when burrow exists)
              if (ctrl.hasBurrow && ctrl.burrowPosition != null)
                Positioned(
                  left: ctrl.burrowPosition!.dx - 85,
                  top: ctrl.burrowPosition!.dy - 85,
                  width: 170,
                  height: 170,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: GestureDetector(
                      onPanStart: (_) => ctrl.startBurrowDragging(),
                      onPanUpdate: (details) => ctrl.updateBurrowDragging(details.globalPosition),
                      onPanEnd: (_) => ctrl.stopBurrowDragging(),
                      onTap: () => ctrl.toggleBurrowPeek(),
                      child: CustomPaint(
                        painter: BurrowMoundPainter(
                          isDragging: ctrl.isBurrowDragging,
                          layer: ctrl.isInsideBurrow ? BurrowMoundLayer.background : BurrowMoundLayer.all,
                          edge: ctrl.burrowEdge,
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. The Pet Mascot (positioned at screenPosition)
              Positioned(
                left: ctrl.screenPosition.dx - 100,
                top: ctrl.screenPosition.dy - 100,
                width: 200,
                height: 200,
                child: ValueListenableBuilder<Offset>(
                  valueListenable: CursorTracker.instance.gazeOffset,
                  builder: (context, gaze, child) {
                    return ValueListenableBuilder<double>(
                      valueListenable: CursorTracker.instance.gazeDistance,
                      builder: (context, dist, child) {
                        return GestureDetector(
                          // Left-click & Drag to pick up friend
                          onPanStart: (details) {
                            if (ctrl.isInsideBurrow) {
                              // Dragging protruding ear pulls friend out of burrow!
                              ctrl.unsnugFromBurrow();
                            }
                            ctrl.startDragging();
                          },
                          onPanUpdate: (details) {
                            ctrl.updateDragging(details.globalPosition);
                          },
                          onPanEnd: (details) {
                            ctrl.stopDragging();
                          },
                          // Secondary tap (Right-click) on mascot
                          onSecondaryTapUp: (details) {
                            _openContextMenu(details.globalPosition);
                          },
                          onTap: () {
                            if (ctrl.isInsideBurrow) {
                              // Touching ear unsnugs the friend from the burrow!
                              ctrl.unsnugFromBurrow();
                            } else {
                              // Left-click interaction (pet/tickle)
                              ctrl.handlePointerMove(ctrl.screenPosition);
                            }
                          },
                          child: MouseRegion(
                            cursor: ctrl.isInsideBurrow
                                ? SystemMouseCursors.click
                                : (ctrl.isDragging
                                    ? SystemMouseCursors.grabbing
                                    : SystemMouseCursors.grab),
                            onHover: (event) {
                              if (!ctrl.isInsideBurrow) {
                                ctrl.handlePointerMove(event.position);
                              }
                            },
                            child: CustomPaint(
                              painter: PetPainter(
                                companion: ctrl.companion,
                                mood: ctrl.mood,
                                animationTime: ctrl.animationTime,
                                gazeOffset: gaze,
                                gazeDistance: dist,
                                trickProgress: ctrl.trickProgress,
                                activeTrickId: ctrl.activeTrickId,
                                particles: [],
                                hasBurrow: false,
                                burrowEdge: ctrl.burrowEdge,
                              ),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 4. Burrow Mound Foreground (overlaps mascot body, allowing only ears to peek out!)
              if (ctrl.hasBurrow && ctrl.burrowPosition != null && ctrl.isInsideBurrow)
                Positioned(
                  left: ctrl.burrowPosition!.dx - 85,
                  top: ctrl.burrowPosition!.dy - 85,
                  width: 170,
                  height: 170,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onPanStart: (_) => ctrl.startBurrowDragging(),
                      onPanUpdate: (details) => ctrl.updateBurrowDragging(details.globalPosition),
                      onPanEnd: (_) => ctrl.stopBurrowDragging(),
                      onTap: () => ctrl.unsnugFromBurrow(),
                      child: CustomPaint(
                        painter: BurrowMoundPainter(
                          isDragging: ctrl.isBurrowDragging,
                          layer: BurrowMoundLayer.foreground,
                          edge: ctrl.burrowEdge,
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. Floating Thought Bubble above Mascot
              if (ctrl.thoughtBubble != null)
                Positioned(
                  left: (ctrl.screenPosition.dx - 130).clamp(10.0, size.width - 270),
                  top: (ctrl.screenPosition.dy - 140).clamp(10.0, size.height - 80),
                  child: _buildThoughtBubble(ctrl.thoughtBubble!),
                ),

              // 4. Right-Click Context Menu
              if (_isContextMenuOpen)
                Positioned(
                  left: (_menuPosition.dx + 20).clamp(20.0, size.width - 230),
                  top: (_menuPosition.dy - 60).clamp(20.0, size.height - 380),
                  child: _buildContextMenu(),
                ),

              // 5. Snack Popover
              if (_showSnacks)
                Positioned(
                  left: (_menuPosition.dx + 20).clamp(20.0, size.width - 290),
                  top: (_menuPosition.dy - 60).clamp(20.0, size.height - 200),
                  child: _buildSnackPopover(),
                ),

              // 6. Trick Training Tray
              if (_showTricks)
                Positioned(
                  left: (_menuPosition.dx + 20).clamp(20.0, size.width - 320),
                  top: (_menuPosition.dy - 100).clamp(20.0, size.height - 300),
                  child: _buildTrickPopover(),
                ),

              // 7. Vet Inspection Dialog
              if (_showVetDialog)
                Positioned.fill(
                  child: _buildVetModal(),
                ),

              // 8. Mindfulness Sanctuary Dialog
              if (_showMindfulnessDialog)
                Positioned.fill(
                  child: MindfulnessDialog(
                    controller: widget.controller,
                    onClose: () => setState(() => _showMindfulnessDialog = false),
                  ),
                ),

              // 9. Daily Routine Dialog
              if (_showRoutineDialog)
                Positioned.fill(
                  child: DailyRoutineDialog(
                    controller: widget.controller,
                    onClose: () => setState(() => _showRoutineDialog = false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThoughtBubble(ThoughtBubble bubble) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bubble.icon != null) ...[
            Icon(bubble.icon, size: 16, color: Colors.amberAccent),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              bubble.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- RIGHT-CLICK CONTEXT MENU ---
  Widget _buildContextMenu() {
    final ctrl = widget.controller;
    final sound = SoundService.instance;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF181824).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Friend Name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.white.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    const Icon(Icons.pets, size: 14, color: Colors.amberAccent),
                    const SizedBox(width: 8),
                    Text(
                      ctrl.companion.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, size: 14, color: Colors.white54),
                      onPressed: _closeContextMenu,
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Menu Items
              _buildMenuItem(
                icon: Icons.fastfood,
                iconColor: Colors.orangeAccent,
                label: 'Feed Snack',
                onTap: () => setState(() {
                  _showSnacks = true;
                  _isContextMenuOpen = false;
                }),
              ),
              _buildMenuItem(
                icon: ctrl.mood == PetMood.sleeping ? Icons.wb_sunny : Icons.bedtime,
                iconColor: Colors.indigoAccent,
                label: ctrl.mood == PetMood.sleeping ? 'Wake Up' : 'Sleep (Catnap)',
                onTap: () {
                  ctrl.toggleSleep();
                  _closeContextMenu();
                },
              ),
              _buildMenuItem(
                icon: Icons.favorite,
                iconColor: Colors.pinkAccent,
                label: 'Pet & Tickle',
                onTap: () {
                  ctrl.handlePointerMove(ctrl.screenPosition);
                  _closeContextMenu();
                },
              ),
              _buildMenuItem(
                icon: Icons.military_tech,
                iconColor: Colors.amberAccent,
                label: 'Train Tricks',
                onTap: () => setState(() {
                  _showTricks = true;
                  _isContextMenuOpen = false;
                }),
              ),
              _buildMenuItem(
                icon: Icons.landscape,
                iconColor: Colors.brown.shade300,
                label: ctrl.hasBurrow ? 'Burrow (Peek/Den)' : 'Dig Corner Burrow',
                onTap: () {
                  ctrl.toggleBurrowPeek();
                  _closeContextMenu();
                },
              ),
              _buildMenuItem(
                icon: Icons.folder_open,
                iconColor: Colors.tealAccent,
                label: 'Sniff Desktop Files',
                onTap: () {
                  ctrl.sniffDesktop();
                  _closeContextMenu();
                },
              ),
              _buildMenuItem(
                icon: Icons.checklist_rtl,
                iconColor: Colors.amberAccent,
                label: 'Daily Routine & Habits',
                onTap: () {
                  _closeContextMenu();
                  setState(() => _showRoutineDialog = true);
                  SoundService.instance.playChirp(pitchMultiplier: 1.2);
                },
              ),
              _buildMenuItem(
                icon: Icons.spa,
                iconColor: Colors.tealAccent,
                label: 'Mindfulness & Rest',
                onTap: () {
                  _closeContextMenu();
                  setState(() => _showMindfulnessDialog = true);
                  SoundService.instance.playZenChime();
                },
              ),
              _buildMenuItem(
                icon: Icons.medical_services,
                iconColor: Colors.redAccent,
                label: 'The Vet (Health Check)',
                onTap: _showVetInspection,
              ),
              _buildMenuItem(
                icon: sound.isMuted ? Icons.volume_off : Icons.volume_up,
                iconColor: sound.isMuted ? Colors.redAccent : Colors.greenAccent,
                label: sound.isMuted ? 'Unmute Sounds' : 'Mute Sounds',
                onTap: () {
                  sound.toggleMute();
                  setState(() {});
                },
              ),
              _buildMenuItem(
                icon: Icons.auto_awesome,
                iconColor: Colors.purpleAccent,
                label: 'Companion Builder',
                onTap: _openBuilderWizard,
              ),
              const Divider(color: Colors.white10, height: 1),
              _buildMenuItem(
                icon: Icons.power_settings_new,
                iconColor: Colors.white38,
                label: 'Quit And Friend',
                onTap: () async {
                  try {
                    await windowManager.close();
                  } catch (_) {
                    exit(0);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSnackPopover() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF202030).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 18),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fastfood, size: 16, color: Colors.orangeAccent),
                const SizedBox(width: 6),
                const Text('Choose a Snack', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 14, color: Colors.white54),
                  onPressed: () => setState(() => _showSnacks = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SnackType.values.map((snack) {
                return InkWell(
                  onTap: () {
                    widget.controller.feed(snack, origin: _menuPosition);
                    setState(() => _showSnacks = false);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 115,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(snack.icon, color: snack.color, size: 22),
                        const SizedBox(height: 4),
                        Text(snack.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('+${snack.hungerRestore.toInt()}%', style: const TextStyle(color: Colors.greenAccent, fontSize: 9)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrickPopover() {
    final mastery = widget.controller.companion.trickMastery;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF202030).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech, size: 16, color: Colors.amberAccent),
                const SizedBox(width: 6),
                const Text('Trick Training Playbook', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 14, color: Colors.white54),
                  onPressed: () => setState(() => _showTricks = false),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 10),
            Expanded(
              child: ListView(
                children: PetTrick.allTricks.map((trick) {
                  final xp = mastery[trick.id] ?? 0;
                  final tier = TrickMasteryTier.fromXp(xp);

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      child: Icon(trick.icon, size: 14, color: Colors.amberAccent),
                    ),
                    title: Text('${trick.name} (${tier.name})', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    subtitle: Text(trick.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 9)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        widget.controller.trainTrick(trick);
                        setState(() => _showTricks = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: const Size(36, 22),
                      ),
                      child: const Text('Train', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- THE VET CLINIC DIAGNOSTIC MODAL ---
  Widget _buildVetModal() {
    final v = widget.controller.vitals;
    final name = widget.controller.companion.name;

    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.redAccent, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Dr. Paws Vet Clinic 🩺',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => setState(() => _showVetDialog = false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Patient: $name  •  Species: ${widget.controller.companion.archetype.name.toUpperCase()}',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.white12, height: 16),
            _buildVetStatRow('Hunger Level', '${v.hunger.toInt()}%', v.hunger > 50 ? Colors.greenAccent : Colors.orangeAccent),
            _buildVetStatRow('Energy Reserve', '${v.energy.toInt()}%', v.energy > 40 ? Colors.blueAccent : Colors.orangeAccent),
            _buildVetStatRow('Joy & Happiness', '${v.happiness.toInt()}%', Colors.pinkAccent),
            _buildVetStatRow('Affection Bond', '${v.affection.toInt()}%', Colors.purpleAccent),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🩺 Vet Diagnosis:', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    v.hunger < 40
                        ? '$name has an empty tummy! Prescribing 1 crunchy Dumpling immediately.'
                        : v.energy < 30
                            ? '$name is running low on battery! Time for a warm catnap.'
                            : '$name is thriving and in peak health! Prescribed 5 extra head pats today.',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _showVetDialog = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Thank You, Doctor!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVetStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}
