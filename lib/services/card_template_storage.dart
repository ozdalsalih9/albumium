import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album_models.dart';

AlbumModel cloneCard(AlbumModel source) {
  final json = jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>;
  json['id'] = newId();
  json.remove('importFingerprint');
  json['createdAt'] = DateTime.now().toIso8601String();
  json['updatedAt'] = json['createdAt'];
  for (final page in json['pages'] as List) {
    page['id'] = newId();
    for (final element in page['elements'] as List) {
      final old = element['id'] as String;
      // Semantic text roles survive, while each instance receives new identities.
      final role = [
        'card-title-',
        'card-message-',
        'card-badge-',
      ].where(old.startsWith);
      element['id'] = '${role.isEmpty ? '' : role.first}${newId()}';
    }
  }
  return AlbumModel.fromJson(json);
}

class CardTemplateStorage {
  static const key = 'albumium.card_templates.v1';
  static Future<void> _writes = Future.value();
  static Future<List<AlbumModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => AlbumModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> _change(void Function(List<AlbumModel>) change) {
    final result = _writes.then((_) async {
      final cards = await load();
      change(cards);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
        key,
        jsonEncode(cards.map((c) => c.toJson()).toList()),
      )) {
        throw StateError('Template save failed');
      }
    });
    _writes = result.catchError((Object _) {});
    return result;
  }

  static Future<void> save(AlbumModel card) {
    final copy = cloneCard(card);
    return _change((cards) => cards.insert(0, copy));
  }

  static Future<void> delete(String id) =>
      _change((cards) => cards.removeWhere((c) => c.id == id));
}
