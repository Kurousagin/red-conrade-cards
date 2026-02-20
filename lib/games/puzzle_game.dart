import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/soviet_theme.dart';

const _puzzleSymbols = ['', '☭', '✊', '⭐', '⚒️', '🌟', '🔴', '👑', '🎖️'];

List<int> _shuffle(List<int> tiles) {
  final arr = List<int>.from(tiles);
  var blankIdx = arr.indexOf(0);
  for (int i = 0; i < 150; i++) {
    final row = blankIdx ~/ 3, col = blankIdx % 3;
    final moves = <int>[];
    if (row > 0) moves.add(blankIdx - 3);
    if (row < 2) moves.add(blankIdx + 3);
    if (col > 0) moves.add(blankIdx - 1);
    if (col < 2) moves.add(blankIdx + 1);
    final target = moves[Random().nextInt(moves.length)];
    final tmp = arr[blankIdx];
    arr[blankIdx] = arr[target];
    arr[target] = tmp;
    blankIdx = target;
  }
  return arr;
}

class PuzzleGame extends StatefulWidget {
  final VoidCallback onWin;
  final VoidCallback onBack;
  const PuzzleGame({super.key, required this.onWin, required this.onBack});
  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  late List<int> _tiles;
  int _moves = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    setState(() {
      _tiles = _shuffle([1, 2, 3, 4, 5, 6, 7, 8, 0]);
      _moves = 0;
      _won = false;
    });
  }

  void _tap(int i) {
    if (_won) return;
    final blankIdx = _tiles.indexOf(0);
    final row = i ~/ 3, col = i % 3;
    final bRow = blankIdx ~/ 3, bCol = blankIdx % 3;
    final adjacent = (row - bRow).abs() + (col - bCol).abs() == 1;
    if (!adjacent) return;
    setState(() {
      final tmp = _tiles[i];
      _tiles[i] = _tiles[blankIdx];
      _tiles[blankIdx] = tmp;
      _moves++;
      if (_tiles
          .asMap()
          .entries
          .every((e) => e.value == [1, 2, 3, 4, 5, 6, 7, 8, 0][e.key])) {
        _won = true;
        widget.onWin();
      }
    });
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: SC.card,
                  child: Row(
                    children: [
                      _backBtn(),
                      const Expanded(
                          child: Text('☭ QUEBRA-CABEÇA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Oswald',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: SC.gold,
                                  letterSpacing: 1))),
                      Text('🎯 $_moves',
                          style: const TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 14,
                              color: SC.red,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Deslize as peças para ordenar 1–8',
                    style: TextStyle(fontSize: 12, color: SC.grey)),
                const SizedBox(height: 20),
                // Puzzle grid
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: 9,
                      itemBuilder: (_, i) {
                        final val = _tiles[i];
                        return GestureDetector(
                          onTap: () => _tap(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            decoration: BoxDecoration(
                              color: val == 0
                                  ? Colors.transparent
                                  : Color.lerp(SC.redDark,
                                      const Color(0xFF000044), val / 8),
                              border: Border.all(
                                color:
                                    val == 0 ? const Color(0xFF330000) : SC.red,
                                width: val == 0 ? 1 : 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: val == 0
                                ? null
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_puzzleSymbols[val],
                                          style: const TextStyle(fontSize: 22)),
                                      Text('$val',
                                          style: const TextStyle(
                                            fontFamily: 'Oswald',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: SC.gold,
                                          )),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Hint
                Text('Ordem: ${_puzzleSymbols.skip(1).join(' ')}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF555555))),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _init,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF330000),
                      border: Border.all(color: SC.redDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🔄 EMBARALHAR',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: SC.red,
                        )),
                  ),
                ),
              ],
            ),
            if (_won)
              WinDialog(
                title: 'PUZZLE RESOLVIDO!',
                message: 'Resolvido em $_moves movimentos!',
                reward: '+1 🎟️ TICKET!',
                onPlayAgain: _init,
                onMenu: widget.onBack,
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
