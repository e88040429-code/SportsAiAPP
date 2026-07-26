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

/// App-wide selected sport. Defaults to volleyball.
final AppSportController appSportController = AppSportController();

class AppSportController extends ChangeNotifier {
  AppSport _sport = AppSport.volleyball;

  AppSport get sport => _sport;

  void select(AppSport sport) {
    _sport = sport;
    notifyListeners();
  }
}
