import 'package:flutter/material.dart';

// ── Soviet Color Palette ───────────────────────────────────────
class SC {
  static const bg        = Color(0xFF1A0000);
  static const card      = Color(0xFF2D0000);
  static const cardDark  = Color(0xFF0D0000);
  static const red       = Color(0xFFCC0000);
  static const redDark   = Color(0xFF8B0000);
  static const redLight  = Color(0xFFFF3333);
  static const gold      = Color(0xFFFFD700);
  static const goldDark  = Color(0xFFB8860B);
  static const cream     = Color(0xFFF5E6C8);
  static const grey      = Color(0xFF888888);
  static const darkGrey  = Color(0xFF333333);
  static const green     = Color(0xFF00FF66);
  static const greenDark = Color(0xFF00CC44);
}

// ── Theme ─────────────────────────────────────────────────────
ThemeData sovietTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: SC.bg,
  colorScheme: const ColorScheme.dark(
    primary: SC.red,
    secondary: SC.gold,
    surface: SC.card,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: SC.cream,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: SC.redDark,
    foregroundColor: SC.gold,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Oswald',
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: SC.gold,
      letterSpacing: 2,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0D0000),
    selectedItemColor: SC.gold,
    unselectedItemColor: SC.darkGrey,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
    unselectedLabelStyle: TextStyle(fontSize: 9),
    elevation: 0,
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: SC.gold,
    unselectedLabelColor: SC.grey,
    indicatorColor: SC.red,
  ),
  cardTheme: CardThemeData(
    color: SC.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: SC.redDark, width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SC.red,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        fontFamily: 'Oswald',
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, color: SC.gold, letterSpacing: 2),
    headlineMedium: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, color: SC.cream),
    bodyLarge: TextStyle(fontFamily: 'Oswald', color: SC.cream),
    bodyMedium: TextStyle(fontFamily: 'Oswald', color: SC.grey),
    labelSmall: TextStyle(fontFamily: 'Oswald', color: SC.grey, letterSpacing: 1),
  ),
);

// ── Reusable Widgets ──────────────────────────────────────────

class SovietHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const SovietHeader({super.key, required this.title, this.subtitle, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(title, style: const TextStyle(
                  fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                  fontSize: 16, color: SC.gold, letterSpacing: 2,
                )),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(
                    fontSize: 11, color: SC.cream,
                  )),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class SovietButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsets? padding;

  const SovietButton({
    super.key,
    required this.label,
    this.onTap,
    this.bgColor = SC.red,
    this.borderColor = SC.redLight,
    this.textColor = Colors.white,
    this.fontSize = 15,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [SC.redDark, bgColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [BoxShadow(color: bgColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          fontFamily: 'Oswald', fontWeight: FontWeight.w700,
          fontSize: fontSize, color: textColor, letterSpacing: 1.5,
        )),
      ),
    );
  }
}

class TicketBadge extends StatelessWidget {
  final int amount;
  const TicketBadge({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SC.gold.withValues(alpha: 0.15),
        border: Border.all(color: SC.gold, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎟️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$amount', style: const TextStyle(
            fontFamily: 'Oswald', fontWeight: FontWeight.w700,
            fontSize: 16, color: SC.gold,
          )),
        ],
      ),
    );
  }
}

class SovietDivider extends StatelessWidget {
  final String? label;
  const SovietDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: SC.redDark)),
          if (label != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('☭ $label ☭', style: const TextStyle(color: SC.gold, fontSize: 11, letterSpacing: 2)),
          ),
          Expanded(child: Container(height: 1, color: SC.redDark)),
        ],
      ),
    );
  }
}

class WinDialog extends StatelessWidget {
  final String title;
  final String message;
  final String reward;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const WinDialog({
    super.key,
    required this.title,
    required this.message,
    required this.reward,
    required this.onPlayAgain,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SC.bg,
          border: Border.all(color: SC.gold, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: SC.gold.withValues(alpha: 0.2), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(
              fontFamily: 'Oswald', fontWeight: FontWeight.w700,
              fontSize: 22, color: SC.gold, letterSpacing: 2,
            )),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(
              fontSize: 13, color: SC.cream,
            )),
            const SizedBox(height: 10),
            Text(reward, style: const TextStyle(
              fontFamily: 'Oswald', fontWeight: FontWeight.w700,
              fontSize: 18, color: SC.green,
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: SovietButton(
                  label: 'JOGAR DE NOVO',
                  onTap: onPlayAgain,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                )),
                const SizedBox(width: 8),
                Expanded(child: SovietButton(
                  label: 'MENU',
                  onTap: onMenu,
                  bgColor: SC.cardDark,
                  borderColor: SC.redDark,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoseDialog extends StatelessWidget {
  final String message;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const LoseDialog({
    super.key,
    required this.message,
    required this.onPlayAgain,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SC.bg,
          border: Border.all(color: SC.red, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💀', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text('REPROVADO!', style: TextStyle(
              fontFamily: 'Oswald', fontWeight: FontWeight.w700,
              fontSize: 22, color: SC.red, letterSpacing: 2,
            )),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(
              fontSize: 13, color: SC.cream,
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: SovietButton(
                  label: 'TENTAR NOVAMENTE',
                  onTap: onPlayAgain,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                )),
                const SizedBox(width: 8),
                Expanded(child: SovietButton(
                  label: 'MENU',
                  onTap: onMenu,
                  bgColor: SC.cardDark,
                  borderColor: SC.redDark,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
