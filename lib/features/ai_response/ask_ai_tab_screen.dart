import 'package:flutter/material.dart';

import '../../core/sport/app_sport.dart';
import 'ai_response_screen.dart';

/// Bottom-tab entry that follows the currently selected sport.
class AskAiTabScreen extends StatelessWidget {
  const AskAiTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSportController,
      builder: (context, _) {
        final sport = appSportController.sport;
        return AiResponseScreen(
          key: ValueKey(sport),
          lockedSport: sport,
          title: 'Ask ${sport.label}',
          hintText: 'Ask anything about ${sport.label.toLowerCase()}…',
          qaMode: true,
        );
      },
    );
  }
}
