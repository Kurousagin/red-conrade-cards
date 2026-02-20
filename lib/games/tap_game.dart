import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/soviet_theme.dart';

const _target = 30;
const _timeLimit = 10;

class TapGame extends StatefulWidget {
  final VoidCallback onWin;
  final VoidCallback onBack;
  const TapGame({super.key, required this.onWin, required this.onBack});
  @override
  State<TapGame> createState() => _TapGameState();
}

class _TapGameState extends State<TapGame> {
  int _count = 0, _timeLeft = _timeLimit;
  bool _running = false, _done = false, _won = false;
  Timer? _timer;

  void _start() {
    setState(() {
      _count = 0;
      _timeLeft = _timeLimit;
      _done = false;
      _won = false;
      _running = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          t.cancel();
          _running = false;
          _done = true;
        }
      });
    });
  }

  void _tap() {
    if (!_running || _done) return;
    setState(() {
      _count++;
      if (_count >= _target) {
        _timer?.cancel();
        _running = false;
        _done = true;
        _won = true;
        widget.onWin();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _timeLeft / _timeLimit;
    final timerColor = pct > 0.4
        ? SC.green
        : pct > 0.2
            ? const Color(0xFFFF6600)
            : SC.red;

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
                  const Expanded(
                      child: Text('☭ CONTADOR SOVIÉTICO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Oswald',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: SC.gold,
                              letterSpacing: 1))),
                  Text('$_count/$_target',
                      style: const TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 14,
                          color: SC.red,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Timer bar
                  if (_running)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 12,
                                backgroundColor: SC.cardDark,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(timerColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${_timeLeft}s',
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                color: SC.gold,
                              )),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Big counter
                  Text('$_count',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w700,
                        fontSize: 88,
                        color: SC.red,
                        shadows: [
                          Shadow(
                              color: SC.red.withValues(alpha: 0.4),
                              blurRadius: 20)
                        ],
                      )),
                  Text('Meta: $_target taps em ${_timeLimit}s',
                      style: const TextStyle(
                        fontSize: 13,
                        color: SC.grey,
                      )),
                  const SizedBox(height: 32),
                  if (!_done)
                    _running
                        ? GestureDetector(
                            onTap: () => _tap(),
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                    colors: [SC.red, SC.redDark]),
                                border: Border.all(color: SC.gold, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                      color: SC.red.withValues(alpha: 0.4),
                                      blurRadius: 24)
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('✊', style: TextStyle(fontSize: 44)),
                                  Text('TAP! TAP! TAP!',
                                      style: TextStyle(
                                          fontFamily: 'Oswald',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Colors.white,
                                          letterSpacing: 2)),
                                  Text('PELA REVOLUÇÃO!',
                                      style: TextStyle(
                                          fontSize: 10, color: SC.cream)),
                                ],
                              ),
                            ),
                          )
                        : SovietButton(
                            label: '☭ INICIAR MISSÃO',
                            onTap: _start,
                            borderColor: SC.gold,
                            textColor: SC.gold,
                            fontSize: 18,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          )
                  else
                    _ResultPanel(
                      won: _won,
                      count: _count,
                      target: _target,
                      onPlayAgain: _start,
                      onMenu: widget.onBack,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backBtn() => GestureDetector(
        onTap: widget.onBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              border: Border.all(color: SC.redDark),
              borderRadius: BorderRadius.circular(6)),
          child: const Text('← VOLTAR',
              style: TextStyle(
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: SC.red,
                  letterSpacing: 1)),
        ),
      );
}

class _ResultPanel extends StatelessWidget {
  final bool won;
  final int count, target;
  final VoidCallback onPlayAgain, onMenu;
  const _ResultPanel(
      {required this.won,
      required this.count,
      required this.target,
      required this.onPlayAgain,
      required this.onMenu});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(won ? '🎉' : '💀', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(won ? 'CAMARADA VELOZ!' : 'MUITO LENTO!',
              style: TextStyle(
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: won ? SC.gold : SC.red,
                  letterSpacing: 2)),
          const SizedBox(height: 6),
          Text(won ? 'Parabéns! $count taps!' : 'Só $count de $target taps',
              style: const TextStyle(color: SC.grey, fontSize: 13)),
          if (won) ...[
            const SizedBox(height: 8),
            const Text('+1 🎟️ TICKET!',
                style: TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: SC.green)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SovietButton(
                  label: 'TENTAR NOVAMENTE',
                  onTap: onPlayAgain,
                  fontSize: 12,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              const SizedBox(width: 10),
              SovietButton(
                  label: 'MENU',
                  onTap: onMenu,
                  bgColor: SC.cardDark,
                  borderColor: SC.redDark,
                  fontSize: 12,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            ],
          ),
        ],
      );
}
