// ══════════════════════════════════════════════════════════════
//  MpClientConn — Conexão WebSocket do CLIENTE (não-host)
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef MpMsgCallback = void Function(Map<String, dynamic> msg);

class MpClientConn {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  MpMsgCallback? onMessage;
  VoidCallback? onDisconnected;
  String? myId;
  String? myName;
  bool _connected = false;
  bool get connected => _connected;

  Future<bool> connect(String ip, String name) async {
    try {
      final uri = Uri.parse('ws://$ip:8765');
      _channel = WebSocketChannel.connect(uri);
      myName = name;

      _sub = _channel!.stream.listen(
        (raw) {
          try {
            final msg = json.decode(raw as String) as Map<String, dynamic>;
            if (msg['type'] == 'joined') {
              myId = msg['id'] as String?;
              _connected = true;
            }
            onMessage?.call(msg);
          } catch (e) {
            debugPrint('MpClientConn parse: $e');
          }
        },
        onDone: () {
          _connected = false;
          onDisconnected?.call();
        },
        onError: (_) {
          _connected = false;
          onDisconnected?.call();
        },
      );

      // Enviar join
      _send({'type': 'join', 'name': name});

      // Aguardar confirmação de conexão (até 5s)
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_connected) return true;
      }
      return _connected;
    } catch (e) {
      debugPrint('MpClientConn connect error: $e');
      return false;
    }
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(json.encode(msg));
    } catch (_) {}
  }

  void send(Map<String, dynamic> msg) => _send(msg);

  Future<void> disconnect() async {
    _connected = false;
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }
}
