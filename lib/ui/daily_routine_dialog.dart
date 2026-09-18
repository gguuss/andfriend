import 'package:flutter/material.dart';
import '../audio/sound_service.dart';
import '../controllers/pet_controller.dart';
import '../models/routine_state.dart';

class DailyRoutineDialog extends StatefulWidget {
  final PetController controller;
  final VoidCallback onClose;

  const DailyRoutineDialog({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<DailyRoutineDialog> createState() => _DailyRoutineDialogState();
}

class _DailyRoutineDialogState extends State<DailyRoutineDialog> {
  final TextEditingController _customHabitController = TextEditingController();
  bool _isAddingCustom = false;

  @override
  void dispose() {
    _customHabitController.dispose();
    super.dispose();
  }

  void _handleAddCustomHabit() {
    final text = _customHabitController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      widget.controller.routineTracker.addCustomItem(
        title: text,
        subtitle: 'Personal daily habit goal',
        icon: Icons.task_alt,
      );
      widget.controller.save();
      _customHabitController.clear();
      _isAddingCustom = false;
    });

    SoundService.instance.playChirp(pitchMultiplier: 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final tracker = widget.controller.routineTracker;
    final progress = tracker.progressRatio;
    final completedCount = tracker.completedCount;
    final totalCount = tracker.totalCount;

    return Material(
      color: Colors.black.withValues(alpha: 0.68),
      child: Center(
        child: Container(
          width: 460,
          constraints: const BoxConstraints(maxHeight: 620),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B2A).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.12),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.checklist_rtl, color: Colors.amberAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Routine & Habits',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.controller.companion.name} is your wellness accountability partner',
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

              // Progress & Streak Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$completedCount of $totalCount completed',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            if (tracker.allCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '🌟 ALL DONE!',
                                  style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        // Streak Flame
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥 ', style: TextStyle(fontSize: 12)),
                              Text(
                                '${tracker.currentStreak} Day Streak',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tracker.allCompleted ? Colors.greenAccent : Colors.amberAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Routine List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: tracker.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = tracker.items[index];
                    return _buildRoutineRow(item);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Custom Habit Bar
              if (_isAddingCustom) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customHabitController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'e.g. 15-minute walk, read 10 pages...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.amberAccent),
                          ),
                        ),
                        onSubmitted: (_) => _handleAddCustomHabit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.greenAccent),
                      onPressed: _handleAddCustomHabit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38),
                      onPressed: () => setState(() => _isAddingCustom = false),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _isAddingCustom = true),
                      icon: const Icon(Icons.add, size: 16, color: Colors.amberAccent),
                      label: const Text('Add Custom Habit', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                    ),
                    if (!tracker.isVitaminsCompleted)
                      Text(
                        'Remember your vitamins! 💊',
                        style: TextStyle(color: Colors.amber.shade200, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineRow(RoutineItem item) {
    final isVitamins = item.id == 'vitamins';

    return InkWell(
      onTap: () {
        setState(() {
          widget.controller.toggleRoutineItem(item.id);
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item.isCompleted
              ? Colors.green.withValues(alpha: 0.12)
              : (isVitamins
                  ? Colors.amber.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isCompleted
                ? Colors.greenAccent.withValues(alpha: 0.4)
                : (isVitamins
                    ? Colors.amberAccent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1)),
            width: isVitamins ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.isCompleted ? Colors.greenAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isCompleted ? Colors.greenAccent : (isVitamins ? Colors.amberAccent : Colors.white38),
                  width: 1.6,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.black87)
                  : null,
            ),
            const SizedBox(width: 12),

            // Icon
            Icon(
              item.icon,
              size: 20,
              color: item.isCompleted
                  ? Colors.greenAccent
                  : (isVitamins ? Colors.amberAccent : Colors.tealAccent),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: item.isCompleted ? Colors.white60 : Colors.white,
                          fontSize: 13,
                          fontWeight: isVitamins ? FontWeight.bold : FontWeight.w600,
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (isVitamins) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('CORE', style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: item.isCompleted ? Colors.white38 : Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // XP Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${item.xpReward} XP',
                style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),

            // Delete for custom items
            if (item.isCustom) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                onPressed: () {
                  setState(() {
                    widget.controller.routineTracker.removeCustomItem(item.id);
                    widget.controller.save();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
