enum MemoryKind { weekend, month, year }

class MemoryPeriod {
  const MemoryPeriod(this.kind, this.date);
  final MemoryKind kind;
  final DateTime date;
  static MemoryPeriod? fromKey(String? key) {
    final match = RegExp(
      r'^(weekend|month|year):(\d{4})-(\d{1,2})-(\d{1,2})$',
    ).firstMatch(key ?? '');
    if (match == null) return null;
    final year = int.parse(match[2]!),
        month = int.parse(match[3]!),
        day = int.parse(match[4]!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return MemoryPeriod(MemoryKind.values.byName(match[1]!), date);
  }

  static MemoryPeriod current(MemoryKind kind, DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    return MemoryPeriod(kind, switch (kind) {
      MemoryKind.weekend => day.subtract(Duration(days: day.weekday % 7)),
      MemoryKind.month => DateTime(day.year, day.month),
      MemoryKind.year => DateTime(day.year),
    });
  }

  String get key => '${kind.name}:${date.year}-${date.month}-${date.day}';
  String get prompt => switch (kind) {
    MemoryKind.weekend => 'Bu hafta aklında ne kaldı?',
    MemoryKind.month => 'Bu ay neler yaptın?',
    MemoryKind.year => 'Bu yıldan neler hatırlamak istersin?',
  };
  String title(bool english) => switch (kind) {
    MemoryKind.weekend =>
      '${english ? 'My week' : 'Haftam'} · ${date.day}.${date.month}.${date.year}',
    MemoryKind.month =>
      '${english ? 'My month' : 'Benim ayım'} · ${date.month}/${date.year}',
    MemoryKind.year => '${date.year} · ${english ? 'My year' : 'Benim yılım'}',
  };
}
