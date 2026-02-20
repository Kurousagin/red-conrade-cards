// ══════════════════════════════════════════════════════════════
//  MpMemoryRace — Memória Competitiva Multiplayer
//  Cada jogador tem seu próprio tabuleiro. Quem achar mais
//  pares primeiro vence. Pares encontrados são broadcastados.
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/soviet_theme.dart';
import 'mp_provider.dart';

const _emojis = ['☭', '✊', '⚒️', '🔴', '🌟', '🚂', '🏭', '📢'];

class MpMemoryRace extends StatefulWidget {
  final MpProvider mp;
  const MpMemoryRace({super.key, required this.mp});

  @override
  State<MpMemoryRace> createState() => _MpMemoryRaceState();
}

class _MpMemoryRaceState extends State<MpMemoryRace> {
  static const _totalPairs = 8;

  // Meu tabuleiro local
  late List<int> _cards; // índices dos emojis
  late List<bool> _revealed;
  late List<bool> _matched;
  int _myScore = 0;
  int? _firstFlipped;
  bool _checking = false;
  bool _finished = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // Scores dos oponentes
  final Map<String, int> _otherScores = {};

  @override
  void initState() {
    super.initState();
    // Gerar tabuleiro local
    final pairs = List.generate(_totalPairs, (i) => i)
      ..addAll(List.generate(_totalPairs, (i) => i));
    pairs.shuffle();
    _cards = pairs;
    _revealed = List.filled(_totalPairs * 2, false);
    _matched = List.filled(_totalPairs * 2, false);

    widget.mp.addListener(_onMpUpdate);

    // Timer de tempo corrido
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_finished && mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.mp.removeListener(_onMpUpdate);
    super.dispose();
  }

  void _onMpUpdate() {
    // Atualizar scores dos oponentes
    final newScores = <String, int>{};
    for (final p in widget.mp.players) {
      newScores[p.name] = p.score;
    }
    final gs = widget.mp.gameState;
    final hostMemScore = gs['host_memory_score'] as int?;
    if (hostMemScore != null && !widget.mp.isHost) {
      newScores['HOST'] = hostMemScore;
    }
    if (mounted) setState(() => _otherScores.addAll(newScores));
  }

  void _flipCard(int index) {
    if (_checking || _matched[index] || _revealed[index] || _finished) return;

    setState(() {
      _revealed[index] = true;
    });

    if (_firstFlipped == null) {
      _firstFlipped = index;
    } else {
      _checking = true;
      final first = _firstFlipped!;
      _firstFlipped = null;

      if (_cards[first] == _cards[index]) {
        // Par encontrado
        setState(() {
          _matched[first] = true;
          _matched[index] = true;
          _myScore++;
        });

        // Broadcast
        widget.mp.sendMemoryMatch(first, index, true, _myScore);

        if (_myScore == _totalPairs) {
          setState(() => _finished = true);
          _timer?.cancel();
          if (widget.mp.isHost) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) widget.mp.hostEndGame();
            });
          }
        }
        _checking = false;
      } else {
        // Par errado
        widget.mp.sendMemoryMatch(first, index, false, _myScore);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            setState(() {
              _revealed[first] = false;
              _revealed[index] = false;
              _checking = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SovietHeader(
          title: '🧠 MEMORY RACE ☭',
          subtitle: 'Ache mais pares que os camaradas!',
        ),

        // Score bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: SC.cardDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScorePill(
                  label: 'VOCÊ',
                  score: _myScore,
                  total: _totalPairs,
                  highlight: true),
              Text('⏱ ${_elapsedSeconds}s',
                  style: const TextStyle(
                      fontFamily: 'Oswald', fontSize: 14, color: SC.grey)),
              ..._otherScores.entries.map((e) =>
                  _ScorePill(label: e.key, score: e.value, total: _totalPairs)),
            ],
          ),
        ),

        // Grid de cartas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _cards.length,
              itemBuilder: (_, index) {
                final isRevealed = _revealed[index] || _matched[index];
                final isMatch = _matched[index];
                return GestureDetector(
                  onTap: () => _flipCard(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isMatch
                          ? SC.greenDark.withValues(alpha: 0.3)
                          : isRevealed
                              ? SC.red.withValues(alpha: 0.2)
                              : SC.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMatch
                            ? SC.green
                            : isRevealed
                                ? SC.red
                                : SC.redDark,
                        width: isMatch ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: isRevealed
                          ? Text(_emojis[_cards[index] % _emojis.length],
                              style: const TextStyle(fontSize: 28))
                          : const Text('?',
                              style: TextStyle(
                                  fontFamily: 'Oswald',
                                  fontSize: 22,
                                  color: SC.grey,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (_finished)
          Container(
            padding: const EdgeInsets.all(16),
            color: SC.greenDark.withValues(alpha: 0.2),
            child: Column(
              children: [
                const Text('✅ CONCLUÍDO!',
                    style: TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: SC.green)),
                Text(
                  widget.mp.isHost
                      ? 'Calculando resultado...'
                      : 'Aguardando outros finalizarem...',
                  style: const TextStyle(
                      fontFamily: 'Oswald', fontSize: 12, color: SC.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int score;
  final int total;
  final bool highlight;

  const _ScorePill({
    required this.label,
    required this.score,
    required this.total,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 10,
                color: highlight ? SC.gold : SC.grey,
                letterSpacing: 1)),
        Text('$score/$total',
            style: TextStyle(
                fontFamily: 'Oswald',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: highlight ? SC.gold : SC.cream)),
      ],
    );
  }
}
