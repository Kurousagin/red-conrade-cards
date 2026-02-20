import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/soviet_theme.dart';

enum ReflexPhase { idle, waiting, tap, result }

class ReflexGame extends StatefulWidget {
  final VoidCallback onWin;
  final VoidCallback onBack;
  const ReflexGame({super.key, required this.onWin, required this.onBack});
  @override State<ReflexGame> createState() => _ReflexGameState();
}

class _ReflexGameState extends State<ReflexGame> {
  ReflexPhase _phase = ReflexPhase.idle;
  final List<int> _attempts = [];
  int? _lastRT;
  bool _tooEarly = false;
  Timer? _waitTimer;
  DateTime? _signalTime;
  static const _maxAttempts = 3;

  void _startRound() {
    setState(() { _phase = ReflexPhase.waiting; _tooEarly = false; });
    final delay = 1500 + Random().nextInt(3000);
    _waitTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        setState(() { _phase = ReflexPhase.tap; _signalTime = DateTime.now(); });
      }
    });
  }

  void _onTap() {
    if (_phase == ReflexPhase.idle) { _startRound(); return; }
    if (_phase == ReflexPhase.waiting) {
      _waitTimer?.cancel();
      setState(() { _tooEarly = true; _phase = ReflexPhase.idle; });
      return;
    }
    if (_phase == ReflexPhase.tap) {
      final rt = DateTime.now().difference(_signalTime!).inMilliseconds;
      setState(() { _lastRT = rt; _attempts.add(rt); });
      if (_attempts.length >= _maxAttempts) {
        setState(() => _phase = ReflexPhase.result);
      } else {
        setState(() => _phase = ReflexPhase.idle);
      }
    }
  }

  @override
  void dispose() { _waitTimer?.cancel(); super.dispose(); }

  int get _avg => _attempts.isEmpty ? 0 : _attempts.reduce((a, b) => a + b) ~/ _attempts.length;
  bool get _won => _phase == ReflexPhase.result && _avg < 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: SC.card,
              child: Row(
                children: [
                  _backBtn(),
                  const Expanded(child: Text('☭ REFLEXO SOVIÉTICO', textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 13, color: SC.gold, letterSpacing: 1))),
                  Text('${_attempts.length}/$_maxAttempts', style: const TextStyle(fontFamily: 'Oswald', fontSize: 14, color: SC.red, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_phase != ReflexPhase.result) ...[
                    _statusText(),
                    const SizedBox(height: 28),
                    _signalButton(),
                    const SizedBox(height: 28),
                    if (_attempts.isNotEmpty) _attemptsList(),
                  ] else
                    _result(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusText() {
    String text = '';
    if (_phase == ReflexPhase.idle && !_tooEarly) {
      text = _attempts.isEmpty
          ? 'Toque quando o sinal verde aparecer!\n3 tentativas, média < 500ms para vencer'
          : '${_maxAttempts - _attempts.length} tentativas restantes';
    } else if (_tooEarly) text = '⚠️ Muito rápido! Espere o sinal!';
    return Text(text, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: SC.grey, height: 1.6));
  }

  Widget _signalButton() {
    Color bg;
    String label, icon;
    switch (_phase) {
      case ReflexPhase.tap:
        bg = SC.green; label = 'TOQUE AGORA!'; icon = '⚡';
      case ReflexPhase.waiting:
        bg = const Color(0xFF333333); label = 'AGUARDANDO...'; icon = '⏳';
      default:
        bg = SC.red; label = 'TOQUE PARA INICIAR'; icon = '☭';
    }
    return GestureDetector(
      onTap: () => _onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 180, height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [bg, Color.alphaBlend(Colors.black38, bg)]),
          border: Border.all(color: Colors.white24, width: 4),
          boxShadow: _phase == ReflexPhase.tap
              ? [BoxShadow(color: SC.green.withValues(alpha: 0.5), blurRadius: 32)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white, letterSpacing: 1)),
            if (_lastRT != null && _phase == ReflexPhase.idle)
              Text('${_lastRT}ms', style: const TextStyle(fontFamily: 'Oswald', fontSize: 13, color: SC.cream)),
          ],
        ),
      ),
    );
  }

  Widget _attemptsList() => Column(
    children: _attempts.asMap().entries.map((e) {
      final i = e.key; final t = e.value;
      final color = t < 300 ? SC.green : t < 500 ? SC.gold : SC.red;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tentativa ${i + 1}:', style: const TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.grey)),
            Text('${t}ms ${t < 300 ? '⚡' : t < 500 ? '✓' : '✗'}',
              style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 12, color: color)),
          ],
        ),
      );
    }).toList(),
  );

  Widget _result() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Text(_won ? '⚡' : '🐌', style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 10),
        Text(_won ? 'REFLEXOS DE CAMARADA!' : 'REFLEXOS DE BURGUÊS!',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 20, color: _won ? SC.gold : SC.red, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('Tempo médio: $_avg ms', style: const TextStyle(fontSize: 14, color: SC.cream)),
        if (_won) ...[
          const SizedBox(height: 10),
          const Text('+1 🎟️ TICKET!', style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 18, color: SC.green)),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: SovietButton(label: 'JOGAR DE NOVO', fontSize: 12,
              padding: const EdgeInsets.symmetric(vertical: 10),
              onTap: () {
                if (_won) widget.onWin();
                setState(() { _attempts.clear(); _phase = ReflexPhase.idle; _lastRT = null; });
              })),
            const SizedBox(width: 10),
            Expanded(child: SovietButton(label: 'MENU', bgColor: SC.cardDark, borderColor: SC.redDark, fontSize: 12,
              padding: const EdgeInsets.symmetric(vertical: 10), onTap: widget.onBack)),
          ],
        ),
      ],
    ),
  );

  Widget _backBtn() => GestureDetector(
    onTap: widget.onBack,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: SC.redDark), borderRadius: BorderRadius.circular(6)),
      child: const Text('← VOLTAR', style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 11, color: SC.red, letterSpacing: 1)),
    ),
  );
}
