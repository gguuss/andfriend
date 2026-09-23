import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ClientSession {
  final WebSocketChannel channel;
  String? roomId;
  String? peerId;
  String? petName;
  String? archetype;
  int? primaryColor;
  int? accentColor;
  double x = 0.5;
  double y = 0.5;

  ClientSession(this.channel);

  Map<String, dynamic> toPeerMap() => {
    'peerId': peerId,
    'petName': petName,
    'archetype': archetype,
    'primaryColor': primaryColor,
    'accentColor': accentColor,
    'x': x,
    'y': y,
  };
}

class ParkRelayServer {
  final Map<String, Set<ClientSession>> _rooms = {};
  final Map<WebSocketChannel, ClientSession> _clients = {};

  Handler get handler {
    final router = Router();

    // Health check endpoint for Linux systemd / Docker / reverse proxy
    router.get('/healthz', (Request request) {
      final totalClients = _clients.length;
      final activeRooms = _rooms.length;
      final body = jsonEncode({
        'status': 'healthy',
        'service': 'andfriend-park-server',
        'activeRooms': activeRooms,
        'connectedClients': totalClients,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return Response.ok(body, headers: {'content-type': 'application/json'});
    });

    // WebSocket upgrade handler
    final wsHandler = webSocketHandler((WebSocketChannel channel, String? protocol) {
      final session = ClientSession(channel);
      _clients[channel] = session;

      channel.stream.listen(
        (data) {
          _handleMessage(session, data);
        },
        onDone: () {
          _handleDisconnect(session);
        },
        onError: (err) {
          _handleDisconnect(session);
        },
      );
    });

    router.get('/ws', wsHandler);

    return const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }

  void _handleMessage(ClientSession session, dynamic rawData) {
    try {
      final text = rawData is String ? rawData : utf8.decode(rawData as List<int>);
      final msg = jsonDecode(text) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'join':
          final roomId = (msg['roomId'] as String? ?? 'cozy-meadow').trim().toLowerCase();
          final peerId = msg['peerId'] as String? ?? 'peer_${DateTime.now().millisecondsSinceEpoch}';

          // Leave previous room if any
          _leaveCurrentRoom(session);

          session.roomId = roomId;
          session.peerId = peerId;
          session.petName = msg['petName'] as String? ?? 'Friend';
          session.archetype = msg['archetype'] as String? ?? 'fox';
          session.primaryColor = msg['primaryColor'] as int? ?? 0xFFE67E22;
          session.accentColor = msg['accentColor'] as int? ?? 0xFFD35400;
          session.x = (msg['x'] as num?)?.toDouble() ?? 0.5;
          session.y = (msg['y'] as num?)?.toDouble() ?? 0.5;

          final room = _rooms.putIfAbsent(roomId, () => <ClientSession>{});

          // Send current peers in room to newly joined client
          final existingPeers = room.map((c) => c.toPeerMap()).toList();
          session.channel.sink.add(jsonEncode({
            'type': 'room_state',
            'roomId': roomId,
            'peers': existingPeers,
          }));

          // Add client to room and notify other peers
          room.add(session);
          _broadcastToRoom(
            roomId,
            jsonEncode({
              'type': 'peer_joined',
              'peer': session.toPeerMap(),
            }),
            exclude: session,
          );
          break;

        case 'move':
          session.x = (msg['x'] as num?)?.toDouble() ?? session.x;
          session.y = (msg['y'] as num?)?.toDouble() ?? session.y;

          if (session.roomId != null) {
            _broadcastToRoom(
              session.roomId!,
              jsonEncode({
                'type': 'peer_moved',
                'peerId': session.peerId,
                'x': session.x,
                'y': session.y,
              }),
              exclude: session,
            );
          }
          break;

        case 'warm_fuzzy':
          // Relay positive affirmation to room or specific target
          if (session.roomId != null) {
            _broadcastToRoom(
              session.roomId!,
              jsonEncode({
                'type': 'warm_fuzzy_received',
                'fromPeerId': session.peerId,
                'fromName': session.petName,
                'targetPeerId': msg['targetPeerId'],
                'fuzzyType': msg['fuzzyType'] ?? 'sunbeam',
                'affirmation': msg['affirmation'] ?? 'You are doing great!',
              }),
            );
          }
          break;

        case 'gift':
          // Relay gift package (burrow treasure or treat)
          if (session.roomId != null) {
            _broadcastToRoom(
              session.roomId!,
              jsonEncode({
                'type': 'gift_received',
                'fromPeerId': session.peerId,
                'fromName': session.petName,
                'targetPeerId': msg['targetPeerId'],
                'gift': msg['gift'],
              }),
            );
          }
          break;

        case 'leave':
          _leaveCurrentRoom(session);
          break;
      }
    } catch (e) {
      // Ignore malformed payloads safely
    }
  }

  void _leaveCurrentRoom(ClientSession session) {
    final roomId = session.roomId;
    if (roomId != null && _rooms.containsKey(roomId)) {
      final room = _rooms[roomId]!;
      room.remove(session);

      _broadcastToRoom(
        roomId,
        jsonEncode({
          'type': 'peer_left',
          'peerId': session.peerId,
        }),
      );

      if (room.isEmpty) {
        _rooms.remove(roomId);
      }
    }
    session.roomId = null;
  }

  void _handleDisconnect(ClientSession session) {
    _leaveCurrentRoom(session);
    _clients.remove(session.channel);
  }

  void _broadcastToRoom(String roomId, String message, {ClientSession? exclude}) {
    final room = _rooms[roomId];
    if (room == null) return;

    for (final client in room) {
      if (client != exclude) {
        try {
          client.channel.sink.add(message);
        } catch (_) {}
      }
    }
  }
}

Future<void> main(List<String> args) async {
  final portEnv = Platform.environment['PORT'];
  final port = portEnv != null ? int.tryParse(portEnv) ?? 8080 : 8080;
  final ip = InternetAddress.anyIPv4;

  final serverInstance = ParkRelayServer();
  final server = await shelf_io.serve(serverInstance.handler, ip, port);

  stdout.writeln('===========================================================');
  stdout.writeln('🌳 And Friend - The Park Relay Server running on port ${server.port}');
  stdout.writeln('📡 WebSocket endpoint: ws://0.0.0.0:${server.port}/ws');
  stdout.writeln('🩺 Health check:      http://0.0.0.0:${server.port}/healthz');
  stdout.writeln('🔒 Zero telemetry, ephemeral memory-only room routing.');
  stdout.writeln('===========================================================');

  // Handle graceful shutdown on Linux systemd SIGTERM/SIGINT
  ProcessSignal.sigint.watch().listen((_) async {
    stdout.writeln('Shutting down park relay server...');
    await server.close(force: true);
    exit(0);
  });

  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) async {
      stdout.writeln('Received SIGTERM. Closing park server...');
      await server.close(force: true);
      exit(0);
    });
  }
}
