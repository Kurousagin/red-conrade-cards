// ══════════════════════════════════════════════════════════════
//  MpProvider — Estado global do multiplayer (ChangeNotifier)
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'mp_server.dart';
import 'mp_client.dart';

enum MpRole { none, host, client }
enum MpGamePhase { lobby, playing, result }

class PlayerInfo {
  final String id;
  final String name;
  int score;
  PlayerInfo({required this.id, required this.name, this.score = 0});
}

class MpProvider extends ChangeNotifier {
  final MpServer _server = MpServer();
  final MpClientConn _conn = MpClientConn();

  MpRole _role = MpRole.none;
  MpGamePhase _phase = MpGamePhase.lobby;
  String _localIp = '...';
  String _myName = 'Camarada';
  String _currentGame = '';
  List<PlayerInfo> _players = [];
  Map<String, dynamic> _gameState = {};
  Map<String, dynamic>? _lastResult;
  String? _errorMsg;

  // ── Getters ───────────────────────────────────────────────
  MpRole get role => _role;
  MpGamePhase get phase => _phase;
  String get localIp => _localIp;
  String get myName => _myName;
  String get myId => _conn.myId ?? 'host';
  bool get isHost => _role == MpRole.host;
  bool get isConnected => _role != MpRole.none;
  String get currentGame => _currentGame;
  List<PlayerInfo> get players => List.unmodifiable(_players);
  Map<String, dynamic> get gameState => Map.unmodifiable(_gameState);
  Map<String, dynamic>? get lastResult => _lastResult;
  String? get errorMsg => _errorMsg;
  MpServer get server => _server;
  MpClientConn get conn => _conn;
  int get playerCount => isHost ? (_players.length + 1) : _players.length;

  // ── Host ──────────────────────────────────────────────────
  Future<bool> startHost(String name) async {
    _myName = name;
    _errorMsg = null;
    try {
      await _server.start();
      _localIp = await _getLocalIp();
      _role = MpRole.host;
      _phase = MpGamePhase.lobby;
      _players = [];

      _server.onClientsChanged = () {
        _players = _server.clients
            .map((c) => PlayerInfo(id: c.id, name: c.name))
            .toList();
        notifyListeners();
      };

      _server.onMessage = _handleHostMessage;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMsg = 'Erro ao iniciar servidor: $e';
      notifyListeners();
      return false;
    }
  }

  void _handleHostMessage(String playerId, Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    switch (type) {
      case 'tap_score':
        final score = (msg['score'] as num?)?.toInt() ?? 0;
        _updatePlayerScore(playerId, score);
        // Rebroadcast to all
        _server.broadcastAll({
          'type': 'score_update',
          'playerId': playerId,
          'score': score,
        });
        notifyListeners();
        break;
      case 'memory_match':
        // Rebroadcast memory matches
        _server.broadcastAll({...msg, 'playerId': playerId});
        notifyListeners();
        break;
      case 'trade_request':
      case 'trade_accept':
      case 'trade_decline':
        // Rotear para o destinatário
        final to = msg['to'] as String?;
        if (to != null) {
          _server.sendTo(to, {...msg, 'from': playerId});
        }
        break;
    }
  }

  // ── Client ────────────────────────────────────────────────
  Future<bool> joinGame(String ip, String name) async {
    _myName = name;
    _errorMsg = null;
    _conn.onMessage = _handleClientMessage;
    _conn.onDisconnected = () {
      _role = MpRole.none;
      _phase = MpGamePhase.lobby;
      _errorMsg = 'Desconectado do host';
      notifyListeners();
    };

    final ok = await _conn.connect(ip, name);
    if (ok) {
      _role = MpRole.client;
      _phase = MpGamePhase.lobby;
      notifyListeners();
    } else {
      _errorMsg = 'Não foi possível conectar em $ip';
    }
    return ok;
  }

