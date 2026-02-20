// ══════════════════════════════════════════════════════════════
//  MpUdpService — Comunicação P2P via UDP na LAN
//
//  POR QUÊ UDP E NÃO TCP?
//  Android bloqueia TCP servidores em 0.0.0.0 (SocketException
//  errno=1). UDP com RawDatagramSocket funciona normalmente em
//  todos os dispositivos Android sem root.
//
//  ARQUITETURA:
//  • Porta 8765 UDP — todos os dispositivos escutam
//  • Descoberta: HOST envia BROADCAST periódico com dados da sala
//  • Clientes respondem ao broadcast com JOIN
//  • Após join, comunicação é UNICAST (IP:porta direto)
//  • Mensagens JSON <= 65507 bytes (limite UDP)
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

const _kPort = 8765;
const _kBroadcastAddr = '255.255.255.255';
const _kMagic = 'RCC☭'; // evita conflito com outros apps

typedef UdpMsgCallback = void Function(String fromIp, Map<String, dynamic> msg);

class MpUdpService {
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  bool _running = false;

  UdpMsgCallback? onMessage;
  VoidCallback? onError;

  bool get running => _running;
  String? _myIp;
  String? get myIp => _myIp;

  // ── Iniciar socket UDP ─────────────────────────────────────
  Future<bool> start() async {
    if (_running) return true;
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _kPort,
        reuseAddress: true,
        reusePort: false,
      );
      _socket!.broadcastEnabled = true;
      _running = true;

      // Descobrir nosso IP local
      _myIp = await _getLocalIp();

      // Escutar pacotes recebidos
      _socket!.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket?.receive();
            if (datagram == null) return;
            _handleDatagram(datagram);
          }
        },
        onError: (e) {
          debugPrint('UDP error: $e');
          onError?.call();
        },
        onDone: () {
          _running = false;
        },
      );

      debugPrint('UDP socket aberto na porta $_kPort | IP: $_myIp');
      return true;
    } catch (e) {
      debugPrint('Erro ao abrir UDP socket: $e');
      _running = false;
      return false;
    }
  }

  void stop() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
    _running = false;
  }

  // ── Enviar para IP específico (unicast) ────────────────────
  void sendTo(String ip, Map<String, dynamic> msg) {
    _send(ip, msg);
  }

  // ── Enviar para toda a rede (broadcast) ───────────────────
  void broadcast(Map<String, dynamic> msg) {
    _send(_kBroadcastAddr, msg);
  }

  // ── Broadcast periódico (para manter sala visível) ─────────
  void startPeriodicBroadcast(Map<String, dynamic> msg,
      {Duration interval = const Duration(seconds: 2)}) {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(interval, (_) {
      if (_running) broadcast(msg);
    });
    // Enviar imediatamente também
    broadcast(msg);
  }

  void stopPeriodicBroadcast() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
  }

  // ── Enviar para lista de IPs (todos os membros da sala) ────
  void sendToAll(List<String> ips, Map<String, dynamic> msg) {
    for (final ip in ips) {
      _send(ip, msg);
    }
  }

  // ── Interno ───────────────────────────────────────────────
  void _send(String ip, Map<String, dynamic> msg) {
    if (!_running || _socket == null) return;
    try {
      final payload = {'magic': _kMagic, ...msg};
      final data = utf8.encode(json.encode(payload));
      final addr = InternetAddress(ip);
      _socket!.send(data, addr, _kPort);
    } catch (e) {
      debugPrint('UDP send error to $ip: $e');
    }
  }

  void _handleDatagram(Datagram datagram) {
    try {
      final raw = utf8.decode(datagram.data);
      final msg = json.decode(raw) as Map<String, dynamic>;
      // Verificar magic para ignorar outros apps UDP na rede
      if (msg['magic'] != _kMagic) return;
      // Ignorar mensagens que vieram do próprio dispositivo
      final fromIp = datagram.address.address;
      if (fromIp == _myIp) return;
      // Remover magic antes de passar para cima
      msg.remove('magic');
      onMessage?.call(fromIp, msg);
    } catch (e) {
      // Pacote malformado — ignorar
    }
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168')) {
            return addr.address;
          }
        }
      }
      // Fallback para qualquer IPv4 privado
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (e) {
      debugPrint('Erro ao obter IP: $e');
    }
    return null;
  }
}
