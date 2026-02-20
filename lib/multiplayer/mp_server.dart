// ══════════════════════════════════════════════════════════════
//  MpServer — Servidor WebSocket local (roda no dispositivo HOST)
//  Usa shelf + shelf_web_socket na porta 8765
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef MpHandler = void Function(String playerId, Map<String, dynamic> msg);

class MpClient {
  final String id;
  final String name;
  final WebSocketChannel ws;
  MpClient({required this.id, required this.name, required this.ws});
}

class MpServer {
  static const port = 8765;

  HttpServer? _server;
  final Map<String, MpClient> _clients = {};
  String? _currentGame; // 'tap' | 'memory' | 'trade'
  final Map<String, dynamic> _gameState = {};
  MpHandler? onMessage;
  VoidCallback? onClientsChanged;

  List<MpClient> get clients => _clients.values.toList();
  int get clientCount => _clients.length;
  bool get running => _server != null;

  // ── Start / Stop ──────────────────────────────────────────
  Future<void> start() async {
    if (_server != null) return;

    final handler = webSocketHandler((WebSocketChannel ws, String? protocol) {
      String? clientId;

      ws.stream.listen(
        (raw) {
          try {
            final msg = json.decode(raw as String) as Map<String, dynamic>;
            final type = msg['type'] as String?;

            if (type == 'join') {
              clientId = 'p_${DateTime.now().millisecondsSinceEpoch}';
              final name = msg['name'] as String? ?? 'Camarada';
              _clients[clientId!] = MpClient(id: clientId!, name: name, ws: ws);
              _sendTo(clientId!, {'type': 'joined', 'id': clientId, 'name': name});
              _broadcast({'type': 'player_list', 'players': _playerList()});
              onClientsChanged?.call();

              // Se há jogo em andamento, manda estado atual
              if (_currentGame != null) {
                _sendTo(clientId!, {
                  'type': 'game_state',
                  'game': _currentGame,
                  'state': _gameState,
                });
              }
            } else if (clientId != null) {
              onMessage?.call(clientId!, msg);
            }
          } catch (e) {
            debugPrint('MpServer parse error: $e');
          }
        },
        onDone: () {
          if (clientId != null) {
            _clients.remove(clientId);
            _broadcast({'type': 'player_list', 'players': _playerList()});
            onClientsChanged?.call();
          }
        },
        onError: (_) {
          if (clientId != null) {
            _clients.remove(clientId);
            onClientsChanged?.call();
          }
        },
      );
    });

    final pipeline = const Pipeline().addMiddleware(logRequests()).addHandler(handler);
    _server = await io.serve(pipeline, InternetAddress.anyIPv4, port);
    debugPrint('MpServer listening on port $port');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _clients.clear();
    _currentGame = null;
    _gameState.clear();
  }

  // ── Messaging ─────────────────────────────────────────────
  void _sendTo(String id, Map<String, dynamic> msg) {
    final client = _clients[id];
    if (client != null) {
      try {
        client.ws.sink.add(json.encode(msg));
      } catch (_) {}
    }
  }

  void _broadcast(Map<String, dynamic> msg, {String? excludeId}) {
    final encoded = json.encode(msg);
    for (final c in _clients.values) {
      if (c.id != excludeId) {
        try {
          c.ws.sink.add(encoded);
        } catch (_) {}
      }
    }
  }

  void broadcastAll(Map<String, dynamic> msg) => _broadcast(msg);
  void sendTo(String id, Map<String, dynamic> msg) => _sendTo(id, msg);

  // ── Game Control ──────────────────────────────────────────
  void startGame(String game, Map<String, dynamic> initialState) {
    _currentGame = game;
    _gameState.clear();
    _gameState.addAll(initialState);
    _broadcast({'type': 'game_start', 'game': game, 'state': initialState});
  }

  void updateGameState(Map<String, dynamic> patch) {
    _gameState.addAll(patch);
    _broadcast({'type': 'game_state', 'game': _currentGame, 'state': _gameState});
  }

  void endGame(Map<String, dynamic> result) {
    _currentGame = null;
    _gameState.clear();
    _broadcast({'type': 'game_end', 'result': result});
  }

  // ── Helpers ───────────────────────────────────────────────
  List<Map<String, dynamic>> _playerList() {
    return _clients.values.map((c) => {'id': c.id, 'name': c.name}).toList();
  }
}
