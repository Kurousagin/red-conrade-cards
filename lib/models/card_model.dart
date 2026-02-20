class ComradeCard {
  final String id;
  final String name;
  final String desc;
  final bool rare;
  final String? imageUrl;
  final String emoji;
  final int colorSeed;

  const ComradeCard({
    required this.id,
    required this.name,
    required this.desc,
    required this.rare,
    this.imageUrl,
    required this.emoji,
    required this.colorSeed,
  });

  factory ComradeCard.fromJson(Map<String, dynamic> json, int index) {
    final isRare = json['rare'] == true || index % 5 == 0;
    return ComradeCard(
      id: 'card_${json['id'] ?? index}',
      name: json['name'] ?? 'Camarada #${json['id'] ?? index}',
      desc: json['desc'] ?? json['author'] ?? 'Herói do proletariado',
      rare: isRare,
      imageUrl: json['src'] as String?,
      emoji: isRare ? '⭐' : _emojis[index % _emojis.length],
      colorSeed: index,
    );
  }

  static const _emojis = [
    '☭', '✊', '⚒️', '🔴', '🌟', '🚂', '🏭', '📢',
    '📜', '💪', '🌍', '⚡', '🎖️', '🛡️', '👊', '🏅',
  ];
}

class AchievementDef {
  final String id;
  final String label;
  final String desc;
  final String icon;
  final bool Function(GameStats stats, int tickets) check;

  const AchievementDef({
    required this.id,
    required this.label,
    required this.desc,
    required this.icon,
    required this.check,
  });
}

class GameStats {
  final int totalSpins;
  final int rareCardsCollected;
  final int albumCompletion;
  final int gamesWon;
  final int cardsSold;

  const GameStats({
    this.totalSpins = 0,
    this.rareCardsCollected = 0,
    this.albumCompletion = 0,
    this.gamesWon = 0,
    this.cardsSold = 0,
  });

  GameStats copyWith({
    int? totalSpins,
    int? rareCardsCollected,
    int? albumCompletion,
    int? gamesWon,
    int? cardsSold,
  }) {
    return GameStats(
      totalSpins: totalSpins ?? this.totalSpins,
      rareCardsCollected: rareCardsCollected ?? this.rareCardsCollected,
      albumCompletion: albumCompletion ?? this.albumCompletion,
      gamesWon: gamesWon ?? this.gamesWon,
      cardsSold: cardsSold ?? this.cardsSold,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalSpins': totalSpins,
    'rareCardsCollected': rareCardsCollected,
    'albumCompletion': albumCompletion,
    'gamesWon': gamesWon,
    'cardsSold': cardsSold,
  };

  factory GameStats.fromJson(Map<String, dynamic> j) => GameStats(
    totalSpins: (j['totalSpins'] as num?)?.toInt() ?? 0,
    rareCardsCollected: (j['rareCardsCollected'] as num?)?.toInt() ?? 0,
    albumCompletion: (j['albumCompletion'] as num?)?.toInt() ?? 0,
    gamesWon: (j['gamesWon'] as num?)?.toInt() ?? 0,
    cardsSold: (j['cardsSold'] as num?)?.toInt() ?? 0,
  );
}
