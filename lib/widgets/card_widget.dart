import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import '../widgets/soviet_theme.dart';

Widget _cardImage(ComradeCard card,
    {double fontSize = 28, BoxFit fit = BoxFit.cover}) {
  if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
    return CachedNetworkImage(
      imageUrl: card.imageUrl!,
      fit: fit,
      placeholder: (_, __) => Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(SC.red.withValues(alpha: 0.6)),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Center(
        child: Text(card.emoji, style: TextStyle(fontSize: fontSize)),
      ),
    );
  }
  return Center(child: Text(card.emoji, style: TextStyle(fontSize: fontSize)));
}

// ── Small card for grid ───────────────────────────────────────
class CardGridItem extends StatelessWidget {
  final ComradeCard card;
  final bool owned;
  final int count;
  final bool isFav;
  final VoidCallback? onTap;
  final VoidCallback? onFavTap;

  const CardGridItem({
    super.key,
    required this.card,
    required this.owned,
    this.count = 0,
    this.isFav = false,
    this.onTap,
    this.onFavTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: owned ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: owned
                  ? (card.rare ? SC.gold : SC.red)
                  : const Color(0xFF333333),
              width: card.rare && owned ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: card.rare && owned
                ? [
                    BoxShadow(
                        color: SC.gold.withValues(alpha: 0.3), blurRadius: 6)
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Column(
              children: [
                // Art area
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      owned
                          ? _cardImage(card, fontSize: 28)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1A1A1A),
                                    Color(0xFF0D0D0D)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Text('?',
                                    style: TextStyle(
                                        fontSize: 24,
                                        color: Color(0xFF333333),
                                        fontWeight: FontWeight.w900)),
                              ),
                            ),
                      // Rare badge
                      if (card.rare)
                        Positioned(
                          top: 3,
                          left: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: SC.gold.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child:
                                const Text('⭐', style: TextStyle(fontSize: 8)),
                          ),
                        ),
                      // Count badge
                      if (owned && count > 1)
                        Positioned(
                          bottom: 3,
                          right: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: SC.red.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text('x$count',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      // Fav button
                      if (owned && onFavTap != null)
                        Positioned(
                          top: 3,
                          right: 3,
                          child: GestureDetector(
                            onTap: onFavTap,
                            child: Text(isFav ? '❤️' : '🤍',
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                    ],
                  ),
                ),
                // Name bar
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                  color: SC.cardDark,
                  child: Text(
                    owned ? card.name : '???',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: card.rare && owned ? SC.gold : SC.cream,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Large card for modal/win display ─────────────────────────
class CardDisplay extends StatelessWidget {
  final ComradeCard card;

  const CardDisplay({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        border: Border.all(
          color: card.rare ? SC.gold : SC.red,
          width: card.rare ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (card.rare ? SC.gold : SC.red).withValues(alpha: 0.4),
            blurRadius: card.rare ? 16 : 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _cardImage(card, fontSize: 52),
                  if (card.rare)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black.withValues(alpha: 0.7),
                        child: const Text(
                          '⭐ ULTRA RARO ⭐',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 9,
                              color: SC.gold,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: SC.cardDark,
              child: Column(
                children: [
                  Text(
                    card.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: card.rare ? SC.gold : SC.cream,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '"${card.desc}"',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 9,
                        color: SC.grey,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
