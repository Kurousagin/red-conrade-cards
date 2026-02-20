import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../data/cards_data.dart';

const _kPrefix = 'rcc_v1_';

class GameProvider extends ChangeNotifier {
  int _tickets = 50;
  Map<String, int> _ownedCards = {};
  Set<String> _favorites = {};
  GameStats _stats = const GameStats();
  Set<String> _unlocked = {};
  int _consecutiveDays = 0;
  String? _lastLoginDate;
  int? _loginBonusAmount;
  List<ComradeCard> _allCards = [];
  bool _isLoading = true;

  // ─── Getters ───────────────────────────────────────────────
  int get tickets => _tickets;
  Map<String, int> get ownedCards => Map.unmodifiable(_ownedCards);
  Set<String> get favorites => Set.unmodifiable(_favorites);
  GameStats get stats => _stats;
  Set<String> get unlockedAchievements => Set.unmodifiable(_unlocked);
  int get consecutiveDays => _consecutiveDays;
  int? get loginBonusAmount => _loginBonusAmount;
  bool get isLoading => _isLoading;

  List<ComradeCard> get allCards => _allCards;
  int get ownedCount => _ownedCards.length;
  int get totalCards => _allCards.length;

  // ─── Rank ──────────────────────────────────────────────────
  Map<String, dynamic> get rank {
    final r = _stats.rareCardsCollected;
    if (r >= 25) return {'name': 'LENDÁRIO', 'color': 0xFFFF6600, 'icon': '👑'};
    if (r >= 18) return {'name': 'ÉPICO', 'color': 0xFF9400D3, 'icon': '💜'};
    if (r >= 10) return {'name': 'RARO', 'color': 0xFF0080FF, 'icon': '💙'};
    if (r >= 5) return {'name': 'ESPECIAL', 'color': 0xFF00CC44, 'icon': '💚'};
    return {'name': 'INICIANTE', 'color': 0xFFAAAAAA, 'icon': '🔰'};
  }

  // ─── Init ──────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _tickets = prefs.getInt('${_kPrefix}tickets') ?? 50;
    _consecutiveDays = prefs.getInt('${_kPrefix}days') ?? 0;
    _lastLoginDate = prefs.getString('${_kPrefix}lastLogin');

    final ownedRaw = prefs.getString('${_kPrefix}owned');
    if (ownedRaw != null) {
      final m = json.decode(ownedRaw) as Map<String, dynamic>;
      _ownedCards = m.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    final favsRaw = prefs.getString('${_kPrefix}favs');
    if (favsRaw != null) {
      _favorites = Set<String>.from(json.decode(favsRaw) as List);
    }

    final statsRaw = prefs.getString('${_kPrefix}stats');
    if (statsRaw != null) {
      _stats =
          GameStats.fromJson(json.decode(statsRaw) as Map<String, dynamic>);
    }

    final unlockedRaw = prefs.getString('${_kPrefix}unlocked');
    if (unlockedRaw != null) {
      _unlocked = Set<String>.from(json.decode(unlockedRaw) as List);
    }

    // Fetch cards from remote
    _allCards = await CardService.fetchCards();
    _isLoading = false;

    _applyLoginBonus();
    _checkAchievements();
    notifyListeners();
  }

