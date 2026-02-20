import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';

const _cardsUrl = 'https://kurousagin.github.io/rollet-images/card.json';
const _cacheKey = 'rcc_v1_cards_cache';

class CardService {
  static List<ComradeCard>? _cached;

  static Future<List<ComradeCard>> fetchCards() async {
    if (_cached != null) return _cached!;

    // Try fetching from network
    try {
      final response = await http.get(Uri.parse(_cardsUrl)).timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        _cached = [
          for (int i = 0; i < list.length; i++)
            ComradeCard.fromJson(list[i] as Map<String, dynamic>, i),
        ];
        // Save to local cache for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, response.body);
        return _cached!;
      }
    } catch (_) {
      // Network failed, try local cache
    }

    // Fallback: load from local cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      final list = json.decode(cached) as List;
      _cached = [
        for (int i = 0; i < list.length; i++)
          ComradeCard.fromJson(list[i] as Map<String, dynamic>, i),
      ];
      return _cached!;
    }

    // No cache available - return empty list
    return [];
  }
}
