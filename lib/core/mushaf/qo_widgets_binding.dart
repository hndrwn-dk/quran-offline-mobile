import 'package:flutter/widgets.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_font_loader.dart';

/// App binding that keeps Mushaf page-font registrations cheap.
///
/// After any font is registered at runtime the engine sends a "fontsChange"
/// system message, and the framework answers by re-laying out every paragraph
/// in the app, hidden routes and tabs included. The Mushaf registers one font
/// per page, so on a large screen each new page cost a 100-200 ms frame
/// (issue #25). A page font's family name is new and unused when it is
/// registered, so that relayout changes nothing; this binding skips it for
/// the loader's own registrations and passes every other message on.
class QoWidgetsBinding extends WidgetsFlutterBinding {
  static WidgetsBinding ensureInitialized() {
    if (_instance == null) {
      QoWidgetsBinding();
      QpcV2FontLoader.skipRelayoutOnRegister = true;
    }
    return WidgetsBinding.instance;
  }

  static QoWidgetsBinding? _instance;

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
  }

  @override
  Future<void> handleSystemMessage(Object systemMessage) async {
    if (systemMessage is Map &&
        systemMessage['type'] == 'fontsChange' &&
        QpcV2FontLoader.consumeOwnFontChange()) {
      return;
    }
    await super.handleSystemMessage(systemMessage);
  }
}