  // ─── Persist ───────────────────────────────────────────────
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_kPrefix}tickets', _tickets);
    await prefs.setInt('${_kPrefix}days', _consecutiveDays);
    if (_lastLoginDate != null) {
      await prefs.setString('${_kPrefix}lastLogin', _lastLoginDate!);
    }
    await prefs.setString('${_kPrefix}owned', json.encode(_ownedCards));
    await prefs.setString('${_kPrefix}favs', json.encode(_favorites.toList()));
    await prefs.setString('${_kPrefix}stats', json.encode(_stats.toJson()));
    await prefs.setString(
        '${_kPrefix}unlocked', json.encode(_unlocked.toList()));
  }

  // ─── Login bonus ───────────────────────────────────────────
  void _applyLoginBonus() {
    final today = DateTime.now().toLocal().toString().substring(0, 10);
    if (_lastLoginDate == today) return;

    final prev =
        _lastLoginDate != null ? DateTime.tryParse(_lastLoginDate!) : null;
    final now = DateTime.now();
    final consecutive = (prev != null && now.difference(prev).inHours < 48)
        ? _consecutiveDays + 1
        : 1;
    final bonus = (5 + consecutive * 2).clamp(5, 20);

    _tickets += bonus;
    _consecutiveDays = consecutive;
    _lastLoginDate = today;
    _loginBonusAmount = bonus;
  }

  void clearLoginBonus() {
    _loginBonusAmount = null;
    notifyListeners();
  }

  // ─── Tickets ───────────────────────────────────────────────
  bool spendTickets(int amount) {
    if (_tickets < amount) return false;
    _tickets -= amount;
    _save();
    notifyListeners();
    return true;
  }

  void addTickets(int amount) {
    _tickets += amount;
    _checkAchievements();
    _save();
    notifyListeners();
  }

  // ─── Cards ─────────────────────────────────────────────────
  void addCard(String cardId, bool isRare) {
    _ownedCards[cardId] = (_ownedCards[cardId] ?? 0) + 1;
    _stats = _stats.copyWith(
      totalSpins: _stats.totalSpins + 1,
      rareCardsCollected: _stats.rareCardsCollected + (isRare ? 1 : 0),
    );
    _updateAlbumCompletion();
    _checkAchievements();
    _save();
    notifyListeners();
  }

  void sellCards(String cardId, int count, int ticketsEarned) {
    final current = _ownedCards[cardId] ?? 0;
    final newCount = current - count;
    if (newCount <= 0) {
      _ownedCards.remove(cardId);
    } else {
      _ownedCards[cardId] = newCount;
    }
    _tickets += ticketsEarned;
    _stats = _stats.copyWith(cardsSold: _stats.cardsSold + count);
    _checkAchievements();
    _save();
    notifyListeners();
  }

  void _updateAlbumCompletion() {
    final pct = totalCards > 0
        ? ((ownedCount / totalCards) * 100).round().clamp(0, 100)
        : 0;
    _stats = _stats.copyWith(albumCompletion: pct);
  }

  // ─── Favorites ─────────────────────────────────────────────
  void toggleFavorite(String cardId) {
    if (_favorites.contains(cardId)) {
      _favorites.remove(cardId);
    } else {
      _favorites.add(cardId);
    }
    _save();
    notifyListeners();
  }

  void clearFavorites() {
    _favorites.clear();
    _save();
    notifyListeners();
  }

  // ─── Games ─────────────────────────────────────────────────
  void recordGameWin() {
    _stats = _stats.copyWith(gamesWon: _stats.gamesWon + 1);
    _tickets += 1;
    _checkAchievements();
    _save();
    notifyListeners();
  }

  // ─── Achievements ──────────────────────────────────────────
  static const achievements = [
    ('first_spin', '☭ Primeira Rodada', 'Faça seu primeiro giro', '🎰'),
    ('spin_10', 'Veterano do Povo', '10 giros realizados', '🌟'),
    ('spin_100', 'Camarada Dedicado', '100 giros realizados', '⭐'),
    ('rare_1', 'Achei um Raro!', 'Colete 1 carta rara', '💎'),
    ('rare_10', 'Colecionador Soviético', 'Colete 10 cartas raras', '👑'),
    ('rare_25', 'Lenda do Gulag', 'Colete 25 cartas raras', '🏆'),
    ('games_5', 'Operário do Jogo', 'Vença 5 mini-jogos', '🎮'),
    ('games_20', 'Campeão do Soviete', 'Vença 20 mini-jogos', '🥇'),
    ('sell_first', 'Mercado Negro', 'Venda sua primeira carta', '💰'),
    ('album_50', 'Meio Caminho', 'Complete 50% do álbum', '📚'),
    ('album_100', 'Álbum Completo!', 'Complete 100% do álbum', '🏅'),
    ('rich', 'Burguês Disfarçado', 'Tenha 100 tickets', '🎟️'),
  ];

  void _checkAchievements() {
    bool changed = false;
    for (final (id, _, _, _) in achievements) {
      if (_unlocked.contains(id)) continue;
      if (_shouldUnlock(id)) {
        _unlocked.add(id);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  bool _shouldUnlock(String id) {
    return switch (id) {
      'first_spin' => _stats.totalSpins >= 1,
      'spin_10' => _stats.totalSpins >= 10,
      'spin_100' => _stats.totalSpins >= 100,
      'rare_1' => _stats.rareCardsCollected >= 1,
      'rare_10' => _stats.rareCardsCollected >= 10,
      'rare_25' => _stats.rareCardsCollected >= 25,
      'games_5' => _stats.gamesWon >= 5,
      'games_20' => _stats.gamesWon >= 20,
      'sell_first' => _stats.cardsSold >= 1,
      'album_50' => _stats.albumCompletion >= 50,
      'album_100' => _stats.albumCompletion >= 100,
      'rich' => _tickets >= 100,
      _ => false,
    };
  }
}
