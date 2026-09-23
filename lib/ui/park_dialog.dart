import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../audio/sound_service.dart';
import '../controllers/pet_controller.dart';
import '../models/exergaming_state.dart';
import '../models/park_state.dart';
import '../services/park_client_service.dart';

class ParkCareEvent {
  final String senderName;
  final Offset senderPosition;
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const ParkCareEvent({
    required this.senderName,
    required this.senderPosition,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

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

class _ParkDialogState extends State<ParkDialog> with TickerProviderStateMixin {
  late AnimationController _treeAnimController;
  late AnimationController _careAnimController;
  ParkCareEvent? _currentCareEvent;
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

    _careAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _careAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _currentCareEvent = null;
          });
        }
      }
    });

    ParkClientService.instance.addFuzzyListener(_handleIncomingFuzzy);
    ParkClientService.instance.addGiftListener(_handleIncomingGift);

    _serverUrlController.text = ParkClientService.instance.serverUrl;
    _roomCodeController.text = ParkClientService.instance.currentRoomId;

    _initParkAndConnect();
  }

  Future<void> _initParkAndConnect() async {
    await ParkClientService.instance.loadPreferences();
    if (!mounted) return;
    setState(() {
      _serverUrlController.text = ParkClientService.instance.serverUrl;
      _roomCodeController.text = ParkClientService.instance.currentRoomId;
    });
    ParkClientService.instance.connect(
      url: ParkClientService.instance.serverUrl,
      roomId: ParkClientService.instance.currentRoomId,
      companion: widget.controller.companion,
    );
  }

  @override
  void dispose() {
    ParkClientService.instance.removeFuzzyListener(_handleIncomingFuzzy);
    ParkClientService.instance.removeGiftListener(_handleIncomingGift);
    _treeAnimController.dispose();
    _careAnimController.dispose();
    _serverUrlController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  void _handleIncomingFuzzy(WarmFuzzyType fuzzy, String fromName, String? fromPeerId) {
    if (!mounted) return;
    Offset senderPos = const Offset(0.5, 0.28);
    if (fromPeerId != null && ParkClientService.instance.peers.containsKey(fromPeerId)) {
      final p = ParkClientService.instance.peers[fromPeerId]!;
      senderPos = Offset(p.x, p.y);
    }
    triggerCareAnimation(
      ParkCareEvent(
        senderName: fromName,
        senderPosition: senderPos,
        title: fuzzy.label,
        message: fuzzy.affirmation,
        icon: fuzzy.icon,
        color: fuzzy.color,
      ),
    );
  }

  void _handleIncomingGift(BurrowTreasure gift, String fromName, String? fromPeerId) {
    if (!mounted) return;
    Offset senderPos = const Offset(0.5, 0.28);
    if (fromPeerId != null && ParkClientService.instance.peers.containsKey(fromPeerId)) {
      final p = ParkClientService.instance.peers[fromPeerId]!;
      senderPos = Offset(p.x, p.y);
    }
    triggerCareAnimation(
      ParkCareEvent(
        senderName: fromName,
        senderPosition: senderPos,
        title: gift.name,
        message: 'Shared an unearthed treasure with you! 🎁',
        icon: gift.icon,
        color: gift.rarity.color,
      ),
    );
  }

  void triggerCareAnimation(ParkCareEvent event) {
    if (!mounted) return;
    setState(() {
      _currentCareEvent = event;
    });
    _careAnimController.forward(from: 0.0);
    SoundService.instance.playZenChime();
  }

  void _triggerSampleCare() {
    final client = ParkClientService.instance;
    String senderName = 'Mochi';
    Offset senderPos = const Offset(0.32, 0.45);
    if (client.peers.isNotEmpty) {
      final peer = client.peers.values.first;
      senderName = peer.petName;
      senderPos = Offset(peer.x, peer.y);
    }
    final fuzzies = WarmFuzzyType.values;
    final f = fuzzies[math.Random().nextInt(fuzzies.length)];
    triggerCareAnimation(
      ParkCareEvent(
        senderName: senderName,
        senderPosition: senderPos,
        title: f.label,
        message: f.affirmation,
        icon: f.icon,
        color: f.color,
      ),
    );
  }

  void _onMeadowTap(TapDownDetails details, Size meadowSize) {
    if (_selectedPeer != null) {
      // Dismiss the action overlay if open, without moving the companion
      setState(() => _selectedPeer = null);
      return;
    }

    final rx = (details.localPosition.dx / meadowSize.width).clamp(0.1, 0.9);
    final ry = (details.localPosition.dy / meadowSize.height).clamp(0.15, 0.85);
    setState(() {
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
                  hintText: 'wss://park.andfriendslabs.com/ws',
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
                final roomText = _roomCodeController.text.trim();
                final finalRoom = roomText.isNotEmpty ? roomText : 'cozy-meadow';
                final urlText = _serverUrlController.text.trim();
                final finalUrl = urlText.isNotEmpty ? urlText : ParkClientService.instance.serverUrl;

                ParkClientService.instance.connect(
                  url: finalUrl,
                  roomId: finalRoom,
                  companion: widget.controller.companion,
                  forceReconnect: true,
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
                    animation: Listenable.merge([client, _treeAnimController, _careAnimController]),
                    builder: (context, _) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final size = Size(constraints.maxWidth, constraints.maxHeight);

                          final isReceivingCare = _currentCareEvent != null &&
                              _careAnimController.value >= 0.30 &&
                              _careAnimController.value <= 0.85;

                          double bounceY = 0.0;
                          if (isReceivingCare) {
                            final t = (_careAnimController.value - 0.30) / 0.55;
                            bounceY = -math.sin(t * math.pi * 5).abs() * 9.0;
                          }

                          return Stack(
                            children: [
                              // Pastoral Meadow Background Painter with tap handling
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) => _onMeadowTap(details, size),
                                  child: CustomPaint(
                                    painter: _MeadowPainter(
                                      treeSway: _treeAnimController.value,
                                    ),
                                  ),
                                ),
                              ),

                              // Care Animation Visual Projectile & Aura
                              if (_currentCareEvent != null)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CareAnimationPainter(
                                        progress: _careAnimController.value,
                                        senderPos: Offset(
                                          _currentCareEvent!.senderPosition.dx * size.width,
                                          _currentCareEvent!.senderPosition.dy * size.height,
                                        ),
                                        receiverPos: Offset(
                                          _myPosition.dx * size.width,
                                          _myPosition.dy * size.height,
                                        ),
                                        color: _currentCareEvent!.color,
                                        icon: _currentCareEvent!.icon,
                                      ),
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
                                top: _myPosition.dy * size.height - 40 + bounceY,
                                child: _buildCompanionAvatar(
                                  name: '${myComp.name} (You)',
                                  primaryColor: myComp.primaryColor,
                                  accentColor: myComp.accentColor,
                                  isMe: true,
                                  isReceivingCare: isReceivingCare,
                                  careColor: _currentCareEvent?.color,
                                ),
                              ),

                              // Floating Care Card over recipient
                              if (_currentCareEvent != null)
                                _buildFloatingCareCard(size),

                              // Selected Peer Action Sheet Overlay
                              if (_selectedPeer != null)
                                Positioned(
                                  bottom: 12,
                                  left: 20,
                                  right: 20,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {}, // Prevent taps inside overlay from bubbling to meadow
                                    child: _buildPeerActionSheet(_selectedPeer!),
                                  ),
                                ),
                            ],
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
                  const Expanded(
                    child: Text(
                      '🌸 Click grass to stroll. Click friends to send care.',
                      style: TextStyle(color: Colors.white54, fontSize: 10.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _triggerSampleCare,
                        icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.amberAccent),
                        label: const Text('Receive Care ✨', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCareCard(Size size) {
    final event = _currentCareEvent;
    if (event == null) return const SizedBox.shrink();

    final progress = _careAnimController.value;
    double opacity = 0.0;
    if (progress >= 0.25 && progress < 0.35) {
      opacity = ((progress - 0.25) / 0.10).clamp(0.0, 1.0);
    } else if (progress >= 0.35 && progress <= 0.82) {
      opacity = 1.0;
    } else if (progress > 0.82 && progress <= 1.0) {
      opacity = (1.0 - (progress - 0.82) / 0.18).clamp(0.0, 1.0);
    }

    if (opacity <= 0.01) return const SizedBox.shrink();

    final cx = (_myPosition.dx * size.width).clamp(110.0, size.width - 110.0);
    final cy = (_myPosition.dy * size.height - 75.0).clamp(15.0, size.height - 80.0);

    return Positioned(
      left: cx - 110,
      top: cy,
      width: 220,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: 0.9 + 0.1 * opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: event.color.withValues(alpha: 0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: event.color.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: event.color.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(event.icon, size: 16, color: event.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event.senderName} sent ${event.title}! ✨',
                          style: TextStyle(
                            color: event.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          event.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    bool isReceivingCare = false,
    Color? careColor,
    String? thought,
  }) {
    final effectiveBorderColor = isReceivingCare
        ? (careColor ?? Colors.amberAccent)
        : (isSelected
            ? Colors.amberAccent
            : (isMe ? Colors.white : accentColor));

    final effectiveScale = isReceivingCare ? 1.12 : 1.0;

    return AnimatedScale(
      scale: effectiveScale,
      duration: const Duration(milliseconds: 160),
      child: Column(
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
                color: effectiveBorderColor,
                width: isReceivingCare ? 3.5 : (isSelected ? 3.0 : 2.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: isReceivingCare
                      ? (careColor ?? Colors.amberAccent).withValues(alpha: 0.85)
                      : primaryColor.withValues(alpha: 0.5),
                  blurRadius: isReceivingCare ? 18 : 10,
                  spreadRadius: isReceivingCare ? 4 : 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isReceivingCare
                    ? Icons.favorite_rounded
                    : (isNpc ? Icons.pets : Icons.favorite),
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
                color: isReceivingCare
                    ? (careColor ?? Colors.amberAccent)
                    : (isMe ? Colors.lightGreenAccent : Colors.white),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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

/// Custom painter for in-park care animations (traveling orb/projectile, aura rings, floating hearts & stars)
class _CareAnimationPainter extends CustomPainter {
  final double progress;
  final Offset senderPos;
  final Offset receiverPos;
  final Color color;
  final IconData icon;

  const _CareAnimationPainter({
    required this.progress,
    required this.senderPos,
    required this.receiverPos,
    required this.color,
    required this.icon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Traveling projectile with trailing particle dust (0.0 .. 0.40)
    if (progress <= 0.42) {
      final t = (progress / 0.38).clamp(0.0, 1.0);
      final p0 = senderPos;
      final p2 = receiverPos;
      final p1 = Offset((p0.dx + p2.dx) / 2, math.min(p0.dy, p2.dy) - 60.0);

      Offset getBezier(double u) {
        final inv = 1.0 - u;
        return Offset(
          inv * inv * p0.dx + 2 * inv * u * p1.dx + u * u * p2.dx,
          inv * inv * p0.dy + 2 * inv * u * p1.dy + u * u * p2.dy,
        );
      }

      final cur = getBezier(t);

      // Trailing dust particles
      for (int i = 1; i <= 6; i++) {
        final trailT = (t - i * 0.045).clamp(0.0, 1.0);
        if (trailT > 0.0) {
          final trailPos = getBezier(trailT);
          final trailAlpha = ((1.0 - i / 7.0) * (1.0 - (1.0 - t) * 0.2)).clamp(0.0, 1.0);
          final trailPaint = Paint()
            ..color = color.withValues(alpha: trailAlpha * 0.7)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(trailPos, (7.0 - i).clamp(1.5, 6.0), trailPaint);
        }
      }

      // Radiant glowing orb
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(cur, 16.0, glowPaint);

      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(cur, 7.0, corePaint);

      final haloPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(cur, 9.5, haloPaint);

      // Star sparkle on head
      _drawStar(canvas, cur, 8.0, Colors.white);
    }

    // 2. Radiant Aura Shockwaves around recipient (0.28 .. 0.88)
    if (progress >= 0.28 && progress <= 0.88) {
      final auraT1 = ((progress - 0.28) / 0.55).clamp(0.0, 1.0);
      final r1 = 16.0 + auraT1 * 60.0;
      final alpha1 = (1.0 - auraT1).clamp(0.0, 1.0);

      final auraPaint1 = Paint()
        ..color = color.withValues(alpha: alpha1 * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1.0 - auraT1 * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(receiverPos, r1, auraPaint1);

      if (progress >= 0.38) {
        final auraT2 = ((progress - 0.38) / 0.48).clamp(0.0, 1.0);
        final r2 = 12.0 + auraT2 * 48.0;
        final alpha2 = (1.0 - auraT2).clamp(0.0, 1.0);
        final auraPaint2 = Paint()
          ..color = Colors.amberAccent.withValues(alpha: alpha2 * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(receiverPos, r2, auraPaint2);
      }
    }

    // 3. Ascending Floating Hearts & Sparkles (0.32 .. 1.0)
    if (progress >= 0.32) {
      final burstT = ((progress - 0.32) / 0.68).clamp(0.0, 1.0);
      final pAlpha = (1.0 - burstT).clamp(0.0, 1.0);

      for (int i = 0; i < 12; i++) {
        final angle = (i / 12.0) * 2 * math.pi;
        final speed = 30.0 + (i * 11) % 35;
        final floatY = burstT * 65.0 + ((i * 7) % 25) * burstT;
        final wobbleX = math.sin(burstT * 5.0 + i) * 8.0;

        final px = receiverPos.dx + math.cos(angle) * speed * (burstT * 0.8) + wobbleX;
        final py = receiverPos.dy + math.sin(angle) * (speed * 0.4) * (burstT * 0.8) - floatY;

        final pSize = 4.0 + (i % 3) * 2.0;
        final pColor = (i % 3 == 0)
            ? Colors.amberAccent.withValues(alpha: pAlpha * 0.9)
            : color.withValues(alpha: pAlpha * 0.85);

        if (i % 2 == 0) {
          _drawHeart(canvas, Offset(px, py), pSize, pColor);
        } else {
          _drawStar(canvas, Offset(px, py), pSize, pColor);
        }
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color c) {
    final paint = Paint()
      ..color = c
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.35);
    path.cubicTo(
      center.dx - size, center.dy - size * 0.4,
      center.dx - size * 0.6, center.dy - size,
      center.dx, center.dy - size * 0.35,
    );
    path.cubicTo(
      center.dx + size * 0.6, center.dy - size,
      center.dx + size, center.dy - size * 0.4,
      center.dx, center.dy + size * 0.35,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color c) {
    final paint = Paint()
      ..color = c
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.28, center.dy - size * 0.28);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.28, center.dy + size * 0.28);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.28, center.dy + size * 0.28);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.28, center.dy - size * 0.28);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CareAnimationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.senderPos != senderPos ||
        oldDelegate.receiverPos != receiverPos ||
        oldDelegate.color != color;
  }
}
