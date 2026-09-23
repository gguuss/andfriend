import 'package:flutter/material.dart';
import '../audio/sound_service.dart';
import '../controllers/pet_controller.dart';
import '../models/exergaming_state.dart';

class ExergamingDialog extends StatefulWidget {
  final PetController controller;
  final VoidCallback onClose;

  const ExergamingDialog({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<ExergamingDialog> createState() => _ExergamingDialogState();
}

class _ExergamingDialogState extends State<ExergamingDialog> {
  int _activeTab = 0; // 0: Steps & Progress, 1: Walk with Friend (Live), 2: Burrow Treasures
  final TextEditingController _customStepsController = TextEditingController();

  @override
  void dispose() {
    _customStepsController.dispose();
    super.dispose();
  }

  void _quickAddSteps(int steps) {
    widget.controller.recordSteps(steps);
    SoundService.instance.playChirp(pitchMultiplier: 1.2);
  }

  void _submitCustomSteps() {
    final text = _customStepsController.text.trim();
    final steps = int.tryParse(text);
    if (steps != null && steps > 0) {
      widget.controller.recordSteps(steps);
      _customStepsController.clear();
      SoundService.instance.playFanfare();
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.controller.exergamingRecord;
    final companion = widget.controller.companion;

    return Material(
      color: Colors.black.withValues(alpha: 0.70),
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1C2E).withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.lightGreenAccent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.lightGreenAccent.withValues(alpha: 0.15),
                blurRadius: 36,
                spreadRadius: 3,
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
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.lightGreenAccent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_walk, color: Colors.lightGreenAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Exergaming & Movement Loop',
                          style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Walking alongside ${companion.name} (+20% Activity Lift)',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
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

              // Tab Selector Buttons
              Row(
                children: [
                  _buildTabButton(0, 'Daily Steps', Icons.stacked_line_chart),
                  const SizedBox(width: 8),
                  _buildTabButton(1, 'Live Walk', Icons.timer),
                  const SizedBox(width: 8),
                  _buildTabButton(2, 'Treasures (${record.treasures.length})', Icons.auto_awesome),
                ],
              ),
              const SizedBox(height: 18),

              // Active Tab Content
              if (_activeTab == 0) _buildDailyStepsView(record),
              if (_activeTab == 1) _buildLiveWalkView(),
              if (_activeTab == 2) _buildTreasuresView(record),
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
            color: isSelected ? Colors.lightGreenAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.lightGreenAccent : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.lightGreenAccent : Colors.white60),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.lightGreenAccent : Colors.white70,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyStepsView(DailyExergamingRecord record) {
    final progress = record.targetProgress;
    final percent = (progress * 100).toInt();

    return Column(
      children: [
        // Activity Progress Ring & Metrics
        Row(
          children: [
            // Circular Progress Indicator
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${record.currentSteps}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$percent% of goal',
                        style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),

            // Stat Badges
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildMiniStat(Icons.route, '${record.distanceKm} km', 'Distance'),
                      const SizedBox(width: 8),
                      _buildMiniStat(Icons.local_fire_department, '${record.estimatedCalories}', 'Est. kcal'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMiniStat(Icons.hourglass_bottom, '${record.activeMinutes} min', 'Pacing time'),
                      const SizedBox(width: 8),
                      _buildMiniStat(Icons.shield_outlined, '${record.staminaBuffer.toInt()}%', 'Stamina buffer'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tier Milestone Badges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: StepGoalTier.values.map((tier) {
            final achieved = record.isTierAchieved(tier);
            return Tooltip(
              message: '${tier.name} (${tier.stepThreshold} steps) - +${tier.xpReward} XP',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: achieved ? tier.color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: achieved ? tier.color : Colors.white12,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(tier.icon, size: 14, color: achieved ? tier.color : Colors.white30),
                    const SizedBox(width: 4),
                    Text(
                      '${tier.stepThreshold ~/ 1000}k',
                      style: TextStyle(
                        color: achieved ? Colors.white : Colors.white38,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (achieved) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.check, size: 11, color: Colors.lightGreenAccent),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Quick Log Buttons
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Quick-Log Smartwatch / Phone Steps',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuickLogButton('+500', 500),
            const SizedBox(width: 6),
            _buildQuickLogButton('+1,000', 1000),
            const SizedBox(width: 6),
            _buildQuickLogButton('+2,500', 2500),
            const SizedBox(width: 8),
            // Custom number input
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: _customStepsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Custom...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.lightGreenAccent, size: 18),
                      onPressed: _submitCustomSteps,
                    ),
                  ),
                  onSubmitted: (_) => _submitCustomSteps(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '🌱 Non-punitive: All steps are additive. Zero guilt or penalties for low-movement days.',
          style: TextStyle(color: Colors.white38, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.lightGreenAccent),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogButton(String label, int steps) {
    return InkWell(
      onTap: () => _quickAddSteps(steps),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.lightGreenAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.lightGreenAccent.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLiveWalkView() {
    final ctrl = widget.controller;
    final isWalking = ctrl.isWalkingSessionActive;
    final seconds = ctrl.walkingSessionElapsedSeconds;
    final minutesStr = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsStr = (seconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.lightGreenAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.lightGreenAccent.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(
                isWalking ? Icons.directions_walk : Icons.accessibility_new,
                size: 44,
                color: isWalking ? Colors.lightGreenAccent : Colors.white60,
              ),
              const SizedBox(height: 8),
              Text(
                isWalking ? 'Walking Together' : 'Ready for a Walk?',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isWalking
                    ? 'Pacing active! Steps accumulate dynamically (~100 steps/min).'
                    : 'Take a gentle walking pad stroll or stretch break with your companion.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 14),

              // Timer & Session Steps
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$minutesStr:$secondsStr',
                      style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${ctrl.walkingSessionSteps} steps',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: () {
            if (isWalking) {
              ctrl.stopWalkSession();
            } else {
              ctrl.startWalkSession();
            }
          },
          icon: Icon(isWalking ? Icons.stop : Icons.play_arrow),
          label: Text(isWalking ? 'Finish Walk' : 'Start Walking Companion'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isWalking ? Colors.orange.shade800 : Colors.lightGreen.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTreasuresView(DailyExergamingRecord record) {
    if (record.treasures.isEmpty) {
      return Column(
        children: [
          const Icon(Icons.park_outlined, size: 48, color: Colors.white30),
          const SizedBox(height: 10),
          const Text(
            'No Burrow Treasures Unearthed Yet',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Take walks and cross step milestones (Bronze, Silver, Gold, Platinum) to unearth rare artifacts and items your friend tucks into the burrow!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artifacts Unearthed Along the Path',
          style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.builder(
            itemCount: record.treasures.length,
            itemBuilder: (context, index) {
              final treasure = record.treasures[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: treasure.rarity.color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: treasure.rarity.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(treasure.icon, color: treasure.rarity.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                treasure.name,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: treasure.rarity.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  treasure.rarity.label,
                                  style: TextStyle(color: treasure.rarity.color, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            treasure.description,
                            style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
