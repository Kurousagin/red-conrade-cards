import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/soviet_theme.dart';

const _simonBtns = [
  ('☭', Color(0xFF8B0000), Color(0xFFFF3333)),
  ('⭐', Color(0xFF8B4000), Color(0xFFFF8C00)),
  ('✊', Color(0xFF006600), Color(0xFF00FF66)),
  ('⚒️', Color(0xFF0033AA), Color(0xFF4488FF)),
];

enum SimonPhase { idle, showing, input, win, lose }

class SimonGame extends StatefulWidget {
  final VoidCallback onWin;
  final VoidCallback onBack;
  const SimonGame({super.key, required this.onWin, required this.onBack});
  @override State<SimonGame> createState() => _SimonGameState();
}

class _SimonGameState extends State<SimonGame> {
  SimonPhase _phase = SimonPhase.idle;
  List<int> _sequence = [];
  List<int> _player = [];
  int _level = 0;
  int? _lit;

  void _startGame() {
    _sequence = [];
    _nextLevel();
  }

  Future<void> _nextLevel() async {
    _sequence.add(Random().nextInt(4));
    _player = [];
    _level = _sequence.length;
    setState(() => _phase = SimonPhase.showing);
    await Future.delayed(const Duration(milliseconds: 600));
    for (final btn in _sequence) {
      setState(() => _lit = btn);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _lit = null);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (mounted) setState(() => _phase = SimonPhase.input);
  }

  void _press(int i) {
    if (_phase != SimonPhase.input) return;
    setState(() { _lit = i; });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _lit = null);
    });
    _player.add(i);
    final idx = _player.length - 1;
    if (_player[idx] != _sequence[idx]) {
      setState(() => _phase = SimonPhase.lose); return;
    }
    if (_player.length == _sequence.length) {
      if (_sequence.length >= 5) {
        setState(() => _phase = SimonPhase.win);
      } else {
        Future.delayed(const Duration(milliseconds: 600), _nextLevel);
      }
    }
  }

  void _reset() {
    setState(() { _phase = SimonPhase.idle; _sequence = []; _player = []; _level = 0; _lit = null; });
  }

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
                  const Expanded(child: Text('☭ SIMON SOVIÉTICO', textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 14, color: SC.gold, letterSpacing: 1))),
                  Text('Nível $_level', style: const TextStyle(fontFamily: 'Oswald', fontSize: 14, color: SC.red, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statusText(),
                  const SizedBox(height: 24),
                  _buildGrid(),
                  const SizedBox(height: 20),
                  if (_phase != SimonPhase.idle && _phase != SimonPhase.win && _phase != SimonPhase.lose)
                    _levelDots(),
                  if (_phase == SimonPhase.idle)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SovietButton(
                        label: '☭ INICIAR MISSÃO',
                        onTap: _startGame,
                        borderColor: SC.gold,
                        textColor: SC.gold,
                        fontSize: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                    ),
                  if (_phase == SimonPhase.win || _phase == SimonPhase.lose)
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
    switch (_phase) {
      case SimonPhase.idle:    text = 'Memorize a sequência!\n5 níveis para vencer';
      case SimonPhase.showing: text = '👁️ Observe a sequência...';
      case SimonPhase.input:   text = '🎯 Repita! (${_player.length}/${_sequence.length})';
      default: text = '';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(text, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: SC.grey, height: 1.6)),
    );
  }

  Widget _buildGrid() => SizedBox(
    width: 240,
    child: GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List.generate(4, (i) {
        final (sym, base, glow) = _simonBtns[i];
        final isLit = _lit == i;
        return GestureDetector(
          onTap: () => _press(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: RadialGradient(
                colors: isLit ? [glow, base] : [base.withValues(alpha: 0.7), base.withValues(alpha: 0.4)],
              ),
              border: Border.all(color: base, width: 3),
              boxShadow: isLit ? [BoxShadow(color: glow.withValues(alpha: 0.6), blurRadius: 24)] : null,
            ),
            child: Center(child: Text(sym, style: const TextStyle(fontSize: 32))),
          ),
        );
      }),
    ),
  );

  Widget _levelDots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(5, (i) => Container(
      width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: i < _level ? SC.gold : const Color(0xFF330000),
        border: Border.all(color: i < _level ? SC.gold : const Color(0xFF666666), width: 2),
      ),
    )),
  );

  Widget _result() {
    final won = _phase == SimonPhase.win;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(won ? '🏆' : '💀', style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(won ? 'MEMÓRIA SOVIÉTICA!' : 'MEMÓRIA BURGUESA!',
            style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 20, color: won ? SC.gold : SC.red, letterSpacing: 2)),
          const SizedBox(height: 6),
          Text(won ? 'Sequência completa de 5 níveis!' : 'Errou no nível $_level',
            style: const TextStyle(fontSize: 13, color: SC.grey)),
          if (won) ...[
            const SizedBox(height: 8),
            const Text('+1 🎟️ TICKET!', style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 18, color: SC.green)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SovietButton(label: 'JOGAR DE NOVO', fontSize: 12,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: () { if (won) widget.onWin(); _reset(); })),
              const SizedBox(width: 10),
              Expanded(child: SovietButton(label: 'MENU', bgColor: SC.cardDark, borderColor: SC.redDark,
                fontSize: 12, padding: const EdgeInsets.symmetric(vertical: 10), onTap: widget.onBack)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backBtn() => GestureDetector(
    onTap: widget.onBack,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: SC.redDark), borderRadius: BorderRadius.circular(6)),
      child: const Text('← VOLTAR', style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 11, color: SC.red, letterSpacing: 1)),
    ),
  );
}
