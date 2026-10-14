/// One ayah currently on screen.
class AyahRef {
  const AyahRef(this.surah, this.ayah);

  final int surah;
  final int ayah;

  @override
  bool operator ==(Object other) {
    return other is AyahRef && other.surah == surah && other.ayah == ayah;
  }

  @override
  int get hashCode => Object.hash(surah, ayah);
}

/// Counts an ayah only after it stays visible. A jump resets the timer.
class AyahDwell {
  static const threshold = Duration(seconds: 2);

  AyahRef? _current;
  DateTime? _since;
  bool _counted = false;

  AyahRef? onVisible(AyahRef ayah, DateTime now) {
    if (_current != ayah) {
      _current = ayah;
      _since = now;
      _counted = false;
      return null;
    }
    if (_counted || _since == null) return null;
    if (now.difference(_since!) < threshold) return null;
    _counted = true;
    return ayah;
  }
}
