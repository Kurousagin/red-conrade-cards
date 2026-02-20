import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/soviet_theme.dart';

const _symbols = ['☭','⭐','✊','⚒️','🌟','💎','🔴','👑'];

class MemoryGame extends StatefulWidget {
  final VoidCallback onWin;
  final VoidCallback onBack;
  const MemoryGame({super.key, required this.onWin, required this.onBack});
  @override State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  late List<_Card> _cards;
  List<int> _flipped = [];
  Set<int> _matched = {};
  int _moves = 0;
  bool _won = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final pairs = [..._symbols, ..._symbols];
    pairs.shuffle();
    setState(() {
      _cards = List.generate(pairs.length, (i) => _Card(sym: pairs[i], id: i));
      _flipped = []; _matched = {}; _moves = 0; _won = false; _checking = false;
    });
  }

  void _flip(int i) {
    if (_checking || _flipped.contains(i) || _matched.contains(i)) return;
    setState(() => _flipped.add(i));
    if (_flipped.length == 2) {
      _moves++;
      _checking = true;
      if (_cards[_flipped[0]].sym == _cards[_flipped[1]].sym) {
        setState(() { _matched.addAll(_flipped); _flipped = []; _checking = false; });
        if (_matched.length == _cards.length) setState(() => _won = true);
      } else {
        Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() { _flipped = []; _checking = false; });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _topBar(context),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: SC.cardDark,
                  child: Text(
                    '${_matched.length ~/ 2}/${_symbols.length} pares encontrados  •  Jogadas: $_moves',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.grey),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
                      ),
                      itemCount: _cards.length,
                      itemBuilder: (_, i) => _CardTile(
                        sym: _cards[i].sym,
                        revealed: _flipped.contains(i) || _matched.contains(i),
                        matched: _matched.contains(i),
                        onTap: () => _flip(i),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_won)
              WinDialog(
                title: 'VITÓRIA DO POVO!',
                message: 'Completado em $_moves jogadas!',
                reward: '+1 🎟️ TICKET GANHO!',
                onPlayAgain: () { _init(); widget.onWin(); },
                onMenu: widget.onBack,
              ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    color: SC.card,
    child: Row(
      children: [
        _backBtn(),
        const Expanded(child: Text('☭ MEMÓRIA SOVIÉTICA', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 14, color: SC.gold, letterSpacing: 1))),
        const SizedBox(width: 60),
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

class _Card { final String sym; final int id; _Card({required this.sym, required this.id}); }

class _CardTile extends StatelessWidget {
  final String sym;
  final bool revealed, matched;
  final VoidCallback onTap;
  const _CardTile({required this.sym, required this.revealed, required this.matched, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: matched ? const Color(0xFF003300) : revealed ? SC.card : SC.bg,
          border: Border.all(
            color: matched ? SC.green : revealed ? SC.red : const Color(0xFF330000),
            width: matched ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: matched ? [BoxShadow(color: SC.green.withValues(alpha: 0.3), blurRadius: 6)] : null,
        ),
        child: Center(
          child: revealed
              ? Text(sym, style: const TextStyle(fontSize: 28))
              : const Text('☭', style: TextStyle(fontSize: 22, color: SC.redDark)),
        ),
      ),
    );
  }
}
