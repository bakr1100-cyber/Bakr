import 'package:flutter/foundation.dart';

/// Drives which bottom-nav tab [HomeScreen] shows, so other screens (e.g.
/// the "talk to the AI" card on the landing page) can jump straight to the
/// assistant tab instead of only reacting to the nav bar itself.
class HomeNavigationProvider extends ChangeNotifier {
  static const assistantTabIndex = 1;
  static const alertsTabIndex = 3;

  int tabIndex = 0;

  /// One-shot flag: set when something outside the assistant tab wants it
  /// to start listening as soon as it becomes visible (e.g. the landing
  /// page's voice card) - consumed immediately once acted on.
  bool pendingVoiceStart = false;

  void goToTab(int index) {
    if (tabIndex == index) return;
    tabIndex = index;
    notifyListeners();
  }

  void goToAssistantWithVoice() {
    tabIndex = assistantTabIndex;
    pendingVoiceStart = true;
    notifyListeners();
  }

  void consumePendingVoiceStart() {
    pendingVoiceStart = false;
  }
}
