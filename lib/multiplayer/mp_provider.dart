// ══════════════════════════════════════════════════════════════
//  MpProvider — Estado global do multiplayer via UDP LAN
//
//  FLUXO DE CONEXÃO:
//  HOST:
//    1. Abre socket UDP na porta 8765
//    2. Envia broadcast "room_announce" a cada 2s
//    3. Recebe "join_request" de clientes
//    4. Envia "join_ack" com lista de jogadores
//    5. Gerencia estado do jogo e faz relay de mensagens
//
//  CLIENT:
//    1. Abre socket UDP na porta 8765
//    2. Escuta broadcasts "room_announce"
//    3. Envia "join_request" ao IP do host
//    4. Recebe "join_ack" e entra na sala
//    5. Envia/recebe mensagens de jogo
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mp_udp_service.dart';

enum MpRole { none, host, client }

enum MpGamePhase { lobby, playing, result }

class PlayerInfo {
  final String id; // IP do dispositivo
  final String name;
  int score;
  PlayerInfo({required this.id, required this.name, this.score = 0});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'score': score};
  factory PlayerInfo.fromJson(Map<String, dynamic> j) => PlayerInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        score: (j['score'] as num?)?.toInt() ?? 0,
      );
}

class MpRoom {
  final String hostIp;
  final String hostName;
  final int playerCount;
  MpRoom({required this.hostIp, required this.hostName, required this.playerCount});
}

class MpProvider extends ChangeNotifier {
  final MpUdpService _udp = MpUdpService();

  MpRole _role = MpRole.none;
  MpGamePhase _phase = MpGamePhase.lobby;
  String _myName = 'Camarada';
  String _currentGame = '';
  List<PlayerInfo> _players = []; // clientes (do ponto de vista do host)
  Map<String, dynamic> _gameState = {};
  Map<String, dynamic>? _lastResult;
  String? _errorMsg;
  String? _hostIp; // IP do host (para clientes)
  String? _myIp;

  // Descoberta de salas (para clientes)
  final List<MpRoom> _availableRooms = [];
  Timer? _roomCleanupTimer;

  // ── Getters ───────────────────────────────────────────────
  MpRole get role => _role;
  MpGamePhase get phase => _phase;
  String get myName => _myName;
  String get myIp => _myIp ?? '???';
  String get hostIp => _hostIp ?? '';
  bool get isHost => _role == MpRole.host;
  bool get isConnected => _role != MpRole.none;
  String get currentGame => _currentGame;
  List<PlayerInfo> get players => List.unmodifiable(_players);
  Map<String, dynamic> get gameState => Map.unmodifiable(_gameState);
  Map<String, dynamic>? get lastResult => _lastResult;
  String? get errorMsg => _errorMsg;
  List<MpRoom> get availableRooms => List.unmodifiable(_availableRooms);

  // Contagem total: host + clientes
  int get playerCount => isHost ? (_players.length + 1) : (_players.length + 1);

  // ── HOST: criar sala ──────────────────────────────────────
  Future<bool> startHost(String name) async {
    _myName = name;
    _errorMsg = null;

    final ok = await _udp.start();
    if (!ok) {
      _errorMsg = 'Não foi possível abrir socket UDP.\nVerifique as permissões de rede.';
      notifyListeners();
      return false;
    }

    _myIp = _udp.myIp;
    _role = MpRole.host;
    _phase = MpGamePhase.lobby;
    _players = [];

    _udp.onMessage = _handleHostMessage;

    // Broadcast periódico anunciando a sala
    _startRoomAnnounce();
    notifyListeners();
    return true;
  }

  void _startRoomAnnounce() {
    _udp.startPeriodicBroadcast({
      'type': 'room_announce',
      'hostName': _myName,
      'hostIp': _myIp,
      'playerCount': _players.length + 1,
    });
  }

  void _handleHostMessage(String fromIp, Map<String, dynamic> msg) {
    final type = msg['type'] as String? ?? '';

    switch (type) {
      case 'join_request':
        final playerName = msg['name'] as String? ?? 'Camarada';
        // Adicionar jogador se não existir
        if (!_players.any((p) => p.id == fromIp)) {
          _players.add(PlayerInfo(id: fromIp, name: playerName));
        }
        // Enviar confirmação com lista de jogadores
        _udp.sendTo(fromIp, {
          'type': 'join_ack',
          'hostName': _myName,
          'players': _players.map((p) => p.toJson()).toList(),
        });
        // Notificar todos os outros sobre novo jogador
        _broadcastToClients({
          'type': 'player_list',
          'players': _players.map((p) => p.toJson()).toList(),
        });
        // Atualizar broadcast com nova contagem
        _startRoomAnnounce();
        notifyListeners();
        break;

      case 'tap_score':
        final score = (msg['score'] as num?)?.toInt() ?? 0;
        _updatePlayerScore(fromIp, score);
        // Relay para todos
        _broadcastToClients({
          'type': 'score_update',
          'playerId': fromIp,
          'score': score,
        });
        notifyListeners();
        break;

      case 'memory_match':
        _broadcastToClients({...msg, 'playerId': fromIp});
        notifyListeners();
        break;

      case 'trade_request':
      case 'trade_accept':
      case 'trade_decline':
        // Roteamento: se destino é o host, processar localmente
        final to = msg['to'] as String?;
        if (to == 'host' || to == _myIp) {
          _gameState = {..._gameState, 'trade_msg': {...msg, 'from': fromIp}};
        } else if (to != null) {
          // Relay para o cliente destino
          _udp.sendTo(to, {...msg, 'from': fromIp, 'fromName': _getPlayerName(fromIp)});
        }
        notifyListeners();
        break;

      case 'leave':
        _players.removeWhere((p) => p.id == fromIp);
        _broadcastToClients({
          'type': 'player_list',
          'players': _players.map((p) => p.toJson()).toList(),
        });
        _startRoomAnnounce();
        notifyListeners();
        break;
    }
  }

