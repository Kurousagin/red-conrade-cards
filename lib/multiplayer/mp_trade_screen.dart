// ══════════════════════════════════════════════════════════════
//  MpTradeScreen — Sistema de Troca de Cartas Wi-Fi Local
// ══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/soviet_theme.dart';
import '../providers/game_provider.dart';
import '../models/card_model.dart';
import 'mp_provider.dart';

class MpTradeScreen extends StatefulWidget {
  const MpTradeScreen({super.key});
  @override
  State<MpTradeScreen> createState() => _MpTradeScreenState();
}

class _MpTradeScreenState extends State<MpTradeScreen> {
  ComradeCard? _selectedCard; // minha carta para oferecer
  String? _targetPlayerId;
  String? _targetPlayerName;

  // Proposta recebida
  Map<String, dynamic>? _incomingTrade;
  ComradeCard? _myCardForExchange; // carta que vou dar em troca

  @override
  void initState() {
    super.initState();
    context.read<MpProvider>().addListener(_onMpUpdate);
  }

  @override
  void dispose() {
    context.read<MpProvider>().removeListener(_onMpUpdate);
    super.dispose();
  }

  void _onMpUpdate() {
    final mp = context.read<MpProvider>();
    final tradeMsg = mp.gameState['trade_msg'] as Map<String, dynamic>?;
    if (tradeMsg != null) {
      final type = tradeMsg['type'] as String?;
      if (type == 'trade_request' && mounted) {
        setState(() => _incomingTrade = tradeMsg);
      } else if (type == 'trade_accept' && mounted) {
        _handleTradeAccepted(tradeMsg);
      } else if (type == 'trade_decline' && mounted) {
        _showSnack('❌ ${tradeMsg['fromName'] ?? 'Jogador'} recusou a troca.');
        setState(() => _selectedCard = null);
      }
    }
  }

