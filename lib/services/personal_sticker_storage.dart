import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album_models.dart';

bool isPersonalSticker(String content) => content.startsWith('albumium_user:');
String personalSticker(String path, double aspect) =>
    'albumium_user:$aspect:${Uri.encodeComponent(path)}';
String personalStickerPath(String content) =>
    Uri.decodeComponent(content.substring(content.indexOf(':', 14) + 1));
double personalStickerAspect(String content) =>
    double.tryParse(content.split(':')[1])?.clamp(.05, 20) ?? 1;
String relocatePersonalSticker(String content, String path) =>
    personalSticker(path, personalStickerAspect(content));

/// Whether the element is a sticker the user cut from their own photo.
///
/// Such a sticker keeps its file reference in [AlbumElementModel.content], the
/// same field that holds an ornament id, so anything that would replace the
/// content has to leave these alone.
bool isPersonalStickerElement(AlbumElementModel element) =>
    element.type == AlbumElementType.sticker &&
    isPersonalSticker(element.content);

class PersonalSticker {
  const PersonalSticker(this.id, this.name, this.content);
  final String id, name, content;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'content': content};
}

class PersonalStickerStorage {
  static const key = 'albumium.personal_stickers.v1';
  static Future<void> _writes = Future.value();
  static Future<List<PersonalSticker>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map(
          (e) => PersonalSticker(
            e['id'] as String,
            e['name'] as String,
            e['content'] as String,
          ),
        )
        .toList();
  }

  static Future<void> _change(void Function(List<PersonalSticker>) change) {
    final result = _writes.then((_) async {
      final all = await load();
      change(all);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
        key,
        jsonEncode(all.map((s) => s.toJson()).toList()),
      )) {
        throw StateError('Sticker save failed');
      }
    });
    _writes = result.catchError((Object _) {});
    return result;
  }

  static Future<PersonalSticker> save(
    Uint8List png,
    double aspect,
    String name,
  ) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = await Directory(
      '${root.path}/albumium_stickers',
    ).create(recursive: true);
    final id = newId();
    final file = File('${dir.path}/$id.png');
    await file.writeAsBytes(png, flush: true);
    final sticker = PersonalSticker(
      id,
      name,
      personalSticker(file.path, aspect),
    );
    await _change((all) => all.insert(0, sticker));
    return sticker;
  }

  // Files remain valid for existing projects and saved templates.
  static Future<void> delete(String id) =>
      _change((all) => all.removeWhere((s) => s.id == id));
  static Future<void> rename(PersonalSticker sticker, String name) =>
      _change((all) {
        final index = all.indexWhere((s) => s.id == sticker.id);
        if (index >= 0) {
          all[index] = PersonalSticker(sticker.id, name, sticker.content);
        }
      });
}