  // ── CLIENT: procurar e entrar em sala ─────────────────────
  Future<bool> startScanning(String name) async {
    _myName = name;
    _errorMsg = null;
    _availableRooms.clear();

    final ok = await _udp.start();
    if (!ok) {
      _errorMsg = 'Não foi possível abrir socket UDP.';
      notifyListeners();
      return false;
    }

    _myIp = _udp.myIp;
    _role = MpRole.none; // scanning, ainda não entrou
    _udp.onMessage = _handleScanMessage;

    // Limpar salas antigas a cada 5s
    _roomCleanupTimer?.cancel();
    _roomCleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Salas são re-anunciadas a cada 2s; se sumiram, remover
      // (simplificado: manter apenas as mais recentes)
      notifyListeners();
    });

    notifyListeners();
    return true;
  }

  void _handleScanMessage(String fromIp, Map<String, dynamic> msg) {
    final type = msg['type'] as String? ?? '';
    if (type == 'room_announce') {
      final room = MpRoom(
        hostIp: fromIp,
        hostName: msg['hostName'] as String? ?? 'Host',
        playerCount: (msg['playerCount'] as num?)?.toInt() ?? 1,
      );
      // Atualizar ou adicionar sala
      final idx = _availableRooms.indexWhere((r) => r.hostIp == fromIp);
      if (idx >= 0) {
        _availableRooms[idx] = room;
      } else {
        _availableRooms.add(room);
      }
      notifyListeners();
    }
  }

  Future<bool> joinRoom(MpRoom room) async {
    _hostIp = room.hostIp;
    _errorMsg = null;
    _udp.onMessage = _handleClientMessage;

    // Enviar pedido de entrada
    _udp.sendTo(room.hostIp, {
      'type': 'join_request',
      'name': _myName,
    });

    // Aguardar join_ack por até 5s
    final completer = Completer<bool>();

    _udp.onMessage = (fromIp, msg) {
      if (fromIp == room.hostIp && msg['type'] == 'join_ack') {
        if (!completer.isCompleted) completer.complete(true);
        _handleClientMessage(fromIp, msg);
      } else {
        _handleClientMessage(fromIp, msg);
      }
    };

    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) completer.complete(false);
    });

    final joined = await completer.future;
    if (joined) {
      _role = MpRole.client;
      _phase = MpGamePhase.lobby;
      _roomCleanupTimer?.cancel();
      _udp.stopPeriodicBroadcast();
      notifyListeners();
    } else {
      _errorMsg = 'Não foi possível conectar a ${room.hostName}';
      notifyListeners();
    }
    return joined;
  }

  void _handleClientMessage(String fromIp, Map<String, dynamic> msg) {
    if (fromIp != _hostIp) return; // ignorar mensagens que não são do host
    final type = msg['type'] as String? ?? '';

    switch (type) {
      case 'join_ack':
        final list = (msg['players'] as List?) ?? [];
        _players = list.map((p) => PlayerInfo.fromJson(p as Map<String, dynamic>)).toList();
        break;

      case 'player_list':
        final list = (msg['players'] as List?) ?? [];
        _players = list.map((p) => PlayerInfo.fromJson(p as Map<String, dynamic>)).toList();
        break;

      case 'game_start':
        _currentGame = msg['game'] as String? ?? '';
        _gameState = (msg['state'] as Map?)?.cast<String, dynamic>() ?? {};
        _phase = MpGamePhase.playing;
        _lastResult = null;
        for (final p in _players) p.score = 0;
        break;

      case 'score_update':
        final pid = msg['playerId'] as String?;
        final score = (msg['score'] as num?)?.toInt() ?? 0;
        if (pid != null) _updatePlayerScore(pid, score);
        break;

      case 'game_state':
        _gameState = (msg['state'] as Map?)?.cast<String, dynamic>() ?? {};
        break;

      case 'game_end':
        _lastResult = (msg['result'] as Map?)?.cast<String, dynamic>();
        _phase = MpGamePhase.result;
        break;

      case 'back_to_lobby':
        _phase = MpGamePhase.lobby;
        _currentGame = '';
        _gameState = {};
        _lastResult = null;
        break;

      case 'trade_request':
      case 'trade_accept':
      case 'trade_decline':
        _gameState = {..._gameState, 'trade_msg': msg};
        break;
    }
    notifyListeners();
  }

  // ── Ações do HOST ─────────────────────────────────────────
  void hostStartGame(String game) {
    if (!isHost) return;
    _currentGame = game;
    _phase = MpGamePhase.playing;
    _lastResult = null;
    for (final p in _players) p.score = 0;
    _gameState['host_score'] = 0;
    _gameState['host_memory_score'] = 0;

    Map<String, dynamic> state = {};
    if (game == 'tap') {
      state = {
        'duration': 15,
        'started_at': DateTime.now().millisecondsSinceEpoch,
      };
    } else if (game == 'memory') {
      state = {
        'cards': _generateMemoryCards(),
        'started_at': DateTime.now().millisecondsSinceEpoch,
      };
    }
    _gameState = {..._gameState, ...state};

    _broadcastToClients({'type': 'game_start', 'game': game, 'state': state});
    notifyListeners();
  }

  void hostEndGame() {
    if (!isHost) return;
    final allPlayers = [
      {'id': _myIp ?? 'host', 'name': _myName, 'score': _gameState['host_score'] ?? _gameState['host_memory_score'] ?? 0},
      ..._players.map((p) => {'id': p.id, 'name': p.name, 'score': p.score}),
    ];
    (allPlayers as List).sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final result = {
      'ranking': allPlayers,
      'winner': allPlayers.first['name'],
    };
    _lastResult = result;
    _phase = MpGamePhase.result;
    _broadcastToClients({'type': 'game_end', 'result': result});
    notifyListeners();
  }

  void hostBackToLobby() {
    if (!isHost) return;
    _phase = MpGamePhase.lobby;
    _currentGame = '';
    _gameState = {};
    _lastResult = null;
    _broadcastToClients({'type': 'back_to_lobby'});
    notifyListeners();
  }

  // ── Tap game ──────────────────────────────────────────────
  void hostRegisterTap(int score) {
    _gameState = {..._gameState, 'host_score': score};
    _broadcastToClients({'type': 'score_update', 'playerId': _myIp ?? 'host', 'score': score});
    notifyListeners();
  }

  void clientSendTap(int score) {
    if (_hostIp == null) return;
    _udp.sendTo(_hostIp!, {'type': 'tap_score', 'score': score});
  }

  // ── Memory game ───────────────────────────────────────────
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
      _broadcastToClients({...payload, 'playerId': _myIp ?? 'host'});
    } else if (_hostIp != null) {
      _udp.sendTo(_hostIp!, payload);
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
      // Host envia direto para o cliente
      if (toId != 'host') {
        _udp.sendTo(toId, {...msg, 'from': _myIp ?? 'host', 'fromName': _myName});
      }
    } else if (_hostIp != null) {
      // Cliente envia para o host fazer relay
      _udp.sendTo(_hostIp!, msg);
    }
  }

  void sendTradeResponse(String toId, String cardId, bool accept,
      {String? myCardId, String? myCardName, bool myCardRare = false}) {
    final msg = {
      'type': accept ? 'trade_accept' : 'trade_decline',
      'to': toId,
      'cardId': cardId,
      if (accept && myCardId != null) 'myCardId': myCardId,
      if (accept && myCardName != null) 'myCardName': myCardName,
      if (accept) 'myCardRare': myCardRare,
    };
    if (isHost) {
      if (toId != 'host' && toId != _myIp) {
        _udp.sendTo(toId, {...msg, 'from': _myIp ?? 'host', 'fromName': _myName});
      }
    } else if (_hostIp != null) {
      _udp.sendTo(_hostIp!, msg);
    }
    // Limpar trade pendente
    _gameState = {..._gameState}..remove('trade_msg');
    notifyListeners();
  }

  // ── Desconectar ───────────────────────────────────────────
  Future<void> disconnect() async {
    if (_role == MpRole.client && _hostIp != null) {
      _udp.sendTo(_hostIp!, {'type': 'leave'});
    }
    _udp.stop();
    _roomCleanupTimer?.cancel();
    _role = MpRole.none;
    _phase = MpGamePhase.lobby;
    _players = [];
    _currentGame = '';
    _gameState = {};
    _lastResult = null;
    _errorMsg = null;
    _hostIp = null;
    _availableRooms.clear();
    notifyListeners();
  }

  // ── Helpers internos ──────────────────────────────────────
  void _broadcastToClients(Map<String, dynamic> msg) {
    final ips = _players.map((p) => p.id).toList();
    _udp.sendToAll(ips, msg);
  }

  void _updatePlayerScore(String id, int score) {
    for (final p in _players) {
      if (p.id == id) {
        p.score = score;
        return;
      }
    }
  }

  String _getPlayerName(String ip) {
    return _players.firstWhere((p) => p.id == ip,
            orElse: () => PlayerInfo(id: ip, name: ip))
        .name;
  }

  List<int> _generateMemoryCards() {
    final pairs = List.generate(8, (i) => i)..addAll(List.generate(8, (i) => i));
    pairs.shuffle();
    return pairs;
  }

  @override
  void dispose() {
    _udp.stop();
    _roomCleanupTimer?.cancel();
    super.dispose();
  }
}
