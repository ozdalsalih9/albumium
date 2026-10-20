import 'dart:convert';
import 'album_models.dart';

/// Only editable card state is restored; identity and storage metadata survive.
class CardDesignHistory {
  CardDesignHistory(AlbumModel card) {
    record(card);
  }
  final List<String> _states = [];
  int _cursor = -1;
  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _states.length - 1;

  void record(AlbumModel card) {
    final state = jsonEncode({
      'title': card.title,
      'cardThemeId': card.cardThemeId,
      'cardArtworkVisible': card.cardArtworkVisible,
      'pages': card.pages.map((p) => p.toJson()).toList(),
    });
    if (_cursor >= 0 && _states[_cursor] == state) return;
    _states.removeRange(_cursor + 1, _states.length);
    _states.add(state);
    if (_states.length > 60) _states.removeAt(0);
    _cursor = _states.length - 1;
  }

  void undo(AlbumModel card) {
    if (canUndo) _restore(card, --_cursor);
  }

  void redo(AlbumModel card) {
    if (canRedo) _restore(card, ++_cursor);
  }

  void _restore(AlbumModel card, int index) {
    final data = jsonDecode(_states[index]) as Map<String, dynamic>;
    card.title = data['title'] as String;
    card.cardThemeId = data['cardThemeId'] as String;
    card.cardArtworkVisible = data['cardArtworkVisible'] as bool;
    card.pages
      ..clear()
      ..addAll(
        (data['pages'] as List).map(
          (p) => AlbumPageModel.fromJson(Map<String, dynamic>.from(p as Map)),
        ),
      );
  }
}
