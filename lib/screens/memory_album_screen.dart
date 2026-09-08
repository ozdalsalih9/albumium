import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../models/memory_period.dart';
import '../services/album_storage.dart';
import '../services/photo_selection_service.dart';
import '../services/reminder_service.dart';

AlbumModel buildMemoryAlbum(
  MemoryPeriod period,
  List<String> photos,
  String note, {
  bool english = false,
}) {
  if (photos.isEmpty || photos.length > 20) {
    throw ArgumentError('Select 1–20 photos');
  }
  final now = DateTime.now();
  return AlbumModel(
    id: newId(),
    title: period.title(english),
    themeId: 'minimal_editorial',
    createdAt: now,
    updatedAt: now,
    memoryPeriod: period.key,
    coverPhotoPath: photos.first,
    pages: [
      for (var i = 0; i < photos.length; i += 2)
        AlbumPageModel(
          id: newId(),
          backgroundColor: 0xFFFFFBF3,
          elements: [
            for (var j = i; j < photos.length && j < i + 2; j++)
              AlbumElementModel(
                id: newId(),
                type: AlbumElementType.photo,
                content: photos[j],
                x: .1,
                y: j == i ? .06 : .49,
                width: .8,
                height: .37,
                frameStyle: 1,
              ),
            if (i == 0 && note.trim().isNotEmpty)
              AlbumElementModel(
                id: newId(),
                type: AlbumElementType.text,
                content: note.trim(),
                x: .1,
                y: .88,
                width: .8,
                height: .09,
                fontSize: 15,
              ),
          ],
        ),
    ],
  );
}

class MemoryAlbumScreen extends StatefulWidget {
  const MemoryAlbumScreen({super.key, required this.period});
  final MemoryPeriod period;
  @override
  State<MemoryAlbumScreen> createState() => _MemoryAlbumScreenState();
}

class _MemoryAlbumScreenState extends State<MemoryAlbumScreen> {
  final _photos = <XFile>[];
  final _note = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final files = await PhotoSelectionService.pick(context, multiple: true);
    if (mounted) {
      setState(() => _photos.addAll(files.take(20 - _photos.length)));
    }
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    final copied = <String>[];
    try {
      final english = Localizations.localeOf(context).languageCode == 'en';
      for (final photo in _photos) {
        copied.add(await AlbumStorage.instance.importImage(photo));
      }
      final album = buildMemoryAlbum(
        widget.period,
        copied,
        _note.text,
        english: english,
      );
      await AlbumStorage.instance.saveAlbum(album);
      if (mounted) Navigator.pop(context, album);
    } catch (_) {
      // Keep any completed media copies: a storage failure may happen after a write.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Kaydedilemedi. Tekrar dene.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(context.tr(widget.period.prompt))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr(
                    'İlk fotoğraf kapağın olacak. Sürükleyerek sırala.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  enabled: !_busy,
                  maxLength: 160,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: context.tr(
                      'Bir cümleyle hatırla (isteğe bağlı)',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || _photos.length >= 20 ? null : _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    '${context.tr('Fotoğraf seç')} · ${_photos.length}/20',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _photos.length,
              onReorder: (oldIndex, newIndex) {
                if (_busy) return;
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  _photos.insert(newIndex, _photos.removeAt(oldIndex));
                });
              },
              itemBuilder: (context, i) => ListTile(
                key: ObjectKey(_photos[i]),
                leading: Image.file(
                  File(_photos[i].path),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
                title: Text(
                  '${i + 1}${i == 0 ? ' · ${context.tr('Kapak')}' : ''}',
                ),
                trailing: IconButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _photos.removeAt(i)),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _busy || _photos.isEmpty ? null : _create,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(context.tr('Albüm taslağını oluştur')),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showReminderSettings(BuildContext context) async {
  final values = await ReminderService.settings();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      var busy = false;
      return StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('Anı hatırlatmaları'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SwitchListTile(
                    title: Text(context.tr('Hatırlatmaları aç')),
                    value: values['enabled'] as bool,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => values['enabled'] = v),
                  ),
                  for (final kind in MemoryKind.values)
                    SwitchListTile(
                      title: Text(
                        context.tr(switch (kind) {
                          MemoryKind.weekend => 'Hafta sonu',
                          MemoryKind.month => 'Ay sonu',
                          MemoryKind.year => 'Yıl sonu',
                        }),
                      ),
                      value: values[kind.name] as bool,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => values[kind.name] = v),
                    ),
                  ListTile(
                    title: Text(context.tr('Hatırlatma saati')),
                    trailing: Text(
                      TimeOfDay(
                        hour: values['hour'] as int,
                        minute: values['minute'] as int,
                      ).format(context),
                    ),
                    onTap: busy
                        ? null
                        : () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: values['hour'] as int,
                                minute: values['minute'] as int,
                              ),
                            );
                            if (time != null && context.mounted) {
                              setState(() {
                                values['hour'] = time.hour;
                                values['minute'] = time.minute;
                              });
                            }
                          },
                  ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() => busy = true);
                            try {
                              final allowed = await ReminderService.save(
                                values,
                                Localizations.localeOf(context).languageCode,
                                requestPermission: values['enabled'] == true,
                              );
                              if (!context.mounted) return;
                              if (!allowed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr(
                                        'Bildirim izni kapalı. Anılarını uygulamadan oluşturabilirsin.',
                                      ),
                                    ),
                                  ),
                                );
                              }
                              Navigator.pop(context);
                            } catch (_) {
                              if (context.mounted) {
                                setState(() => busy = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr('Kaydedilemedi. Tekrar dene.'),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: Text(context.tr('Kaydet')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
