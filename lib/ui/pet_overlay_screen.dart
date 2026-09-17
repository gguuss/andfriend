import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../audio/sound_service.dart';
import '../controllers/pet_controller.dart';
import '../core/cursor_tracker.dart';
import '../graphics/pet_painter.dart';
import '../models/pet_state.dart';
import '../models/trick_system.dart';
import 'builder/companion_builder_dialog.dart';

class PetOverlayScreen extends StatefulWidget {
  final PetController controller;

  const PetOverlayScreen({super.key, required this.controller});

  @override
  State<PetOverlayScreen> createState() => _PetOverlayScreenState();
}

class _PetOverlayScreenState extends State<PetOverlayScreen> {
  bool _showMenu = false;
  bool _showVitals = false;
  bool _showSnacks = false;
  bool _showTricks = false;

  Timer? _cursorPollTimer;

  @override
  void initState() {
    super.initState();
    // Poll global cursor position periodically (10Hz) to update gaze even if cursor is outside window
    _cursorPollTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      CursorTracker.instance.updateGazeFromScreen(
        petScreenPos: const Offset(150, 160),
      );
    });
  }

  @override
  void dispose() {
    _cursorPollTimer?.cancel();
    super.dispose();
  }

  void _openBuilderWizard() {
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // 1. Draggable background area (drag companion window)
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: (details) async {
                    // Start dragging window if supported by window_manager
                    try {
                      await windowManager.startDragging();
                    } catch (_) {}
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),

              // 2. Main Pet Canvas with Mouse Tracking & Petting
              Positioned.fill(
                child: ValueListenableBuilder<Offset>(
                  valueListenable: CursorTracker.instance.gazeOffset,
                  builder: (context, gaze, child) {
                    return ValueListenableBuilder<double>(
                      valueListenable: CursorTracker.instance.gazeDistance,
                      builder: (context, dist, child) {
                        return MouseRegion(
                          onHover: (event) {
                            // Update local gaze vector and detect petting/tickles
                            CursorTracker.instance.updateGazeFromLocal(
                              cursorLocal: event.localPosition,
                              petCenterLocal: const Offset(150, 160),
                            );
                            ctrl.handlePointerMove(event.localPosition);
                          },
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showMenu = !_showMenu;
                                if (!_showMenu) {
                                  _showSnacks = false;
                                  _showTricks = false;
                                }
                              });
                              SoundService.instance.playChirp();
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
                                particles: ctrl.particles,
                                hasBurrow: ctrl.hasBurrow,
                                burrowCorner: ctrl.burrowCorner,
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

              // 3. Floating Thought / Dialogue Bubble
              if (ctrl.thoughtBubble != null)
                Positioned(
                  top: 25,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: _buildThoughtBubble(ctrl.thoughtBubble!),
                  ),
                ),

              // 4. Floating Action Menu Buttons
              if (_showMenu)
                Positioned(
                  bottom: 8,
                  left: 12,
                  right: 12,
                  child: _buildActionToolbar(),
                ),

              // 5. Snack Selection Popover
              if (_showSnacks)
                Positioned(
                  bottom: 60,
                  left: 20,
                  right: 20,
                  child: _buildSnackTray(),
                ),

              // 6. Trick Training Selection Drawer
              if (_showTricks)
                Positioned(
                  bottom: 60,
                  left: 16,
                  right: 16,
                  child: _buildTrickTray(),
                ),

              // 7. Vitals Quick Drawer
              if (_showVitals)
                Positioned(
                  top: 75,
                  left: 20,
                  right: 20,
                  child: _buildVitalsPanel(),
                ),

              // 8. Top Control Bar (Sound toggle, Vitals toggle, Builder, Close)
              Positioned(
                top: 8,
                right: 8,
                child: _buildTopControlPill(),
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
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
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

  Widget _buildTopControlPill() {
    final sound = SoundService.instance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF181824).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sound Mute Toggle
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              sound.isMuted ? Icons.volume_off : Icons.volume_up,
              size: 16,
              color: sound.isMuted ? Colors.redAccent : Colors.greenAccent,
            ),
            tooltip: sound.isMuted ? 'Unmute Sound' : 'Mute Sound',
            onPressed: () {
              sound.toggleMute();
              setState(() {});
            },
          ),
          // Vitals Toggle
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              _showVitals ? Icons.bar_chart : Icons.show_chart,
              size: 16,
              color: Colors.amberAccent,
            ),
            tooltip: 'Pet Vitals',
            onPressed: () => setState(() => _showVitals = !_showVitals),
          ),
          // Builder Wizard Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.purpleAccent),
            tooltip: 'Companion Builder',
            onPressed: _openBuilderWizard,
          ),
          // Minimize / Hide
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.close, size: 14, color: Colors.white60),
            tooltip: 'Close Companion',
            onPressed: () async {
              try {
                await windowManager.close();
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar() {
    final ctrl = widget.controller;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF181824).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Feed
          _buildToolButton(
            icon: Icons.fastfood,
            label: 'Feed',
            color: Colors.orangeAccent,
            onTap: () {
              setState(() {
                _showSnacks = !_showSnacks;
                _showTricks = false;
              });
            },
          ),
          // Sleep / Wake
          _buildToolButton(
            icon: ctrl.mood == PetMood.sleeping ? Icons.wb_sunny : Icons.bedtime,
            label: ctrl.mood == PetMood.sleeping ? 'Wake' : 'Sleep',
            color: Colors.indigoAccent,
            onTap: () => ctrl.toggleSleep(),
          ),
          // Tickle
          _buildToolButton(
            icon: Icons.favorite,
            label: 'Pet',
            color: Colors.pinkAccent,
            onTap: () => ctrl.handlePointerMove(const Offset(150, 160)),
          ),
          // Train Tricks
          _buildToolButton(
            icon: Icons.military_tech,
            label: 'Tricks',
            color: Colors.amberAccent,
            onTap: () {
              setState(() {
                _showTricks = !_showTricks;
                _showSnacks = false;
              });
            },
          ),
          // Burrow
          _buildToolButton(
            icon: Icons.landscape,
            label: ctrl.hasBurrow ? 'Burrow' : 'Dig',
            color: Colors.brown.shade300,
            onTap: () => ctrl.toggleBurrowPeek(),
          ),
          // Desktop Sniff
          _buildToolButton(
            icon: Icons.folder_open,
            label: 'Sniff',
            color: Colors.tealAccent,
            onTap: () => ctrl.sniffDesktop(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnackTray() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF222232).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: SnackType.values.map((snack) {
          return InkWell(
            onTap: () {
              widget.controller.feed(snack);
              setState(() => _showSnacks = false);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(snack.icon, color: snack.color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    snack.name,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '+${snack.hungerRestore.toInt()}%',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrickTray() {
    final mastery = widget.controller.companion.trickMastery;

    return Container(
      height: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222232).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, size: 16, color: Colors.amberAccent),
              const SizedBox(width: 6),
              const Text(
                'Trick Training Playbook',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 14, color: Colors.white60),
                onPressed: () => setState(() => _showTricks = false),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 12),
          Expanded(
            child: ListView(
              children: PetTrick.allTricks.map((trick) {
                final xp = mastery[trick.id] ?? 0;
                final tier = TrickMasteryTier.fromXp(xp);

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.amber.withValues(alpha: 0.15),
                    child: Icon(trick.icon, size: 16, color: Colors.amberAccent),
                  ),
                  title: Row(
                    children: [
                      Text(trick.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text('(${tier.name})', style: TextStyle(color: tier.color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  subtitle: Text(
                    trick.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      widget.controller.trainTrick(trick);
                      setState(() => _showTricks = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(40, 26),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Train', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsPanel() {
    final v = widget.controller.vitals;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lv. ${v.level} • XP ${v.currentXp}/${v.level * 100}',
                style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'Mood: ${widget.controller.mood.name}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildVitalBar('Hunger', v.hunger, Colors.orangeAccent),
          _buildVitalBar('Energy', v.energy, Colors.blueAccent),
          _buildVitalBar('Happiness', v.happiness, Colors.pinkAccent),
          _buildVitalBar('Affection', v.affection, Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildVitalBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (value / 100.0).clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${value.toInt()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
