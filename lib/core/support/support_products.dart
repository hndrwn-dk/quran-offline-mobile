/// Consumable Play product ids. Prices come from Play, never from these ids.
class SupportProducts {
  SupportProducts._();

  static const coffee = 'support_10k';
  static const lunch = 'support_25k';
  static const full = 'support_50k';

  static const ordered = <String>[coffee, lunch, full];

  static const ids = <String>{coffee, lunch, full};

  static const defaultSelected = lunch;
}
