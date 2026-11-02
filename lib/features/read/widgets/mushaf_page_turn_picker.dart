import 'package:flutter/material.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// "Mushaf page turn" choice (Seperti buku / Geser / Langsung) with a hint
/// for the selected option. Used by Settings and the Mushaf text settings.
///
/// Labels are never truncated or split inside a word: icons go first when
/// space runs out, then labels wrap between words, and when even one word
/// does not fit a third of the width the options stack vertically.
class MushafPageTurnPicker extends StatelessWidget {
  const MushafPageTurnPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.language,
  });

  final MushafPageTurn value;
  final ValueChanged<MushafPageTurn> onChanged;
  final String language;

  static const _options = [
    (MushafPageTurn.curl, Icons.auto_stories, 'page_turn_curl', 'page_turn_hint_curl'),
    (MushafPageTurn.slide, Icons.swap_horiz, 'page_turn_slide', 'page_turn_hint_slide'),
    (MushafPageTurn.none, Icons.bolt, 'page_turn_none', 'page_turn_hint_none'),
  ];

  /// Horizontal space a segment spends besides its label (padding, borders).
  static const double _segmentChrome = 26;

  /// Icon plus the gap after it.
  static const double _iconSpace = 18 + 8;

  String _text(String key) => AppLocalizations.getSettingsText(key, language);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintKey = _options.firstWhere((o) => o.$1 == value).$4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final style = theme.textTheme.labelLarge ?? const TextStyle();
            final scaler = MediaQuery.textScalerOf(context);
            final segment = constraints.maxWidth / _options.length;
            double widestOf(Iterable<String> texts) => texts
                .map((t) => _labelWidth(t, style, scaler))
                .reduce((a, b) => a > b ? a : b);
            final labels = [for (final o in _options) _text(o.$3)];
            final widestWord = widestOf(labels.expand((l) => l.split(' ')));
            final vertical = widestWord + _segmentChrome > segment;
            final icons = vertical ||
                widestOf(labels) + _iconSpace + _segmentChrome <= segment;
            return SegmentedButton<MushafPageTurn>(
              key: const Key('mushaf-page-turn'),
              showSelectedIcon: false,
              direction: vertical ? Axis.vertical : Axis.horizontal,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
              segments: [
                for (final (turn, icon, label, _) in _options)
                  ButtonSegment<MushafPageTurn>(
                    value: turn,
                    icon: icons ? Icon(icon, size: 18) : null,
                    label: Text(
                      _text(label),
                      textAlign:
                          vertical ? TextAlign.start : TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ),
              ],
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.first),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          _text(hintKey),
          key: const Key('mushaf-page-turn-hint'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static double _labelWidth(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
