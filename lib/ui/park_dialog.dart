import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../audio/sound_service.dart';
import '../controllers/pet_controller.dart';
import '../models/exergaming_state.dart';
import '../models/park_state.dart';
import '../services/park_client_service.dart';

class ParkDialog extends StatefulWidget {
  final PetController controller;
  final VoidCallback onClose;

  const ParkDialog({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<ParkDialog> createState() => _ParkDialogState();
}

class _ParkDialogState extends State<ParkDialog> with SingleTickerProviderStateMixin {
  late AnimationController _treeAnimController;
  Offset _myPosition = const Offset(0.5, 0.65);
  ParkCompanion? _selectedPeer;

  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _treeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _serverUrlController.text = ParkClientService.instance.serverUrl;
    _roomCodeController.text = ParkClientService.instance.currentRoomId;

    // Connect to park server (or fallback to cozy offline visitors)
    ParkClientService.instance.connect(companion: widget.controller.companion);
  }

  @override
  void dispose() {
    _treeAnimController.dispose();
    _serverUrlController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  void _onMeadowTap(TapDownDetails details, Size meadowSize) {
    setState(() {
      _selectedPeer = null;
      final rx = (details.localPosition.dx / meadowSize.width).clamp(0.1, 0.9);
      final ry = (details.localPosition.dy / meadowSize.height).clamp(0.15, 0.85);
      _myPosition = Offset(rx, ry);
    });

    ParkClientService.instance.move(_myPosition.dx, _myPosition.dy);
    SoundService.instance.playChirp(pitchMultiplier: 1.1);
  }

  void _openPeerActionDialog(ParkCompanion peer) {
    setState(() => _selectedPeer = peer);
    SoundService.instance.playChirp(pitchMultiplier: 1.25);
  }

  void _sendWarmFuzzy(WarmFuzzyType fuzzy, ParkCompanion target) {
    ParkClientService.instance.sendWarmFuzzy(target.peerId, fuzzy);
    SoundService.instance.playZenChime();

    // Reward player with prosocial joy
    widget.controller.vitals.gainXp(10);
    widget.controller.vitals.happiness = (widget.controller.vitals.happiness + 15.0).clamp(0.0, 100.0);
    widget.controller.save();

    setState(() => _selectedPeer = null);

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('Sent ${fuzzy.label} to ${target.petName}! ✨'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E1E2E),
      ),
    );
  }

  void _shareTreasureGift(BurrowTreasure gift, ParkCompanion target) {
    ParkClientService.instance.sendGift(target.peerId, gift);
    SoundService.instance.playFanfare();

    widget.controller.vitals.gainXp(30);
    widget.controller.vitals.affection = (widget.controller.vitals.affection + 20.0).clamp(0.0, 100.0);
    widget.controller.save();

    setState(() => _selectedPeer = null);
  }

