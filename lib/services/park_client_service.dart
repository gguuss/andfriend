import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/companion_model.dart';
import '../models/exergaming_state.dart';
import '../models/park_state.dart';

class ParkClientService extends ChangeNotifier {
  static final ParkClientService instance = ParkClientService._internal();

  ParkClientService._internal();

  bool isConnected = false;
  bool isConnecting = false;
  bool isOfflineMode = false;
  String currentRoomId = 'cozy-meadow';
  String serverUrl = 'wss://park.andfriendslabs.com/ws';
  String myPeerId = 'peer_${DateTime.now().millisecondsSinceEpoch}';

  final Map<String, ParkCompanion> peers = {};
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _npcLoopTimer;

  // Event callbacks for controller integration
  void Function(WarmFuzzyType fuzzy, String fromName)? onWarmFuzzyReceived;
  void Function(BurrowTreasure gift, String fromName)? onGiftReceived;

  Future<void> connect({
    String? url,
    String? roomId,
    required CompanionModel companion,
  }) async {
    disconnect();
    isConnecting = true;
    isOfflineMode = false;
    currentRoomId = (roomId ?? currentRoomId).trim().toLowerCase();

    String targetUrl = (url ?? serverUrl).trim();
    if (!targetUrl.startsWith('ws://') && !targetUrl.startsWith('wss://')) {
      if (targetUrl.startsWith('https://')) {
        targetUrl = 'wss://${targetUrl.substring(8)}';
      } else if (targetUrl.startsWith('http://')) {
        targetUrl = 'ws://${targetUrl.substring(7)}';
      } else {
        targetUrl = 'wss://$targetUrl';
      }
    }
    if (!targetUrl.endsWith('/ws')) {
      targetUrl = targetUrl.endsWith('/') ? '${targetUrl}ws' : '$targetUrl/ws';
    }
    serverUrl = targetUrl;
    notifyListeners();

    try {
      final uri = Uri.parse(serverUrl);
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready.timeout(const Duration(seconds: 4));

      isConnected = true;
      isConnecting = false;

      // Send join message
      final joinMsg = ParkMessage.join(
        roomId: currentRoomId,
        peerId: myPeerId,
        petName: companion.name,
        archetype: companion.archetype.name,
        primaryColor: companion.primaryColor.toARGB32(),
        accentColor: companion.accentColor.toARGB32(),
      );
      _channel!.sink.add(joinMsg);

      _subscription = _channel!.stream.listen(
        _handleServerMessage,
        onDone: () => _handleDisconnect(companion),
        onError: (err) => _handleDisconnect(companion),
      );

      notifyListeners();
    } catch (_) {
      // Server unreachable: seamlessly fall back to local Cozy Park offline simulation
      isConnecting = false;
      isConnected = false;
      enableOfflineMode(companion);
    }
  }

