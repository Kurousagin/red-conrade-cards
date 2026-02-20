import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/soviet_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final unlocked = gp.unlockedAchievements.length;
    final total = GameProvider.achievements.length;
    final pct = total > 0 ? unlocked / total : 0.0;

    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [SC.redDark, Color(0xFF4A0000)]),
                border: Border(bottom: BorderSide(color: SC.redDark, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏆 CONQUISTAS DO POVO 🏆', style: TextStyle(
                    fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                    fontSize: 16, color: SC.gold, letterSpacing: 2,
                  )),
                  const SizedBox(height: 4),
                  Text('$unlocked/$total conquistas desbloqueadas', style: const TextStyle(fontSize: 11, color: SC.cream)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: SC.cardDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(SC.gold),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: SC.cardDark,
              child: Row(
                children: [
                  _stat('🎰', '${gp.stats.totalSpins}', 'Giros'),
                  _stat('⭐', '${gp.stats.rareCardsCollected}', 'Raras'),
                  _stat('📋', '${gp.stats.albumCompletion}%', 'Álbum'),
                  _stat('🎮', '${gp.stats.gamesWon}', 'Jogos'),
                ],
              ),
            ),
            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: GameProvider.achievements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final (id, label, desc, icon) = GameProvider.achievements[i];
                  final isUnlocked = gp.unlockedAchievements.contains(id);
                  return _AchievementTile(
                    id: id,
                    label: label,
                    desc: desc,
                    icon: icon,
                    isUnlocked: isUnlocked,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: SC.card,
        border: Border.all(color: const Color(0xFF330000)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700, fontSize: 16, color: SC.red)),
          Text(label, style: const TextStyle(fontFamily: 'Oswald', fontSize: 8, color: SC.grey, letterSpacing: 0.5)),
        ],
      ),
    ),
  );
}

class _AchievementTile extends StatelessWidget {
  final String id, label, desc, icon;
  final bool isUnlocked;

  const _AchievementTile({
    required this.id,
    required this.label,
    required this.desc,
    required this.icon,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isUnlocked ? 1.0 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked ? SC.card : SC.cardDark,
          border: Border.all(
            color: isUnlocked ? SC.gold : const Color(0xFF1A0000),
            width: isUnlocked ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isUnlocked
              ? [BoxShadow(color: SC.gold.withValues(alpha: 0.1), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? const LinearGradient(colors: [SC.redDark, SC.red])
                    : null,
                color: isUnlocked ? null : const Color(0xFF1A1A1A),
                border: Border.all(color: isUnlocked ? SC.gold : const Color(0xFF333333), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  isUnlocked ? icon : '🔒',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                    fontSize: 13, color: isUnlocked ? SC.gold : const Color(0xFF555555),
                    letterSpacing: 0.5,
                  )),
                  const SizedBox(height: 3),
                  Text(desc, style: TextStyle(
                    fontSize: 11,
                    color: isUnlocked ? SC.cream : const Color(0xFF444444),
                  )),
                ],
              ),
            ),
            if (isUnlocked)
              const Text('✓', style: TextStyle(
                color: SC.green, fontSize: 20, fontWeight: FontWeight.w700,
              )),
          ],
        ),
      ),
    );
  }
}