  void _openRoomSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Park & Server Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _roomCodeController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Room Name or Friend Code',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g. cozy-meadow, FOX-942',
                  hintStyle: TextStyle(color: Colors.white30),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serverUrlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Server WebSocket URL',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'ws://localhost:8080/ws',
                  hintStyle: TextStyle(color: Colors.white30),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ParkClientService.instance.connect(
                  url: _serverUrlController.text.trim(),
                  roomId: _roomCodeController.text.trim(),
                  companion: widget.controller.companion,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen.shade700),
              child: const Text('Connect & Switch Room', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = ParkClientService.instance;
    final myComp = widget.controller.companion;

    return Material(
      color: Colors.black.withValues(alpha: 0.70),
      child: Center(
        child: Container(
          width: 650,
          height: 520,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF161A28).withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.lightGreenAccent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.lightGreenAccent.withValues(alpha: 0.16),
                blurRadius: 36,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.lightGreenAccent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.park, color: Colors.lightGreenAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'The Park Sanctuary 🌳',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          client.isConnected
                              ? 'Online Room: "${client.currentRoomId}" • ${client.peers.length + 1} companions roaming'
                              : (client.isOfflineMode
                                  ? 'Cozy Sanctuary (Offline Mode with Visiting NPCs)'
                                  : 'Connecting to park server...'),
                          style: TextStyle(
                            color: client.isConnected ? Colors.lightGreenAccent : Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white70, size: 20),
                    tooltip: 'Park Server Settings',
                    onPressed: _openRoomSettings,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Meadow Canvas
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([client, _treeAnimController]),
                    builder: (context, _) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final size = Size(constraints.maxWidth, constraints.maxHeight);

                          return GestureDetector(
                            onTapDown: (details) => _onMeadowTap(details, size),
                            child: Stack(
                              children: [
                                // Pastoral Meadow Background Painter
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _MeadowPainter(
                                      treeSway: _treeAnimController.value,
                                    ),
                                  ),
                                ),

                                // Remote / NPC Peers
                                ...client.peers.values.map((peer) {
                                  final px = peer.x * size.width;
                                  final py = peer.y * size.height;

                                  return Positioned(
                                    left: px - 35,
                                    top: py - 40,
                                    child: GestureDetector(
                                      onTap: () => _openPeerActionDialog(peer),
                                      child: _buildCompanionAvatar(
                                        name: peer.petName,
                                        primaryColor: peer.primaryColor,
                                        accentColor: peer.accentColor,
                                        isNpc: peer.isNpc,
                                        thought: peer.hasActiveThought ? peer.activeThought : null,
                                        isSelected: _selectedPeer?.peerId == peer.peerId,
                                      ),
                                    ),
                                  );
                                }),

                                // Your Companion
                                Positioned(
                                  left: _myPosition.dx * size.width - 35,
                                  top: _myPosition.dy * size.height - 40,
                                  child: _buildCompanionAvatar(
                                    name: '${myComp.name} (You)',
                                    primaryColor: myComp.primaryColor,
                                    accentColor: myComp.accentColor,
                                    isMe: true,
                                  ),
                                ),

                                // Selected Peer Action Sheet Overlay
                                if (_selectedPeer != null)
                                  Positioned(
                                    bottom: 12,
                                    left: 20,
                                    right: 20,
                                    child: _buildPeerActionSheet(_selectedPeer!),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Bottom Prosocial Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🌸 Click anywhere on grass to stroll. Click friends to send care.',
                    style: TextStyle(color: Colors.white54, fontSize: 10.5),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      SoundService.instance.playZenChime();
                      widget.controller.vitals.gainXp(15);
                      widget.controller.vitals.happiness = (widget.controller.vitals.happiness + 10).clamp(0.0, 100.0);
                      widget.controller.save();
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(
                          content: Text('Watered the Community Care Tree! 🌸 (+15 XP)'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF1E1E2E),
                        ),
                      );
                    },
                    icon: const Icon(Icons.water_drop, size: 14, color: Colors.cyanAccent),
                    label: const Text('Tend Community Tree', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanionAvatar({
    required String name,
    required Color primaryColor,
    required Color accentColor,
    bool isMe = false,
    bool isNpc = false,
    bool isSelected = false,
    String? thought,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (thought != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: Text(
              thought,
              style: const TextStyle(color: Colors.white, fontSize: 9.5),
            ),
          ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor,
            border: Border.all(
              color: isSelected
                  ? Colors.amberAccent
                  : (isMe ? Colors.white : accentColor),
              width: isSelected ? 3.0 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isNpc ? Icons.pets : Icons.favorite,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: isMe ? Colors.lightGreenAccent : Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeerActionSheet(ParkCompanion peer) {
    final treasures = widget.controller.exergamingRecord.treasures;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 18),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism, size: 16, color: Colors.pinkAccent),
              const SizedBox(width: 8),
              Text(
                'Interact with ${peer.petName}',
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onPressed: () => setState(() => _selectedPeer = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Send a Warm Fuzzy (Affirmation):', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
          const SizedBox(height: 6),

          // Warm Fuzzy Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: WarmFuzzyType.values.map((f) {
              return InkWell(
                onTap: () => _sendWarmFuzzy(f, peer),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: f.color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.icon, size: 12, color: f.color),
                      const SizedBox(width: 4),
                      Text(f.label, style: TextStyle(color: f.color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (treasures.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Gift an Unearthed Burrow Treasure:', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: math.min(treasures.length, 5),
                itemBuilder: (context, idx) {
                  final t = treasures[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ElevatedButton.icon(
                      onPressed: () => _shareTreasureGift(t, peer),
                      icon: Icon(t.icon, size: 12, color: t.rarity.color),
                      label: Text(t.name, style: const TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for The Park's soothing grass meadow and Community Care Tree
class _MeadowPainter extends CustomPainter {
  final double treeSway;

  const _MeadowPainter({required this.treeSway});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Lush Pastoral Meadow Gradient
    final meadowRect = Offset.zero & size;
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E3A2B),
          const Color(0xFF142B20),
        ],
      ).createShader(meadowRect);
    canvas.drawRect(meadowRect, grassPaint);

    // 2. Gentle Winding Stone Footpath
    final pathPaint = Paint()
      ..color = const Color(0xFF3B483C).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round;

    final stonePath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.65,
        size.width * 0.5,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.45,
        size.width * 0.9,
        size.height * 0.3,
      );
    canvas.drawPath(stonePath, pathPaint);

    // 3. Central Community Care Tree
    final treeX = size.width * 0.5;
    final treeY = size.height * 0.45;
    final swayOffset = (treeSway - 0.5) * 6.0;

    // Tree Trunk
    final trunkPaint = Paint()..color = const Color(0xFF5D4037);
    final trunkPath = Path()
      ..moveTo(treeX - 12, treeY + 30)
      ..lineTo(treeX - 8, treeY - 10)
      ..lineTo(treeX + 8, treeY - 10)
      ..lineTo(treeX + 12, treeY + 30)
      ..close();
    canvas.drawPath(trunkPath, trunkPaint);

    // Blossom Foliage Canopy
    final canopyCenter = Offset(treeX + swayOffset, treeY - 25);
    final canopyPaint = Paint()
      ..color = const Color(0xFFFFB7B2).withValues(alpha: 0.85);
    canvas.drawCircle(canopyCenter, 38, canopyPaint);

    final highlightPaint = Paint()
      ..color = const Color(0xFFFFDAC1).withValues(alpha: 0.7);
    canvas.drawCircle(canopyCenter + const Offset(-10, -10), 22, highlightPaint);

    // Blossom Aura Glow
    final glowPaint = Paint()
      ..color = Colors.pinkAccent.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(canopyCenter, 48, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _MeadowPainter oldDelegate) =>
      oldDelegate.treeSway != treeSway;
}
