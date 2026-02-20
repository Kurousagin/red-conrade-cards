import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'multiplayer/mp_provider.dart';
import 'widgets/soviet_theme.dart';
import 'screens/deck_screen.dart';
import 'screens/roulette_screen.dart';
import 'screens/games_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/achievements_screen.dart';
import 'multiplayer/mp_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: SC.redDark,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const RedComradeCardsApp());
}

class RedComradeCardsApp extends StatelessWidget {
  const RedComradeCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()..init()),
        ChangeNotifierProvider(create: (_) => MpProvider()),
      ],
      child: MaterialApp(
        title: 'Red Comrade Cards ☭',
        debugShowCheckedModeBanner: false,
        theme: sovietTheme(),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 1; // Start on Roulette
  bool _bonusShown = false;

  // Screens agora incluem Multiplayer (índice 6)
  static const List<Widget> _screens = [
    DeckScreen(),
    RouletteScreen(),
    GamesScreen(),
    ShopScreen(),
    FavoritesScreen(),
    AchievementsScreen(),
    MpScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();

    // Loading screen while cards are being fetched
    if (gp.isLoading) {
      return const Scaffold(
        backgroundColor: SC.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('☭',
                  style: TextStyle(
                      fontSize: 64,
                      shadows: [Shadow(color: SC.gold, blurRadius: 16)])),
              SizedBox(height: 20),
              Text('RED COMRADE CARDS',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: SC.gold,
                    letterSpacing: 4,
                  )),
              SizedBox(height: 8),
              Text('Carregando cartas do povo...',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 13,
                    color: SC.cream,
                  )),
              SizedBox(height: 24),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(SC.red),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Login bonus toast
    if (!_bonusShown && gp.loginBonusAmount != null) {
      _bonusShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginBonus(gp.loginBonusAmount!, gp.consecutiveDays);
        gp.clearLoginBonus();
      });
    }

    final rank = gp.rank;

    return Scaffold(
      backgroundColor: SC.bg,
      body: Column(
        children: [
          // ── Top Bar ─────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [SC.redDark, SC.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: SC.gold, width: 3)),
              ),
              child: Row(
                children: [
                  // Logo
                  const Text('☭',
                      style: TextStyle(
                        fontSize: 28,
                        shadows: [Shadow(color: SC.gold, blurRadius: 8)],
                      )),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RED COMRADE',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: SC.gold,
                            letterSpacing: 2,
                          )),
                      Text('CARDS',
                          style: TextStyle(
                            fontSize: 11,
                            color: SC.cream,
                            letterSpacing: 4,
                          )),
                    ],
                  ),
                  const Spacer(),
                  // Rank badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(rank['icon'] as String,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 3),
                        Text(rank['name'] as String,
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              color: Color(rank['color'] as int),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tickets
                  TicketBadge(amount: gp.tickets),
                ],
              ),
            ),
          ),
          // ── Screen Content ───────────────────────────────────────
          Expanded(child: _screens[_tab]),
          // ── Bottom Nav ──────────────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: SC.cardDark,
                border: Border(top: BorderSide(color: SC.redDark, width: 2)),
              ),
              child: Row(
                children: [
                  _navItem(0, '📋', 'Álbum'),
                  _navItem(1, '🎰', 'Roleta'),
                  _navItem(2, '🎮', 'Jogos'),
                  _navItem(3, '💰', 'Mercado'),
                  _navItem(4, '❤️', 'Favoritos'),
                  _navItem(5, '🏆', 'Troféus'),
                  _navItem(6, '📡', 'Multi'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, String icon, String label) {
    final active = _tab == index;
    final isMp = index == 6;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? (isMp
                    ? SC.greenDark.withValues(alpha: 0.2)
                    : SC.red.withValues(alpha: 0.15))
                : Colors.transparent,
            border: Border(
                top: BorderSide(
              color: active
                  ? (isMp ? SC.green : SC.red)
                  : Colors.transparent,
              width: 2,
            )),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? (isMp ? SC.green : SC.gold)
                        : const Color(0xFF666666),
                    letterSpacing: 0.3,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginBonus(int amount, int days) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SC.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SC.gold, width: 2),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '☭ BOM DIA, CAMARADA! ☭',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: SC.gold,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            Text(
              'Bônus diário: +$amount 🎟️ tickets',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Oswald', fontSize: 13, color: SC.cream),
            ),
            if (days > 1)
              Text(
                '🔥 $days dias seguidos!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Oswald', fontSize: 11, color: SC.gold),
              ),
          ],
        ),
      ),
    );
  }
}