  void _handleClientMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    switch (type) {
      case 'player_list':
        final list = (msg['players'] as List?) ?? [];
        _players = list
            .map((p) => PlayerInfo(
                  id: p['id'] as String,
                  name: p['name'] as String,
                ))
            .toList();
        break;
      case 'game_start':
        _currentGame = msg['game'] as String? ?? '';
        _gameState = (msg['state'] as Map?)?.cast<String, dynamic>() ?? {};
        _phase = MpGamePhase.playing;
        _lastResult = null;
        // Reset scores
        for (final p in _players) p.score = 0;
        break;
      case 'game_state':
        _gameState = (msg['state'] as Map?)?.cast<String, dynamic>() ?? {};
        break;
      case 'game_end':
        _lastResult = (msg['result'] as Map?)?.cast<String, dynamic>();
        _phase = MpGamePhase.result;
        break;
      case 'score_update':
        final pid = msg['playerId'] as String?;
        final score = (msg['score'] as num?)?.toInt() ?? 0;
        _updatePlayerScore(pid ?? '', score);
        break;
      case 'memory_match':
        _gameState = {..._gameState, 'last_match': msg};
        break;
      case 'trade_request':
      case 'trade_accept':
      case 'trade_decline':
        _gameState = {..._gameState, 'trade_msg': msg};
        break;
    }
    notifyListeners();
  }

  // ── Game Control (HOST only) ───────────────────────────────
  void hostStartGame(String game) {
    if (!isHost) return;
    _currentGame = game;
    _phase = MpGamePhase.playing;
    _lastResult = null;
    // Reset scores
    for (final p in _players) p.score = 0;

    Map<String, dynamic> initialState = {};
    if (game == 'tap') {
      initialState = {
        'duration': 15,
        'started_at': DateTime.now().millisecondsSinceEpoch,
      };
    } else if (game == 'memory') {
      initialState = {
        'cards': _generateMemoryCards(),
        'started_at': DateTime.now().millisecondsSinceEpoch,
      };
    }
    _gameState = initialState;
    _server.startGame(game, initialState);
    notifyListeners();
  }

  void hostEndGame() {
    if (!isHost) return;
    // Calcular ranking
    final allPlayers = [
      {'id': 'host', 'name': myName, 'score': _gameState['host_score'] ?? 0},
      ..._players.map((p) => {'id': p.id, 'name': p.name, 'score': p.score}),
    ];
    allPlayers.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final result = {
      'ranking': allPlayers,
      'winner': allPlayers.first['name'],
    };
    _lastResult = result;
    _phase = MpGamePhase.result;
    _server.endGame(result);
    notifyListeners();
  }

  void hostBackToLobby() {
    if (!isHost) return;
    _phase = MpGamePhase.lobby;
    _currentGame = '';
    _gameState = {};
    _lastResult = null;
    _server.broadcastAll({'type': 'back_to_lobby'});
    notifyListeners();
  }

  // ── Tap game actions ──────────────────────────────────────
  // HOST registra seu próprio tap
  void hostRegisterTap(int score) {
    _gameState = {..._gameState, 'host_score': score};
    _server.broadcastAll({'type': 'score_update', 'playerId': 'host', 'score': score});
    notifyListeners();
  }

  // CLIENT envia tap
  void clientSendTap(int score) {
    _conn.send({'type': 'tap_score', 'score': score});
    notifyListeners();
  }

  // ── Memory game actions ───────────────────────────────────
  void sendMemoryMatch(int cardA, int cardB, bool matched, int score) {
    final payload = {
      'type': 'memory_match',
      'cardA': cardA,
      'cardB': cardB,
      'matched': matched,
      'score': score,
    };
    if (isHost) {
      _gameState = {..._gameState, 'host_memory_score': score};
      _server.broadcastAll({...payload, 'playerId': 'host'});
    } else {
      _conn.send(payload);
    }
    notifyListeners();
  }

  // ── Trade system ──────────────────────────────────────────
  void sendTradeRequest(String toId, String cardId, String cardName, bool isRare) {
    final msg = {
      'type': 'trade_request',
      'to': toId,
      'cardId': cardId,
      'cardName': cardName,
      'isRare': isRare,
    };
    if (isHost) {
      _server.sendTo(toId, {...msg, 'from': 'host', 'fromName': myName});
    } else {
      _conn.send(msg);
    }
    notifyListeners();
  }

  void sendTradeResponse(String toId, String cardId, bool accept, {String? myCardId, String? myCardName, bool myCardRare = false}) {
    final msg = {
      'type': accept ? 'trade_accept' : 'trade_decline',
      'to': toId,
      'cardId': cardId,
      if (accept && myCardId != null) 'myCardId': myCardId,
      if (accept && myCardName != null) 'myCardName': myCardName,
      if (accept) 'myCardRare': myCardRare,
    };
    if (isHost) {
      _server.sendTo(toId, {...msg, 'from': 'host', 'fromName': myName});
    } else {
      _conn.send(msg);
    }
    notifyListeners();
  }

  // ── Disconnect ────────────────────────────────────────────
  Future<void> disconnect() async {
    if (_role == MpRole.host) {
      await _server.stop();
    } else {
      await _conn.disconnect();
    }
    _role = MpRole.none;
    _phase = MpGamePhase.lobby;
    _players = [];
    _currentGame = '';
    _gameState = {};
    _lastResult = null;
    _errorMsg = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────
  void _updatePlayerScore(String id, int score) {
    for (final p in _players) {
      if (p.id == id) {
        p.score = score;
        return;
      }
    }
  }

  Future<String> _getLocalIp() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      if (ip != null && ip.isNotEmpty) return ip;
    } catch (_) {}
    // Fallback
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return '???';
  }

  List<int> _generateMemoryCards() {
    // 8 pares = 16 cartas
    final pairs = List.generate(8, (i) => i)..addAll(List.generate(8, (i) => i));
    pairs.shuffle();
    return pairs;
  }
}
