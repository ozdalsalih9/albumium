enum MemoryKind { weekend, month, year }

class MemoryPeriod {
  const MemoryPeriod(this.kind, this.date);
  final MemoryKind kind;
  final DateTime date;
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
    MemoryKind.weekend => 'Hafta sonun nasıl geçti?',
    MemoryKind.month => 'Bu ay neler yaptın?',
    MemoryKind.year => 'Bu yıldan neler hatırlamak istersin?',
  };
  String title(bool english) => switch (kind) {
    MemoryKind.weekend =>
      '${english ? 'Weekend' : 'Hafta sonu'} · ${date.day}.${date.month}.${date.year}',
    MemoryKind.month =>
      '${english ? 'My month' : 'Benim ayım'} · ${date.month}/${date.year}',
    MemoryKind.year => '${date.year} · ${english ? 'My year' : 'Benim yılım'}',
  };
}