  void _handleTradeAccepted(Map<String, dynamic> msg) {
    final gameProvider = context.read<GameProvider>();

    // Aplicar a troca: remover minha carta, ganhar a dele
    if (_selectedCard != null) {
      final myCardId = _selectedCard!.id;
      final theirCardId = msg['myCardId'] as String?;
      final theirCardIsRare = msg['myCardRare'] as bool? ?? false;

      if (theirCardId != null) {
        gameProvider.sellCards(myCardId, 1, 0); // Remove minha carta
        gameProvider.addCard(theirCardId, theirCardIsRare); // Ganha a dele
        _showSnack('✅ Troca concluída! Você recebeu: ${msg['myCardName']}');
        setState(() {
          _selectedCard = null;
          _targetPlayerId = null;
          _targetPlayerName = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MpProvider>();
    final gp = context.watch<GameProvider>();

    // Minhas cartas com pelo menos 1 cópia
    final myCards = gp.allCards
        .where((c) => (gp.ownedCards[c.id] ?? 0) >= 1)
        .toList();

    // Lista de jogadores para trocar
    final players = mp.players
        .where((p) => p.id != mp.myIp)
        .toList();
    if (mp.isHost) {
      // clientes aparecem para o host
    }

    return Scaffold(
      backgroundColor: SC.bg,
      body: Column(
        children: [
          SovietHeader(
            title: '🔄 TROCA DE CARTAS',
            subtitle: 'Negocie com os camaradas via Wi-Fi',
            actions: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('✕',
                      style: TextStyle(color: SC.cream, fontSize: 18)),
                ),
              ),
            ],
          ),

          // Proposta recebida
          if (_incomingTrade != null) _buildIncomingTradePanel(gp),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Escolher jogador ──────────────────────────
                  if (players.isEmpty && !mp.isHost)
                    const _EmptyState(msg: 'Apenas você está conectado.\nAguarde outros jogadores.')
                  else ...[
                    const Text('ESCOLHER CAMARADA',
                        style: TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 12,
                            color: SC.gold,
                            letterSpacing: 2)),
                    const SizedBox(height: 8),
                    if (mp.isHost)
                      ...mp.players.map((p) => _PlayerChip(
                            name: p.name,
                            selected: _targetPlayerId == p.id,
                            onTap: () => setState(() {
                              _targetPlayerId = p.id;
                              _targetPlayerName = p.name;
                            }),
                          ))
                    else
                      _PlayerChip(
                        name: 'HOST',
                        selected: _targetPlayerId == 'host',
                        onTap: () => setState(() {
                          _targetPlayerId = 'host';
                          _targetPlayerName = 'HOST';
                        }),
                      ),

                    const SizedBox(height: 20),

                    // ── Escolher carta ──────────────────────────
                    const Text('CARTA A OFERECER',
                        style: TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 12,
                            color: SC.gold,
                            letterSpacing: 2)),
                    const SizedBox(height: 8),

                    if (myCards.isEmpty)
                      const _EmptyState(msg: 'Você não possui cartas\npara trocar.')
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: myCards.length,
                        itemBuilder: (_, i) {
                          final card = myCards[i];
                          final count = gp.ownedCards[card.id] ?? 0;
                          final selected = _selectedCard?.id == card.id;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCard = selected ? null : card),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected
                                    ? SC.gold.withValues(alpha: 0.2)
                                    : SC.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? SC.gold
                                      : card.rare
                                          ? SC.goldDark
                                          : SC.redDark,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(card.emoji,
                                      style: const TextStyle(fontSize: 28)),
                                  const SizedBox(height: 4),
                                  Text(card.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontFamily: 'Oswald',
                                          fontSize: 11,
                                          color: SC.cream)),
                                  if (card.rare)
                                    const Text('⭐ RARA',
                                        style: TextStyle(
                                            fontFamily: 'Oswald',
                                            fontSize: 9,
                                            color: SC.gold)),
                                  Text('x$count',
                                      style: const TextStyle(
                                          fontFamily: 'Oswald',
                                          fontSize: 10,
                                          color: SC.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // ── Botão enviar ──────────────────────────
                    SovietButton(
                      label: _selectedCard == null || _targetPlayerId == null
                          ? 'Selecione carta e jogador'
                          : '🔄 OFERECER "${_selectedCard!.name}" PARA $_targetPlayerName',
                      onTap: (_selectedCard != null && _targetPlayerId != null)
                          ? _sendTradeRequest
                          : null,
                      bgColor: _selectedCard != null && _targetPlayerId != null
                          ? SC.greenDark
                          : SC.cardDark,
                      borderColor: _selectedCard != null && _targetPlayerId != null
                          ? SC.green
                          : SC.redDark,
                      fontSize: 12,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingTradePanel(GameProvider gp) {
    final trade = _incomingTrade!;
    final fromName = trade['fromName'] as String? ?? 'Jogador';
    final fromId = trade['from'] as String?;
    final offeredCardId = trade['cardId'] as String?;
    final offeredCardName = trade['cardName'] as String? ?? '?';
    final offeredIsRare = trade['isRare'] as bool? ?? false;

    // Minhas cartas disponíveis para trocar de volta
    final myCards =
        gp.allCards.where((c) => (gp.ownedCards[c.id] ?? 0) >= 1).toList();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SC.gold, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📨 PROPOSTA DE $fromName',
              style: const TextStyle(
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: SC.gold)),
          const SizedBox(height: 6),
          Text(
            '$fromName quer dar: ${offeredIsRare ? "⭐" : ""}$offeredCardName',
            style: const TextStyle(
                fontFamily: 'Oswald', fontSize: 13, color: SC.cream),
          ),
          const SizedBox(height: 8),
          const Text('ESCOLHA UMA CARTA SUA PARA DAR EM TROCA:',
              style: TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 11,
                  color: SC.grey,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: myCards.length,
              itemBuilder: (_, i) {
                final card = myCards[i];
                final selected = _myCardForExchange?.id == card.id;
                return GestureDetector(
                  onTap: () => setState(() => _myCardForExchange = card),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? SC.gold.withValues(alpha: 0.2)
                          : SC.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: selected ? SC.gold : SC.redDark,
                          width: selected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(card.emoji, style: const TextStyle(fontSize: 22)),
                        Text(card.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Oswald',
                                fontSize: 9,
                                color: SC.cream)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SovietButton(
                  label: '✅ ACEITAR',
                  onTap: _myCardForExchange != null
                      ? () => _acceptTrade(fromId!, offeredCardId!, offeredIsRare, gp)
                      : null,
                  bgColor: _myCardForExchange != null ? SC.greenDark : SC.cardDark,
                  borderColor: _myCardForExchange != null ? SC.green : SC.grey,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SovietButton(
                  label: '❌ RECUSAR',
                  onTap: () => _declineTrade(fromId!),
                  bgColor: SC.cardDark,
                  borderColor: SC.red,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendTradeRequest() {
    if (_selectedCard == null || _targetPlayerId == null) return;
    final mp = context.read<MpProvider>();
    mp.sendTradeRequest(
      _targetPlayerId!,
      _selectedCard!.id,
      _selectedCard!.name,
      _selectedCard!.rare,
    );
    _showSnack('📨 Proposta enviada para $_targetPlayerName!');
  }

  void _acceptTrade(
      String fromId, String offeredCardId, bool offeredIsRare, GameProvider gp) {
    final mp = context.read<MpProvider>();
    final myCard = _myCardForExchange!;

    // Aplicar troca localmente
    gp.sellCards(myCard.id, 1, 0); // Remove minha carta
    gp.addCard(offeredCardId, offeredIsRare); // Ganha a carta oferecida

    // Notificar o outro jogador
    mp.sendTradeResponse(
      fromId,
      offeredCardId,
      true,
      myCardId: myCard.id,
      myCardName: myCard.name,
      myCardRare: myCard.rare,
    );

    _showSnack('✅ Troca concluída!');
    setState(() {
      _incomingTrade = null;
      _myCardForExchange = null;
    });
  }

  void _declineTrade(String fromId) {
    final mp = context.read<MpProvider>();
    mp.sendTradeResponse(fromId, '', false);
    setState(() {
      _incomingTrade = null;
      _myCardForExchange = null;
    });
    _showSnack('❌ Troca recusada.');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Oswald', color: SC.cream)),
      backgroundColor: SC.card,
      duration: const Duration(seconds: 2),
    ));
  }
}

class _PlayerChip extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _PlayerChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? SC.red.withValues(alpha: 0.2) : SC.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? SC.red : SC.redDark, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(selected ? '✅' : '✊', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(name,
                style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 15,
                    color: selected ? SC.gold : SC.cream,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Oswald', fontSize: 14, color: SC.grey)),
      ),
    );
  }
}
