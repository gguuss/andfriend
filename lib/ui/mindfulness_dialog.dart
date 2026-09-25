import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/sound_service.dart';
import '../controllers/pet_controller.dart';
import '../models/eft_tapping_state.dart';
import '../models/grounding_state.dart';
import '../models/mindfulness_state.dart';

enum BreathingTechnique {
  diaphragmatic478(
    title: '4-7-8 Diaphragmatic',
    subtitle: 'Vagus nerve stimulation (4s Inhale, 7s Hold, 8s Exhale)',
    inhaleMs: 4000,
    holdMs: 7000,
    exhaleMs: 8000,
    restMs: 0,
  ),
  box(
    title: '4-4-4-4 Box',
    subtitle: 'Autonomic reset & focus (4s Inhale, 4s Hold, 4s Exhale, 4s Rest)',
    inhaleMs: 4000,
    holdMs: 4000,
    exhaleMs: 4000,
    restMs: 4000,
  );

  final String title;
  final String subtitle;
  final int inhaleMs;
  final int holdMs;
  final int exhaleMs;
  final int restMs;

  const BreathingTechnique({
    required this.title,
    required this.subtitle,
    required this.inhaleMs,
    required this.holdMs,
    required this.exhaleMs,
    required this.restMs,
  });

  int get totalCycleMs => inhaleMs + holdMs + exhaleMs + restMs;
}

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
  int _activeTab = 0; // 0: Breathing, 1: EFT Tapping, 2: Care Nudges & Water, 3: Affirmation Jar

  // Breathing state
  BreathingTechnique _technique = BreathingTechnique.diaphragmatic478;
  bool _isBreathingActive = false;
  String _breathPhaseText = 'Ready to begin';
  double _breathProgress = 0.0;
  Timer? _breathTimer;
  int _breathElapsedMs = 0;
  int _lastPhaseIndex = -1;

  // EFT Tapping session
  final EftTappingSession _eftSession = EftTappingSession();
  bool _eftClaimed = false;

  // 5-Sense Grounding session
  final GroundingScanSession _groundingSession = GroundingScanSession();
  bool _groundingClaimed = false;

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
        _lastPhaseIndex = -1;
      }
    });
  }

  void _switchTechnique(BreathingTechnique tech) {
    if (_technique == tech) return;
    setState(() {
      _technique = tech;
      _breathElapsedMs = 0;
      _breathProgress = 0.0;
      _lastPhaseIndex = -1;
      if (_isBreathingActive) {
        _startBreathingLoop();
      } else {
        _breathPhaseText = 'Ready for ${tech.title}';
      }
    });
  }

  void _startBreathingLoop() {
    _breathElapsedMs = 0;
    _lastPhaseIndex = -1;
    SoundService.instance.playZenChime();
    _breathTimer?.cancel();

    _breathTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _breathElapsedMs += 50;
        final totalCycle = _technique.totalCycleMs;
        final cyclePosition = _breathElapsedMs % totalCycle;

        int phaseIndex = 0;
        double phaseProgress = 0.0;

        if (_technique == BreathingTechnique.box) {
          // 4 equal phases of 4000ms
          const p = 4000;
          phaseIndex = cyclePosition ~/ p;
          phaseProgress = (cyclePosition % p) / p;

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
        } else {
          // 4-7-8 Diaphragmatic (4s Inhale, 7s Hold, 8s Exhale)
          const inDuration = 4000;
          const holdDuration = 7000;
          const exDuration = 8000;

          if (cyclePosition < inDuration) {
            phaseIndex = 0;
            phaseProgress = cyclePosition / inDuration;
            _breathPhaseText = 'Inhale deeply (Nose)...';
            _breathProgress = phaseProgress;
          } else if (cyclePosition < inDuration + holdDuration) {
            phaseIndex = 1;
            phaseProgress = (cyclePosition - inDuration) / holdDuration;
            _breathPhaseText = 'Hold breath gently...';
            _breathProgress = 1.0;
          } else {
            phaseIndex = 2;
            phaseProgress = (cyclePosition - inDuration - holdDuration) / exDuration;
            _breathPhaseText = 'Whoosh exhale (Mouth)...';
            _breathProgress = 1.0 - phaseProgress;
          }
        }

        // Play chime on phase transition
        if (phaseIndex != _lastPhaseIndex) {
          _lastPhaseIndex = phaseIndex;
          SoundService.instance.playZenChime();
        }
      });
    });
  }

  void _onEftTap() {
    if (_eftSession.isCompleted) return;

    setState(() {
      final pointBefore = _eftSession.currentPointIndex;
      final transitioned = _eftSession.registerTap();

      if (_eftSession.isCompleted) {
        SoundService.instance.playFanfare();
      } else if (transitioned || _eftSession.currentPointIndex != pointBefore) {
        SoundService.instance.playZenChime();
      } else {
        // Play subtly ascending tone per tap
        final pitch = 1.0 + (_eftSession.currentPointTapCount * 0.08);
        SoundService.instance.playChirp(pitchMultiplier: pitch);
      }
    });
  }

  void _claimEftBlessing() {
    setState(() {
      _eftClaimed = true;
    });
    widget.controller.completeEftSession();
    SoundService.instance.playFanfare();
  }

  void _resetEftSession() {
    setState(() {
      _eftSession.reset();
      _eftClaimed = false;
    });
    SoundService.instance.playChirp(pitchMultiplier: 1.2);
  }

  void _onGroundingItemTap() {
    if (_groundingSession.isCompleted) return;

    setState(() {
      final indexBefore = _groundingSession.currentSenseIndex;
      final transitioned = _groundingSession.registerItem();

      if (_groundingSession.isCompleted) {
        SoundService.instance.playFanfare();
      } else if (transitioned || _groundingSession.currentSenseIndex != indexBefore) {
        SoundService.instance.playZenChime();
      } else {
        final pitch = 1.0 + (_groundingSession.currentSenseCount * 0.08);
        SoundService.instance.playChirp(pitchMultiplier: pitch);
      }
    });
  }

  void _claimGroundingReward() {
    if (_groundingClaimed) return;
    setState(() {
      _groundingClaimed = true;
    });
    widget.controller.completeGroundingSession();
    SoundService.instance.playFanfare();
  }

  void _resetGroundingSession() {
    setState(() {
      _groundingSession.reset();
      _groundingClaimed = false;
    });
    SoundService.instance.playChirp(pitchMultiplier: 1.2);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.70),
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withValues(alpha: 0.18),
                blurRadius: 32,
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
                          'Mindfulness & Somatic Sanctuary',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.controller.companion.name} is grounding with you',
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

              // 5 Tabs: Breathing, EFT Tapping, 5-Sense Grounding, Daily Care, Affirmation
              Row(
                children: [
                  _buildTabButton(0, 'Breathing', Icons.air),
                  const SizedBox(width: 4),
                  _buildTabButton(1, 'EFT Tap', Icons.touch_app),
                  const SizedBox(width: 4),
                  _buildTabButton(2, '5-Sense', Icons.spa),
                  const SizedBox(width: 4),
                  _buildTabButton(3, 'Care', Icons.water_drop),
                  const SizedBox(width: 4),
                  _buildTabButton(4, 'Affirmation', Icons.favorite),
                ],
              ),
              const SizedBox(height: 18),

              // Tab Content
              if (_activeTab == 0) _buildBreathingView(),
              if (_activeTab == 1) _buildEftTappingView(),
              if (_activeTab == 2) _buildGroundingView(),
              if (_activeTab == 3) _buildDailyCareView(),
              if (_activeTab == 4) _buildAffirmationJarView(),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.tealAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.tealAccent : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: isSelected ? Colors.tealAccent : Colors.white60),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.tealAccent : Colors.white70,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
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
        // Mode Selector Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTechniquePill(BreathingTechnique.diaphragmatic478, '4-7-8 Diaphragmatic'),
            const SizedBox(width: 8),
            _buildTechniquePill(BreathingTechnique.box, '4-4-4-4 Box'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _technique.subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Concentric Diaphragmatic Breath Pacing Rings
        SizedBox(
          height: 160,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer aura ring 2
                Transform.scale(
                  scale: 0.7 + (_breathProgress * 0.55),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.tealAccent.withValues(alpha: 0.15 + (_breathProgress * 0.25)),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Middle aura ring 1
                Transform.scale(
                  scale: 0.75 + (_breathProgress * 0.45),
                  child: Container(
                    width: 125,
                    height: 125,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.25 + (_breathProgress * 0.35)),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Main breathing orb
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.tealAccent.withValues(alpha: 0.85),
                          Colors.cyan.shade700.withValues(alpha: 0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.tealAccent.withValues(alpha: 0.45),
                          blurRadius: 22 + (_breathProgress * 18),
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.spa,
                        color: Colors.white.withValues(alpha: 0.95),
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        Text(
          _breathPhaseText,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: _toggleBreathing,
          icon: Icon(_isBreathingActive ? Icons.pause : Icons.play_arrow),
          label: Text(_isBreathingActive ? 'Pause Exercise' : 'Begin ${_technique.title}'),
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

  Widget _buildTechniquePill(BreathingTechnique tech, String title) {
    final isSelected = _technique == tech;
    return InkWell(
      onTap: () => _switchTechnique(tech),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.tealAccent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.tealAccent : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.tealAccent : Colors.white60,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEftTappingView() {
    final currentPoint = _eftSession.currentPoint;

    if (_eftSession.isCompleted) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars, color: Colors.amberAccent, size: 48),
                const SizedBox(height: 10),
                const Text(
                  'Somatic Meridian Session Complete!',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your 5 somatic meridian points are calibrated and down-regulated. Parasympathetic nervous tone restored.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                if (!_eftClaimed)
                  ElevatedButton.icon(
                    onPressed: _claimEftBlessing,
                    icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                    label: const Text('Claim Zen Blessing (+35 XP, +25 Hap)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                  )
                else
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.tealAccent, size: 18),
                      SizedBox(width: 6),
                      Text('Blessing applied to companion!', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _resetEftSession,
            icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
            label: const Text('Tap with Friend Again', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Meridian Progress Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(EftMeridianPoint.values.length, (index) {
            final point = EftMeridianPoint.values[index];
            final isDone = index < _eftSession.currentPointIndex;
            final isCurrent = index == _eftSession.currentPointIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: point.name,
                child: Container(
                  width: isCurrent ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.tealAccent
                        : (isCurrent ? Colors.amberAccent : Colors.white24),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: Colors.amberAccent.withValues(alpha: 0.6),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // Meridian point info card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.tealAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(currentPoint.icon, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Point ${_eftSession.currentPointIndex + 1}/5: ${currentPoint.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                currentPoint.clinicalFocus,
                style: const TextStyle(color: Colors.tealAccent, fontSize: 10.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '"${currentPoint.affirmation}"',
                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Interactive Somatic Tapping Ring Button
        GestureDetector(
          onTap: _onEftTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.amberAccent.withValues(alpha: 0.8),
                  Colors.orange.shade700.withValues(alpha: 0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.35 + (_eftSession.pointProgress * 0.35)),
                  blurRadius: 18 + (_eftSession.pointProgress * 14),
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(
                color: Colors.amberAccent,
                width: 2.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app, color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Tap Here',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_eftSession.currentPointTapCount} / ${EftTappingSession.tapsPerPoint}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Gently tap 5 times while breathing and repeating the somatic affirmation.',
          style: TextStyle(color: Colors.white54, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGroundingView() {
    if (_groundingSession.isCompleted) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.spa, color: Colors.tealAccent, size: 44),
                const SizedBox(height: 8),
                const Text(
                  '5-Sense Grounding Complete!',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'All 5 sensory checkpoints acknowledged. Mental rumination interrupted and parasympathetic vagal tone restored.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                if (!_groundingClaimed)
                  ElevatedButton.icon(
                    onPressed: _claimGroundingReward,
                    icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                    label: const Text('Claim Grounding (+30 XP, +20 Hap)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                  )
                else
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.tealAccent, size: 18),
                      SizedBox(width: 6),
                      Text('Anchoring applied to companion!', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _resetGroundingSession,
            icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
            label: const Text('Run 5-Sense Scan Again', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
        ],
      );
    }

    final sense = _groundingSession.currentSense;

    return Column(
      children: [
        // 5 Sense Category Indicators (See 5, Feel 4, Hear 3, Smell 2, Taste 1)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(GroundingSense.values.length, (index) {
            final s = GroundingSense.values[index];
            final isDone = index < _groundingSession.currentSenseIndex;
            final isCurrent = index == _groundingSession.currentSenseIndex;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Tooltip(
                  message: '${s.name} (${s.targetCount})',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isDone
                          ? s.color.withValues(alpha: 0.28)
                          : (isCurrent ? s.color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDone
                            ? s.color
                            : (isCurrent ? s.color : Colors.white12),
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: s.color.withValues(alpha: 0.45),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isDone ? '✓' : '${s.order}',
                          style: TextStyle(
                            color: isDone || isCurrent ? s.color : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // Active Sense Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sense.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sense.color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: sense.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(sense.icon, color: sense.color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${sense.emoji} ${sense.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sense.instruction,
                          style: TextStyle(color: sense.color.withValues(alpha: 0.9), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sense.prompt,
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Interactive Item Checklist / Tap Bubbles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(sense.targetCount, (itemIndex) {
                  final isLogged = itemIndex < _groundingSession.currentSenseCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isLogged ? sense.color : Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLogged ? sense.color : Colors.white24,
                          width: 1.2,
                        ),
                        boxShadow: isLogged
                            ? [
                                BoxShadow(
                                  color: sense.color.withValues(alpha: 0.5),
                                  blurRadius: 5,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isLogged
                            ? const Icon(Icons.check, size: 14, color: Colors.black87)
                            : Text(
                                '${itemIndex + 1}',
                                style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Tap Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onGroundingItemTap,
                  icon: const Icon(Icons.check_circle_outline, size: 15),
                  label: Text(
                    'Acknowledge ${sense.shortName} (${_groundingSession.currentSenseCount}/${sense.targetCount})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sense.color,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
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
