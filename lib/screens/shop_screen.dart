import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/game_provider.dart';
import '../widgets/soviet_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Map<String, int> _qty = {};
  String? _message;

  int _maxSell(bool rare, int count) => rare ? count - 1 : count;
  int _price(bool rare, int qty) => rare ? qty * 25 : (qty ~/ 2) * 5;

  void _sell(GameProvider gp, String id, bool rare, int qty) {
    final max = _maxSell(rare, gp.ownedCards[id] ?? 0);
    if (qty <= 0) {
      _flash('Selecione a quantidade!');
      return;
    }
    if (qty > max) {
      _flash('Quantidade inválida!');
      return;
    }
    if (!rare && qty < 2) {
      _flash('Mínimo 2 cartas comuns!');
      return;
    }
    final earned = _price(rare, qty);
    gp.sellCards(id, qty, earned);
    setState(() {
      _qty[id] = 0;
    });
    _flash('+$earned 🎟️ recebido!');
  }

  void _flash(String msg) {
    setState(() => _message = msg);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final sellable = gp.allCards.where((c) {
      final count = gp.ownedCards[c.id] ?? 0;
      return count > 0;
    }).toList();

    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Column(
          children: [
            SovietHeader(
                title: '☭ MERCADO NEGRO ☭',
                subtitle: 'Troque cartas por tickets do povo'),
            // Price guide
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: SC.cardDark,
              child: Row(
                children: [
                  const Text('● 2 comuns = ',
                      style: TextStyle(
                          fontFamily: 'Oswald', fontSize: 12, color: SC.grey)),
                  const Text('5 🎟️',
                      style: TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: SC.gold)),
                  const SizedBox(width: 20),
                  const Text('⭐ 1 rara = ',
                      style: TextStyle(
                          fontFamily: 'Oswald', fontSize: 12, color: SC.grey)),
                  const Text('25 🎟️',
                      style: TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: SC.gold)),
                ],
              ),
            ),
            // Message
            if (_message != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: _message!.startsWith('+')
                    ? SC.greenDark.withValues(alpha: 0.3)
                    : SC.red.withValues(alpha: 0.2),
                child: Text(_message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _message!.startsWith('+')
                          ? SC.green
                          : const Color(0xFFFF6666),
                    )),
              ),
            Expanded(
              child: sellable.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: sellable.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final card = sellable[i];
                        final count = gp.ownedCards[card.id] ?? 0;
                        final max = _maxSell(card.rare, count);
                        final qty = _qty[card.id] ?? 0;
                        final earned = _price(card.rare, qty);
                        final canSell = card.rare ? qty >= 1 : qty >= 2;
                        return _sellRow(
                            gp,
                            card.id,
                            card.name,
                            card.emoji,
                            card.imageUrl,
                            card.rare,
                            count,
                            max,
                            qty,
                            earned,
                            canSell);
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
          children: [
            const Text('📦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Nenhuma carta para vender.',
                style: TextStyle(
                    fontFamily: 'Oswald', color: SC.grey, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Gire a roleta para conseguir cartas!',
                style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
          ],
        ),
      );

  Widget _sellRow(
    GameProvider gp,
    String id,
    String name,
    String emoji,
    String? imageUrl,
    bool rare,
    int count,
    int max,
    int qty,
    int earned,
    bool canSell,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SC.card,
        border: Border.all(
            color: rare ? const Color(0xFF6B5300) : const Color(0xFF330000)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 60,
            decoration: BoxDecoration(
                color: SC.bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: SC.redDark)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 22))),
                      errorWidget: (_, __, ___) => Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 22))),
                    )
                  : Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: rare ? SC.gold : SC.cream,
                    )),
                Text(
                    '${rare ? '⭐ RARO' : '● COMUM'} • Tenho: $count • Máx: $max',
                    style: const TextStyle(
                        fontFamily: 'Oswald', fontSize: 10, color: SC.grey)),
                if (rare)
                  const Text('⚠️ 1 cópia preservada',
                      style: TextStyle(
                          fontFamily: 'Oswald', fontSize: 9, color: SC.red)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Controls
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qtyBtn('−', () {
                    final step = rare ? 1 : 2;
                    setState(() => _qty[id] = ((qty - step).clamp(0, max)));
                  }),
                  const SizedBox(width: 6),
                  Text('$qty',
                      style: const TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: SC.cream)),
                  const SizedBox(width: 6),
                  _qtyBtn('+', () {
                    final step = rare ? 1 : 2;
                    setState(() => _qty[id] = ((qty + step).clamp(0, max)));
                  }),
                ],
              ),
              if (qty > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('+$earned 🎟️',
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: SC.green,
                      )),
                ),
              GestureDetector(
                onTap:
                    canSell && qty > 0 ? () => _sell(gp, id, rare, qty) : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: canSell && qty > 0 ? 1.0 : 0.35,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: [SC.redDark, SC.red]),
                      border: Border.all(color: SC.redLight),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('VENDER',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: Colors.white,
                          letterSpacing: 1,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: SC.red,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white))),
        ),
      );
}
