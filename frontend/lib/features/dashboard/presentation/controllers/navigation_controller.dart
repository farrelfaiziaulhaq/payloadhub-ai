import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifiers for the sidebar pages (kept in sync with [AppSidebar]).
enum AppPage { dashboard, exploits, generator, monitoring, settings }

/// Holds the currently selected sidebar page. Kept in a provider so the
/// sidebar, the main canvas, and cross-page actions (e.g. "Send to Studio")
/// all share a single source of truth without re-mounting the telemetry.
class NavigationController extends StateNotifier<AppPage> {
  NavigationController() : super(AppPage.dashboard);

  void select(AppPage page) {
    if (state != page) state = page;
  }
}

final navControllerProvider =
    StateNotifierProvider<NavigationController, AppPage>((ref) {
  return NavigationController();
});
