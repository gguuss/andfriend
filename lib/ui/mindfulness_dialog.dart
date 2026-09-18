import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/sound_service.dart';
import '../controllers/pet_controller.dart';
import '../models/mindfulness_state.dart';

class MindfulnessDialog extends StatefulWidget {
  final PetController controller;
  final VoidCallback onClose;

  const MindfulnessDialog({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<MindfulnessDialog> createState() => _MindfulnessDialogState();
}

class _MindfulnessDialogState extends State<MindfulnessDialog> with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: Breathing, 1: Care Nudges & Water, 2: Affirmation Jar

  // Box Breathing state (4s Inhale, 4s Hold, 4s Exhale, 4s Rest)
  bool _isBreathingActive = false;
  String _breathPhaseText = 'Ready to begin';
  double _breathProgress = 0.0;
  Timer? _breathTimer;
  int _breathElapsedMs = 0;
  static const int _phaseDurationMs = 4000;

  @override
  void dispose() {
    _breathTimer?.cancel();
    super.dispose();
  }

  void _toggleBreathing() {
    setState(() {
      _isBreathingActive = !_isBreathingActive;
      if (_isBreathingActive) {
        _startBreathingLoop();
      } else {
        _breathTimer?.cancel();
        _breathPhaseText = 'Paused';
      }
    });
  }

  void _startBreathingLoop() {
    _breathElapsedMs = 0;
    SoundService.instance.playZenChime();
    _breathTimer?.cancel();
    _breathTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _breathElapsedMs += 50;
        final totalCycle = _phaseDurationMs * 4; // 16 seconds
        final cyclePosition = _breathElapsedMs % totalCycle;
        final phaseIndex = cyclePosition ~/ _phaseDurationMs;
        final phaseProgress = (cyclePosition % _phaseDurationMs) / _phaseDurationMs;

        switch (phaseIndex) {
          case 0:
            _breathPhaseText = 'Inhale slowly...';
            _breathProgress = phaseProgress;
            break;
          case 1:
            _breathPhaseText = 'Hold gently...';
            _breathProgress = 1.0;
            break;
          case 2:
            _breathPhaseText = 'Exhale softly...';
            _breathProgress = 1.0 - phaseProgress;
            break;
          case 3:
            _breathPhaseText = 'Rest & reset...';
            _breathProgress = 0.0;
            break;
        }

        // Play subtle zen chime at start of new inhale
        if (cyclePosition == 0) {
          SoundService.instance.playZenChime();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spa, color: Colors.tealAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mindfulness Sanctuary',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.controller.companion.name} is looking after you',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tabs
              Row(
                children: [
                  _buildTabButton(0, 'Box Breathing', Icons.air),
                  const SizedBox(width: 8),
                  _buildTabButton(1, 'Daily Care', Icons.water_drop),
                  const SizedBox(width: 8),
                  _buildTabButton(2, 'Affirmation', Icons.favorite),
                ],
              ),
              const SizedBox(height: 18),

              // Tab Content
              if (_activeTab == 0) _buildBreathingView(),
              if (_activeTab == 1) _buildDailyCareView(),
              if (_activeTab == 2) _buildAffirmationJarView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _activeTab = index);
          SoundService.instance.playChirp(pitchMultiplier: 1.1);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.tealAccent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.tealAccent : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.tealAccent : Colors.white60),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.tealAccent : Colors.white70,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingView() {
    final scale = 0.8 + (_breathProgress * 0.4);

    return Column(
      children: [
        const Text(
          '4-4-4-4 Box Breathing Technique',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Breathing Orb
        SizedBox(
          height: 150,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.tealAccent.withValues(alpha: 0.7),
                      Colors.cyan.shade600.withValues(alpha: 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.tealAccent.withValues(alpha: 0.4),
                      blurRadius: 20 + (_breathProgress * 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.spa,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          _breathPhaseText,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 18),

        ElevatedButton.icon(
          onPressed: _toggleBreathing,
          icon: Icon(_isBreathingActive ? Icons.pause : Icons.play_arrow),
          label: Text(_isBreathingActive ? 'Pause Exercise' : 'Begin 4-4-4-4 Breathing'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyCareView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Wellness Boosts',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Water tracker card
        InkWell(
          onTap: () {
            widget.controller.logHydration();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFF0288D1), shape: BoxShape.circle),
                  child: const Icon(Icons.water_drop, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('I drank a cup of water!', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Tap to log hydration & splash happy droplets', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle, color: Colors.lightBlueAccent, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Trigger Random Reminder
        InkWell(
          onTap: () {
            widget.controller.triggerMindfulnessReminder();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ask for a Wellness Nudge', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Get an instant posture, water, or rest prompt', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.purpleAccent, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAffirmationJarView() {
    return Column(
      children: [
        const Icon(Icons.volunteer_activism, size: 44, color: Colors.pinkAccent),
        const SizedBox(height: 10),
        const Text(
          'Daily Kindness Jar',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Whenever work feels heavy or you need reassurance, pull an affirmation from your companion.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            final affirmation = MindfulnessBank.allQuotes
                .where((q) => q.category == MindfulnessCategory.affirmation)
                .toList();
            affirmation.shuffle();
            widget.controller.triggerMindfulnessReminder(affirmation.first);
          },
          icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 16),
          label: const Text('Pull an Affirmation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }
}
