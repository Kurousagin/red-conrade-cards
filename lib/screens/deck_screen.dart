import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/soviet_theme.dart';
import '../widgets/card_widget.dart';
import '../models/card_model.dart';

enum DeckFilter { all, owned, rare, common }

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key});
  @override State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  DeckFilter _filter = DeckFilter.all;
  ComradeCard? _selected;

  List<ComradeCard> _filtered(GameProvider gp) {
    return gp.allCards.where((c) {
      switch (_filter) {
        case DeckFilter.owned:  return gp.ownedCards.containsKey(c.id);
        case DeckFilter.rare:   return c.rare;
        case DeckFilter.common: return !c.rare;
        case DeckFilter.all:    return true;
      }
    }).toList();
  }

  String _nextRank(int rares) {
    if (rares < 1)  return '1 rara → Especial';
    if (rares < 3)  return '${3 - rares} raras → Raro';
    if (rares < 6)  return '${6 - rares} raras → Épico';
    if (rares < 10) return '${10 - rares} raras → Lendário';
    return '👑 Rank Máximo!';
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final pct = gp.totalCards > 0 ? gp.ownedCount / gp.totalCards : 0.0;
    final cards = _filtered(gp);

    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: SC.card,
                border: Border(bottom: BorderSide(color: SC.redDark, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ÁLBUM DO POVO', style: TextStyle(
                        fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                        fontSize: 13, color: SC.gold, letterSpacing: 2,
                      )),
                      Text('${(pct * 100).round()}%', style: const TextStyle(
                        fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                        fontSize: 18, color: SC.red,
                      )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: SC.cardDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(SC.red),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      _statChip('📋 ${gp.ownedCount}/${gp.totalCards}'),
                      _statChip('⭐ ${gp.stats.rareCardsCollected} raras'),
                      _statChip('🔜 ${_nextRank(gp.stats.rareCardsCollected)}'),
                    ],
                  ),
                ],
              ),
            ),
            // Filter bar
            Container(
              color: SC.cardDark,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  for (final f in DeckFilter.values)
                    Expanded(child: _filterBtn(f)),
                ],
              ),
            ),
            // Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.62,
                ),
                itemCount: cards.length,
                itemBuilder: (_, i) {
                  final card = cards[i];
                  return CardGridItem(
                    card: card,
                    owned: gp.ownedCards.containsKey(card.id),
                    count: gp.ownedCards[card.id] ?? 0,
                    isFav: gp.favorites.contains(card.id),
                    onTap: () => setState(() => _selected = card),
                    onFavTap: () => gp.toggleFavorite(card.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Card detail bottom sheet
      bottomSheet: _selected == null ? null : _buildDetailSheet(gp),
    );
  }

  Widget _statChip(String text) => Text(text, style: const TextStyle(
    fontFamily: 'Oswald', fontSize: 10, color: SC.cream,
  ));

  Widget _filterBtn(DeckFilter f) {
    final labels = {
      DeckFilter.all: 'TODOS',
      DeckFilter.owned: 'TENHO',
      DeckFilter.rare: '⭐ RAROS',
      DeckFilter.common: 'COMUNS',
    };
    final active = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: active ? SC.red : SC.bg,
          border: Border.all(color: active ? SC.redLight : const Color(0xFF330000)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(labels[f]!, textAlign: TextAlign.center, style: TextStyle(
          fontFamily: 'Oswald', fontSize: 9, fontWeight: FontWeight.w700,
          color: active ? Colors.white : SC.grey, letterSpacing: 0.5,
        )),
      ),
    );
  }

  Widget _buildDetailSheet(GameProvider gp) {
    final card = _selected!;
    final owned = gp.ownedCards.containsKey(card.id);
    return GestureDetector(
      onTap: () => setState(() => _selected = null),
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: SC.bg,
                border: Border(
                  top: BorderSide(color: SC.red, width: 2),
                  left: BorderSide(color: SC.redDark, width: 1),
                  right: BorderSide(color: SC.redDark, width: 1),
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.rare ? '⭐ CARTA RARA' : 'DETALHES DA CARTA',
                        style: TextStyle(
                          fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                          fontSize: 13, color: card.rare ? SC.gold : SC.cream,
                          letterSpacing: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selected = null),
                        child: const Text('✕', style: TextStyle(color: SC.red, fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 80, height: 112,
                        decoration: BoxDecoration(
                          color: SC.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: SC.redDark),
                        ),
                        child: Center(child: Text(card.emoji, style: const TextStyle(fontSize: 36))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(owned ? card.name : '???', style: TextStyle(
                              fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                              fontSize: 16, color: card.rare ? SC.gold : SC.cream,
                            )),
                            if (owned) Text('"${card.desc}"', style: const TextStyle(
                              fontSize: 11, color: SC.grey, fontStyle: FontStyle.italic,
                            )),
                            const SizedBox(height: 8),
                            _detailRow('Raridade', card.rare ? '⭐ RARO' : '● COMUM'),
                            _detailRow('Cópias', '${gp.ownedCards[card.id] ?? 0}'),
                            _detailRow('Favorito', gp.favorites.contains(card.id) ? '❤️ Sim' : '🤍 Não'),
                            if (owned)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () => gp.toggleFavorite(card.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: SC.card,
                                      border: Border.all(color: SC.redDark),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      gp.favorites.contains(card.id) ? '🤍 Remover Favorito' : '❤️ Adicionar Favorito',
                                      style: const TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.cream),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.grey)),
        Text(value, style: const TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.cream, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
