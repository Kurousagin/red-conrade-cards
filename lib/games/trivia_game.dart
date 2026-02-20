import 'package:flutter/material.dart';
import '../widgets/soviet_theme.dart';

const _allQ = [
  (
    'Qual é a cor predominante do comunismo?',
    ['Azul', 'Vermelho', 'Verde', 'Amarelo'],
    1
  ),
  (
    'O que o símbolo ☭ representa?',
    [
      'Martelo e Espada',
      'Foice e Martelo',
      'Estrela e Foice',
      'Cruz e Martelo'
    ],
    1
  ),
  (
    'Quem escreveu "O Manifesto Comunista"?',
    ['Lenin', 'Stalin', 'Marx e Engels', 'Trotsky'],
    2
  ),
  (
    'Em que ano ocorreu a Revolução Russa?',
    ['1905', '1917', '1921', '1933'],
    1
  ),
  (
    'O que significa "URSS"?',
    [
      'União das Repúblicas Socialistas Soviéticas',
      'União Russa de Sistemas Socialistas',
      'União Rev. Soviética Socialista',
      'Unidade Russa de Sovietes'
    ],
    0
  ),
  (
    'Qual é a capital da Rússia?',
    ['São Petersburgo', 'Moscou', 'Kiev', 'Stalingrado'],
    1
  ),
  (
    '"De cada um segundo suas capacidades..." O que completa?',
    ['Força', 'Necessidades', 'Méritos', 'Trabalho'],
    1
  ),
  (
    'Símbolo do trabalhador rural soviético?',
    ['Pá', 'Enxada', 'Foice', 'Picareta'],
    2
  ),
  (
    'Quem liderou o exército soviético na WWII?',
    ['Stalin', 'Zhukov', 'Rokossovsky', 'Konev'],
    0
  ),
  (
    'Qual foi o primeiro satélite artificial?',
    ['Vostok', 'Sputnik', 'Mir', 'Cosmos'],
    1
  ),
];

class TriviaGame extends StatefulWidget {
  final VoidCallback onWin;
  final VoidCallback onBack;
  const TriviaGame({super.key, required this.onWin, required this.onBack});
  @override
  State<TriviaGame> createState() => _TriviaGameState();
}

class _TriviaGameState extends State<TriviaGame> {
  late List<(String, List<String>, int)> _questions;
  int _current = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final copy = [..._allQ]..shuffle();
    _questions = copy.take(5).toList();
  }

  void _answer(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
      _answered = true;
    });
    if (i == _questions[_current].$3) setState(() => _score++);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_current < _questions.length - 1) {
        setState(() {
          _current++;
          _selected = null;
          _answered = false;
        });
      } else {
        setState(() => _done = true);
        if (_score >= 3) widget.onWin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_current];
    final passed = _score >= 3;

    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: SC.card,
              child: Row(
                children: [
                  _backBtn(),
                  const Expanded(
                      child: Text('☭ TRIVIA SOVIÉTICA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Oswald',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: SC.gold,
                              letterSpacing: 1))),
                  Text('✓ $_score/${_questions.length}',
                      style: const TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 14,
                          color: SC.green,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: _done ? _buildResult(passed) : _buildQuestion(q),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion((String, List<String>, int) q) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Text('Pergunta ${_current + 1} de ${_questions.length}',
              style: const TextStyle(
                  fontFamily: 'Oswald', fontSize: 11, color: SC.grey)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _current / _questions.length,
              backgroundColor: SC.cardDark,
              valueColor: const AlwaysStoppedAnimation<Color>(SC.red),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 14),
          // Question
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SC.card,
              border: Border.all(color: SC.redDark),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: SC.red, borderRadius: BorderRadius.circular(4)),
                  child: Text('P${_current + 1}',
                      style: const TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(q.$1,
                        style: const TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 15,
                            color: SC.cream,
                            height: 1.5))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Options
          ...q.$2.asMap().entries.map((e) {
            final i = e.key;
            final opt = e.value;
            Color bg = SC.bg, border = const Color(0xFF330000);
            Color txtColor = SC.cream;
            if (_answered) {
              if (i == q.$3) {
                bg = const Color(0xFF003300);
                border = SC.green;
                txtColor = SC.green;
              } else if (i == _selected && i != q.$3) {
                bg = const Color(0xFF330000);
                border = SC.red;
                txtColor = SC.red;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _answer(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: border, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                            child: Text('ABCD'[i],
                                style: TextStyle(
                                    fontFamily: 'Oswald',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: txtColor))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(opt,
                              style: TextStyle(
                                  fontFamily: 'Oswald',
                                  fontSize: 13,
                                  color: txtColor))),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResult(bool passed) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(passed ? '🏆' : '💀', style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text(
                passed ? 'GLORIOSO CAMARADA!' : 'REPROVADO NO PARTIDO!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: passed ? SC.gold : SC.red,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text('Acertou $_score de ${_questions.length} perguntas',
                  style: const TextStyle(fontSize: 14, color: SC.cream)),
              if (passed) ...[
                const SizedBox(height: 10),
                const Text('+1 🎟️ TICKET!',
                    style: TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: SC.green)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: SovietButton(
                    label: 'JOGAR DE NOVO',
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onTap: () {
                      setState(() {
                        final copy = [..._allQ]..shuffle();
                        _questions = copy.take(5).toList();
                        _current = 0;
                        _score = 0;
                        _selected = null;
                        _answered = false;
                        _done = false;
                      });
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: SovietButton(
                    label: 'MENU',
                    bgColor: SC.cardDark,
                    borderColor: SC.redDark,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onTap: widget.onBack,
                  )),
                ],
              ),
            ],
          ),
        ),
      );

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
