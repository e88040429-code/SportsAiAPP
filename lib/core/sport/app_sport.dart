import 'package:flutter/material.dart';

enum AppSport {
  volleyball,
  soccer,
}

extension AppSportX on AppSport {
  String get label => switch (this) {
        AppSport.volleyball => 'Volleyball',
        AppSport.soccer => 'Soccer',
      };

  String get tagline => switch (this) {
        AppSport.volleyball => 'Spikes, serves, sets, and form cues',
        AppSport.soccer => 'Shots, passes, dribbles, and footwork',
      };

  IconData get icon => switch (this) {
        AppSport.volleyball => Icons.sports_volleyball,
        AppSport.soccer => Icons.sports_soccer,
      };
}

/// App-wide selected sport. No sport is "chosen" until the welcome screen.
final AppSportController appSportController = AppSportController();

class AppSportController extends ChangeNotifier {
  AppSport _sport = AppSport.volleyball;
  bool _hasSelectedSport = false;

  /// Deep link to open after the athlete picks a sport (e.g. `/coach`).
  String? pendingDeepLink;

  AppSport get sport => _sport;

  /// False on cold start until welcome selection (or after [debugReset]).
  bool get hasSelectedSport => _hasSelectedSport;

  void select(AppSport sport) {
    _sport = sport;
    _hasSelectedSport = true;
    notifyListeners();
  }

  String? takePendingDeepLink() {
    final link = pendingDeepLink;
    pendingDeepLink = null;
    return link;
  }

  /// Test / hot-restart helper — clears the welcome gate.
  void debugReset() {
    _sport = AppSport.volleyball;
    _hasSelectedSport = false;
    pendingDeepLink = null;
    notifyListeners();
  }
}