  void _handleServerMessage(dynamic raw) {
    try {
      final text = raw is String ? raw : utf8.decode(raw as List<int>);
      final msg = jsonDecode(text) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'room_state':
          peers.clear();
          if (msg['peers'] is List) {
            for (final p in msg['peers'] as List) {
              if (p is Map<String, dynamic>) {
                final companion = ParkCompanion.fromPeerMap(p);
                if (companion.peerId != myPeerId) {
                  peers[companion.peerId] = companion;
                }
              }
            }
          }
          notifyListeners();
          break;

        case 'peer_joined':
          if (msg['peer'] is Map<String, dynamic>) {
            final companion = ParkCompanion.fromPeerMap(msg['peer'] as Map<String, dynamic>);
            if (companion.peerId != myPeerId) {
              peers[companion.peerId] = companion;
              notifyListeners();
            }
          }
          break;

        case 'peer_moved':
          final id = msg['peerId'] as String?;
          if (id != null && peers.containsKey(id)) {
            final p = peers[id]!;
            p.targetX = (msg['x'] as num?)?.toDouble() ?? p.x;
            p.targetY = (msg['y'] as num?)?.toDouble() ?? p.y;
            p.x = p.targetX;
            p.y = p.targetY;
            notifyListeners();
          }
          break;

        case 'peer_left':
          final id = msg['peerId'] as String?;
          if (id != null) {
            peers.remove(id);
            notifyListeners();
          }
          break;

        case 'warm_fuzzy_received':
          final target = msg['targetPeerId'] as String?;
          // If targeted at us or broadcasted to room
          if (target == null || target == myPeerId) {
            final fromName = msg['fromName'] as String? ?? 'A Park Friend';
            final fuzzyTypeName = msg['fuzzyType'] as String? ?? 'sunbeam';
            final fuzzyType = WarmFuzzyType.values.firstWhere(
              (f) => f.name == fuzzyTypeName,
              orElse: () => WarmFuzzyType.sunbeam,
            );

            // Trigger speech bubble over sender if in room
            final fromId = msg['fromPeerId'] as String?;
            if (fromId != null && peers.containsKey(fromId)) {
              peers[fromId]!.setThought('Sent a ${fuzzyType.label}! ✨');
            }

            onWarmFuzzyReceived?.call(fuzzyType, fromName);
            notifyListeners();
          }
          break;

        case 'gift_received':
          final target = msg['targetPeerId'] as String?;
          if (target == null || target == myPeerId) {
            final fromName = msg['fromName'] as String? ?? 'A Park Friend';
            if (msg['gift'] is Map<String, dynamic>) {
              final gift = BurrowTreasure.fromJson(msg['gift'] as Map<String, dynamic>);
              onGiftReceived?.call(gift, fromName);
            }
            notifyListeners();
          }
          break;
      }
    } catch (_) {}
  }

  void _handleDisconnect(CompanionModel companion) {
    if (isConnected) {
      isConnected = false;
      notifyListeners();
      // Seamlessly preserve park ambiance with offline visitors
      enableOfflineMode(companion);
    }
  }

  void move(double x, double y) {
    if (isConnected && _channel != null) {
      _channel!.sink.add(ParkMessage.move(x: x, y: y));
    }
  }

  void sendWarmFuzzy(String targetPeerId, WarmFuzzyType fuzzy) {
    if (isConnected && _channel != null) {
      _channel!.sink.add(ParkMessage.warmFuzzy(
        targetPeerId: targetPeerId,
        fuzzyType: fuzzy,
        affirmation: fuzzy.affirmation,
      ));
    } else if (isOfflineMode) {
      // NPC reaction in offline mode
      if (peers.containsKey(targetPeerId)) {
        final npc = peers[targetPeerId]!;
        npc.setThought('Thank you! ${fuzzy.label} received 🌸');
        notifyListeners();
      }
    }
  }

  void sendGift(String targetPeerId, BurrowTreasure treasure) {
    if (isConnected && _channel != null) {
      _channel!.sink.add(ParkMessage.gift(
        targetPeerId: targetPeerId,
        treasure: treasure,
      ));
    } else if (isOfflineMode) {
      if (peers.containsKey(targetPeerId)) {
        final npc = peers[targetPeerId]!;
        npc.setThought('Oh! A ${treasure.name}! Thank you! 🎁');
        notifyListeners();
      }
    }
  }

  /// Populates the park with gentle, autonomous NPC companions so it's never lonely
  void enableOfflineMode(CompanionModel userCompanion) {
    isOfflineMode = true;
    isConnected = false;
    peers.clear();

    final mochi = ParkCompanion(
      peerId: 'npc_mochi',
      petName: 'Mochi',
      archetype: CompanionArchetype.bunny,
      primaryColor: const Color(0xFFFFB6C1),
      accentColor: const Color(0xFFFF69B4),
      x: 0.32,
      y: 0.45,
      isNpc: true,
      activeThought: 'Enjoying the fresh air! 🌿',
    );

    final matcha = ParkCompanion(
      peerId: 'npc_matcha',
      petName: 'Matcha',
      archetype: CompanionArchetype.dragon,
      primaryColor: const Color(0xFF81C784),
      accentColor: const Color(0xFF388E3C),
      x: 0.68,
      y: 0.58,
      isNpc: true,
      activeThought: 'Sunlight is so cozy today... 🍵',
    );

    peers[mochi.peerId] = mochi;
    peers[matcha.peerId] = matcha;

    _startNpcLoop();
    notifyListeners();
  }

  void _startNpcLoop() {
    _npcLoopTimer?.cancel();
    final rng = math.Random();

    _npcLoopTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!isOfflineMode) return;

      for (final npc in peers.values) {
        if (npc.isNpc) {
          // Wander gently within bounds
          final dx = (rng.nextDouble() - 0.5) * 0.16;
          final dy = (rng.nextDouble() - 0.5) * 0.16;
          npc.x = (npc.x + dx).clamp(0.15, 0.85);
          npc.y = (npc.y + dy).clamp(0.20, 0.80);

          if (rng.nextInt(5) == 0) {
            final thoughts = [
              'Such a peaceful day in The Park! 🌸',
              'Stretching our legs feels so nice.',
              'Remember to drink some water! 💧',
              'Glad we are companions together.',
            ];
            npc.setThought(thoughts[rng.nextInt(thoughts.length)]);
          }
        }
      }
      notifyListeners();
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _npcLoopTimer?.cancel();
    _npcLoopTimer = null;
    isConnected = false;
    isConnecting = false;
    isOfflineMode = false;
    peers.clear();
    notifyListeners();
  }
}
