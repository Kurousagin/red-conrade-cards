// ══════════════════════════════════════════════════════════════
//  MpTapBattle — Corrida de Taps em tempo real (15 segundos)
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/soviet_theme.dart';
import 'mp_provider.dart';

class MpTapBattle extends StatefulWidget {
  final MpProvider mp;
  const MpTapBattle({super.key, required this.mp});

  @override
  State<MpTapBattle> createState() => _MpTapBattleState();
}

class _MpTapBattleState extends State<MpTapBattle>
    with TickerProviderStateMixin {
  static const _gameDuration = 15;

  int _myTaps = 0;
  int _timeLeft = _gameDuration;
  bool _started = false;
  bool _finished = false;
  Timer? _timer;

  // Scores dos outros
  final Map<String, int> _otherScores = {};

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    widget.mp.addListener(_onMpUpdate);
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    widget.mp.removeListener(_onMpUpdate);
    super.dispose();
  }

  void _onMpUpdate() {
    final gs = widget.mp.gameState;
    // Atualizar scores dos outros jogadores
    final newScores = <String, int>{};
    for (final p in widget.mp.players) {
      newScores[p.name] = p.score;
    }
    // Host score
    final hostScore = gs['host_score'] as int?;
    if (hostScore != null && !widget.mp.isHost) {
      newScores['HOST'] = hostScore;
    }
    setState(() => _otherScores.addAll(newScores));
  }

  void _startCountdown() async {
    // Contagem regressiva 3,2,1
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() {});
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _finished = true;
          t.cancel();
          _onFinish();
        }
      });
    });
  }

  void _tap() {
    if (!_started || _finished) return;
    _myTaps++;
    _pulseCtrl.forward().then((_) => _pulseCtrl.reverse());

    // Enviar score ao servidor
    if (widget.mp.isHost) {
      widget.mp.hostRegisterTap(_myTaps);
    } else {
      widget.mp.clientSendTap(_myTaps);
    }
    setState(() {});
  }

  void _onFinish() {
    if (widget.mp.isHost) {
      // Host finaliza o jogo para todos
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) widget.mp.hostEndGame();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SovietHeader(
          title: '👆 TAP BATTLE ☭',
          subtitle: 'Quem tocar mais vezes em 15s vence!',
        ),
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  // Placar dos oponentes
                  if (_otherScores.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: SC.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SC.redDark),
                      ),
                      child: Column(
                        children: _otherScores.entries
                            .map((e) => Row(
                                  children: [
                                    Text('✊ ${e.key}',
                                        style: const TextStyle(
                                            fontFamily: 'Oswald',
                                            fontSize: 13,
                                            color: SC.cream)),
                                    const Spacer(),
                                    Text('${e.value} taps',
                                        style: const TextStyle(
                                            fontFamily: 'Oswald',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: SC.gold)),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),

                  // Timer
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _started ? '⏱ $_timeLeft' : '...',
                      style: TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          color: _timeLeft <= 5 ? SC.red : SC.gold,
                          letterSpacing: 4),
                    ),
                  ),

                  // Meu score
                  Text(
                    '$_myTaps',
                    style: const TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w700,
                        fontSize: 72,
                        color: SC.cream),
                  ),
                  const Text('TAPS',
                      style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 16,
                          color: SC.grey,
                          letterSpacing: 4)),

                  const SizedBox(height: 16),

                  // Botão de tap gigante
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: GestureDetector(
                        onTap: _tap,
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: _finished
                                      ? [SC.grey, SC.cardDark]
                                      : _started
                                          ? [SC.red, SC.redDark]
                                          : [SC.redDark, SC.cardDark],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _started && !_finished
                                      ? SC.gold
                                      : SC.grey,
                                  width: 4,
                                ),
                                boxShadow: _started && !_finished
                                    ? [
                                        BoxShadow(
                                          color: SC.red.withValues(alpha: 0.6),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  _finished
                                      ? '⏰'
                                      : _started
                                          ? '☭'
                                          : '...',
                                  style: const TextStyle(fontSize: 72),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_finished)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        widget.mp.isHost
                            ? 'Calculando resultado...'
                            : 'Aguardando host...',
                        style: const TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 14,
                            color: SC.grey),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
