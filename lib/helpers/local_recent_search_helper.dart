import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalRecentSearchHelper {
  static const String _key = 'recent_searches_local';
  static const int _maxItems = 20;

  Future<List<Map<String, dynamic>>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSearch(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getRecentSearches();

    // Check for duplicates
    final index = items.indexWhere((element) {
      if (element['content_type'] == item['content_type']) {
        if (element['content_type'] == 'keyword' && element['keyword'] == item['keyword']) {
          return true;
        }
        if (element['content_id'] != null && element['content_id'] == item['content_id']) {
          return true;
        }
      }
      return false;
    });

    if (index >= 0) {
      // Remove the existing item so we can move it to the top
      items.removeAt(index);
    }

    // Add new item to the top
    items.insert(0, item);

    // Enforce limit
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }

    await prefs.setString(_key, jsonEncode(items));
  }

  Future<void> removeSearch(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getRecentSearches();

    items.removeWhere((element) {
      if (element['content_type'] == item['content_type']) {
        if (element['content_type'] == 'keyword' && element['keyword'] == item['keyword']) {
          return true;
        }
        if (element['content_id'] != null && element['content_id'] == item['content_id']) {
          return true;
        }
      }
      return false;
    });

    await prefs.setString(_key, jsonEncode(items));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
