import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../data/cards_data.dart';
import '../models/card_model.dart';
import '../widgets/soviet_theme.dart';
import '../widgets/card_widget.dart';

const _rareChance = 0.15;
const _singleCost = 5;
const _multiCost = 25;
const _multiCount = 5;

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});
  @override State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _spinAnim;
  double _currentAngle = 0;
  bool _spinning = false;
  List<ComradeCard> _wonCards = [];
  bool _showWin = false;
  String? _error;

  static const _symbols = ['☭','⭐','✊','⚒️','🌟','💎','🔴','👑','🌍','⚡','💪','🎖️'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _spinAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    )..addListener(() {
      setState(() {
        _currentAngle = _spinAnim.value;
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ComradeCard _pickCard() {
    final roll = Random().nextDouble();
    final rares = kAllCards.where((c) => c.rare).toList();
    final commons = kAllCards.where((c) => !c.rare).toList();
    if (roll < _rareChance && rares.isNotEmpty) {
      return rares[Random().nextInt(rares.length)];
    }
    return commons[Random().nextInt(commons.length)];
  }

  Future<void> _doSpin(int count) async {
    final cost = count == 1 ? _singleCost : _multiCost;
    final gp = context.read<GameProvider>();
    if (!gp.spendTickets(cost)) {
      setState(() => _error = 'Tickets insuficientes! Precisa de $cost 🎟️');
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _error = null);
      return;
    }
    setState(() { _spinning = true; _error = null; });

    final rounds = 5 + Random().nextInt(5);
    final extra = Random().nextDouble() * 2 * pi;
    final target = _currentAngle + rounds * 2 * pi + extra;

    _ctrl.duration = const Duration(milliseconds: 2200);
    _spinAnim = Tween<double>(begin: _currentAngle, end: target).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    )..addListener(() => setState(() => _currentAngle = _spinAnim.value));

    _ctrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 2300));

    final won = <ComradeCard>[];
    for (int i = 0; i < count; i++) {
      final card = _pickCard();
      gp.addCard(card.id, card.rare);
      won.add(card);
    }
    setState(() {
      _spinning = false;
      _wonCards = won;
      _showWin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  // Title
                  const Text('ROLETA', style: TextStyle(
                    fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                    fontSize: 34, color: SC.red, letterSpacing: 6,
                  )),
                  const Text('DO CAMARADA', style: TextStyle(
                    fontSize: 12, color: SC.cream, letterSpacing: 4,
                  )),
                  const SizedBox(height: 4),
                  const Text('━━━ ☭ ━━━', style: TextStyle(color: SC.gold, fontSize: 14)),
                  const SizedBox(height: 16),

                  // Wheel
                  _buildWheel(),
                  const SizedBox(height: 16),

                  // Error
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: SC.red.withValues(alpha: 0.15),
                        border: Border.all(color: SC.red),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('⚠️ $_error', textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Oswald', color: Color(0xFFFF6666), fontSize: 13)),
                    ),

                  // Info row
                  Row(
                    children: [
                      _infoCard('Taxa Rara', '~15%'),
                      const SizedBox(width: 12),
                      _infoCard('Saldo', '🎟️ ${gp.tickets}'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Spin buttons
                  _spinButton(
                    icon: '🎰',
                    label: 'GIRAR',
                    cost: _singleCost,
                    detail: '→ 1 carta',
                    enabled: !_spinning && gp.tickets >= _singleCost,
                    onTap: () => _doSpin(1),
                    isMulti: false,
                  ),
                  const SizedBox(height: 10),
                  _spinButton(
                    icon: '🎯',
                    label: 'MEGA GIRO',
                    cost: _multiCost,
                    detail: '→ $_multiCount cartas',
                    enabled: !_spinning && gp.tickets >= _multiCost,
                    onTap: () => _doSpin(_multiCount),
                    isMulti: true,
                  ),
                  const SizedBox(height: 12),

                  // Odds
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SC.card,
                      border: Border.all(color: SC.redDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text('☭ CHANCES DO POVO ☭', style: TextStyle(
                          fontFamily: 'Oswald', fontSize: 11, color: SC.gold, letterSpacing: 2,
                        )),
                        const SizedBox(height: 8),
                        _oddsRow('● Carta Comum', '~85%', SC.cream),
                        _oddsRow('⭐ Carta Rara', '~15%', SC.gold),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Win overlay
            if (_showWin) _buildWinOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel() {
    const double size = 220;
    const int segments = 12;
    return Column(
      children: [
        const Text('▼', style: TextStyle(fontSize: 20, color: SC.gold, shadows: [Shadow(color: SC.gold, blurRadius: 8)])),
        const SizedBox(height: -4),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SC.gold, width: 4),
            boxShadow: [BoxShadow(color: SC.gold.withValues(alpha: 0.3), blurRadius: 16)],
          ),
          child: ClipOval(
            child: Transform.rotate(
              angle: _currentAngle,
              child: CustomPaint(
                size: const Size(size, size),
                painter: _WheelPainter(segments: segments, symbols: _symbols),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SC.card,
        border: Border.all(color: SC.redDark),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Oswald', fontSize: 9, color: SC.grey, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 16, color: SC.gold)),
        ],
      ),
    ),
  );

  Widget _spinButton({
    required String icon,
    required String label,
    required int cost,
    required String detail,
    required bool enabled,
    required VoidCallback onTap,
    required bool isMulti,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMulti ? [const Color(0xFF4A0000), SC.redDark] : [SC.redDark, SC.red],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(color: isMulti ? SC.gold : SC.redLight, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text('$icon ${_spinning ? "⟳ GIRANDO..." : label}', style: const TextStyle(
                fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                fontSize: 20, color: Colors.white, letterSpacing: 2,
              )),
              const SizedBox(height: 4),
              Text('🎟️ $cost tickets $detail', style: const TextStyle(
                fontFamily: 'Oswald', fontSize: 12, color: SC.cream,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _oddsRow(String label, String value, Color valueColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.grey)),
        Text(value, style: TextStyle(fontFamily: 'Oswald', fontSize: 12, color: valueColor, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _buildWinOverlay() {
    final hasRare = _wonCards.any((c) => c.rare);
    return GestureDetector(
      onTap: () => setState(() => _showWin = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SC.bg,
                border: Border.all(
                  color: hasRare ? SC.gold : SC.red,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: (hasRare ? SC.gold : SC.red).withValues(alpha: 0.3),
                  blurRadius: 24,
                )],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasRare ? '⭐ RARO CONQUISTADO! ⭐' : '🎉 CARTAS DO POVO!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                      fontSize: 18, color: hasRare ? SC.gold : SC.cream,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasRare ? 'A burguesia chora!' : 'O partido aprova!',
                    style: const TextStyle(fontSize: 12, color: SC.grey),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _wonCards.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CardDisplay(card: c),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SovietButton(
                    label: '☭ GLORIOSO! ☭',
                    onTap: () => setState(() => _showWin = false),
                    borderColor: hasRare ? SC.gold : SC.redLight,
                    textColor: hasRare ? SC.gold : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for the roulette wheel
class _WheelPainter extends CustomPainter {
  final int segments;
  final List<String> symbols;

  const _WheelPainter({required this.segments, required this.symbols});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angle = 2 * pi / segments;
    final colors = [const Color(0xFF8B0000), const Color(0xFF330000)];

    for (int i = 0; i < segments; i++) {
      final paint = Paint()..color = colors[i % 2];
      final startAngle = i * angle - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, angle, true, paint,
      );
      // Divider lines
      final linePaint = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.3)..strokeWidth = 1;
      final lineEnd = Offset(
        center.dx + radius * cos(startAngle),
        center.dy + radius * sin(startAngle),
      );
      canvas.drawLine(center, lineEnd, linePaint);
      // Symbol text
      final textAngle = startAngle + angle / 2;
      final textR = radius * 0.7;
      final textPos = Offset(
        center.dx + textR * cos(textAngle),
        center.dy + textR * sin(textAngle),
      );
      final tp = TextPainter(
        text: TextSpan(text: symbols[i % symbols.length], style: const TextStyle(fontSize: 16)),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(textPos.dx, textPos.dy);
      canvas.rotate(textAngle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    // Center circle
    canvas.drawCircle(center, 26,
      Paint()..shader = const RadialGradient(
        colors: [Color(0xFFCC0000), Color(0xFF8B0000)],
      ).createShader(Rect.fromCircle(center: center, radius: 26)));
    canvas.drawCircle(center, 26, Paint()..color = SC.gold..style = PaintingStyle.stroke..strokeWidth = 3);
    final tp = TextPainter(
      text: const TextSpan(text: '☭', style: TextStyle(fontSize: 20)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}
