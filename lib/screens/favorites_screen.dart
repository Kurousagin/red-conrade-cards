import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/soviet_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _confirmClear = false;

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final favCards = gp.allCards.where((c) => gp.favorites.contains(c.id)).toList();

    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [SC.redDark, Color(0xFF4A0000)]),
                border: Border(bottom: BorderSide(color: SC.redDark, width: 2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('❤️ GALERIA FAVORITA ❤️', style: TextStyle(
                          fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                          fontSize: 16, color: SC.gold, letterSpacing: 2,
                        )),
                        Text('${favCards.length} cartas favoritas', style: const TextStyle(fontSize: 11, color: SC.cream)),
                      ],
                    ),
                  ),
                  if (favCards.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        if (_confirmClear) {
                          gp.clearFavorites();
                          setState(() => _confirmClear = false);
                        } else {
                          setState(() => _confirmClear = true);
                          Future.delayed(const Duration(seconds: 3), () {
                            if (mounted) setState(() => _confirmClear = false);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _confirmClear ? SC.red : const Color(0xFF330000),
                          border: Border.all(color: _confirmClear ? SC.redLight : SC.redDark),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _confirmClear ? '⚠️ CONFIRMAR?' : '🗑️ LIMPAR',
                          style: TextStyle(
                            fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                            fontSize: 11, color: _confirmClear ? Colors.white : SC.red,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: favCards.isEmpty
                  ? _emptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: favCards.length,
                      itemBuilder: (_, i) {
                        final card = favCards[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: SC.card,
                            border: Border.all(color: SC.redDark),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Container(
                                        color: SC.bg,
                                        child: Center(child: Text(card.emoji, style: const TextStyle(fontSize: 36))),
                                      ),
                                      if (card.rare)
                                        Positioned(
                                          top: 4, left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: SC.gold.withValues(alpha: 0.9),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: const Text('⭐', style: TextStyle(fontSize: 10)),
                                          ),
                                        ),
                                      Positioned(
                                        top: 4, right: 4,
                                        child: GestureDetector(
                                          onTap: () => gp.toggleFavorite(card.id),
                                          child: const Text('❤️', style: TextStyle(fontSize: 16)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(4),
                                  color: SC.cardDark,
                                  child: Text(card.name, textAlign: TextAlign.center,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Oswald', fontWeight: FontWeight.w600,
                                      fontSize: 9, color: card.rare ? SC.gold : SC.cream,
                                    )),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('💔', style: TextStyle(fontSize: 52)),
        SizedBox(height: 16),
        Text('NENHUM FAVORITO', style: TextStyle(
          fontFamily: 'Oswald', fontWeight: FontWeight.w700,
          fontSize: 20, color: SC.red, letterSpacing: 3,
        )),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'O coração do proletariado está vazio!\nMarque cartas como favoritas no Álbum.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: SC.grey),
          ),
        ),
        SizedBox(height: 16),
        Text('☭', style: TextStyle(fontSize: 28, color: SC.redDark)),
      ],
    ),
  );
}
