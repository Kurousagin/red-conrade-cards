import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/soviet_theme.dart';
import '../games/memory_game.dart';
import '../games/trivia_game.dart';
import '../games/tap_game.dart';
import '../games/reflex_game.dart';
import '../games/simon_game.dart';
import '../games/puzzle_game.dart';

const _gameList = [
  ('memory',  '🃏', 'MEMÓRIA SOVIÉTICA',       'Encontre os pares de símbolos',               Color(0xFF8B0000)),
  ('trivia',  '📚', 'TRIVIA MARXISTA',          'Prove seu conhecimento do socialismo',         Color(0xFF003366)),
  ('tap',     '✊', 'CONTADOR ESTAKHANOVISTA',  '30 taps em 10 segundos',                      Color(0xFF004400)),
  ('reflex',  '⚡', 'REFLEXOS DO GULAG',        'Reaja ao sinal verde rapidamente',             Color(0xFF664400)),
  ('simon',   '🎯', 'SIMON SOVIÉTICO',          'Repita a sequência — 5 níveis para vencer',   Color(0xFF440066)),
  ('puzzle',  '🧩', 'QUEBRA-CABEÇA DO POVO',   'Monte o puzzle deslizando peças',             Color(0xFF006666)),
];

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});
  @override State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String? _activeGame;
  String? _toast;

  void _onWin() {
    context.read<GameProvider>().recordGameWin();
    setState(() => _toast = '+1 🎟️ PELO PARTIDO!');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();

    if (_activeGame != null) {
      return Stack(
        children: [
          _buildActiveGame(),
          if (_toast != null)
            Positioned(
              top: 70, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: SC.greenDark.withValues(alpha: 0.95),
                    border: Border.all(color: SC.green),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: SC.green.withValues(alpha: 0.3), blurRadius: 12)],
                  ),
                  child: Text(_toast!, style: const TextStyle(
                    fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 16, color: SC.green,
                  )),
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Column(
          children: [
            SovietHeader(title: '🎮 CENTRAL DE JOGOS ☭', subtitle: 'Jogue mini-jogos para ganhar tickets'),
            // Tickets display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: SC.cardDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SALDO ATUAL:', style: TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.grey)),
                  TicketBadge(amount: gp.tickets),
                ],
              ),
            ),
            // Toast
            if (_toast != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: SC.greenDark.withValues(alpha: 0.3),
                child: Text(_toast!, textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 15, color: SC.green)),
              ),
            // Game list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: _gameList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final (id, icon, name, desc, color) = _gameList[i];
                  return _GameCard(
                    id: id, icon: icon, name: name, desc: desc, color: color,
                    onTap: () => setState(() => _activeGame = id),
                  );
                },
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(8),
              color: SC.cardDark,
              child: const Text('☭ Cada vitória = +1 Ticket do Povo ☭',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFF555555), letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGame() {
    final props = (onWin: _onWin, onBack: () => setState(() => _activeGame = null));
    return switch (_activeGame) {
      'memory' => MemoryGame(onWin: props.onWin, onBack: props.onBack),
      'trivia' => TriviaGame(onWin: props.onWin, onBack: props.onBack),
      'tap'    => TapGame(onWin: props.onWin, onBack: props.onBack),
      'reflex' => ReflexGame(onWin: props.onWin, onBack: props.onBack),
      'simon'  => SimonGame(onWin: props.onWin, onBack: props.onBack),
      'puzzle' => PuzzleGame(onWin: props.onWin, onBack: props.onBack),
      _        => const SizedBox(),
    };
  }
}

class _GameCard extends StatelessWidget {
  final String id, icon, name, desc;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({required this.id, required this.icon, required this.name, required this.desc, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SC.card,
          border: Border.all(color: const Color(0xFF330000)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(
                    fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                    fontSize: 13, color: SC.gold, letterSpacing: 0.5,
                  )),
                  const SizedBox(height: 3),
                  Text(desc, style: const TextStyle(fontSize: 10, color: SC.grey)),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SC.gold.withValues(alpha: 0.12),
                    border: Border.all(color: SC.gold.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('+1 🎟️', style: TextStyle(
                    fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 10, color: SC.gold,
                  )),
                ),
                const SizedBox(height: 6),
                const Text('▶', style: TextStyle(color: SC.red, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
