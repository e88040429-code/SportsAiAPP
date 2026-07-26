import '../../../core/sport/app_sport.dart';

enum AiMessageRole { user, assistant }

class AiMessage {
  const AiMessage({
    required this.role,
    required this.text,
  });

  final AiMessageRole role;
  final String text;
}

/// Mock AI coaching responses (no backend / LLM yet).
abstract final class AiResponseMockData {
  static List<AiMessage> seedFor(AppSport sport) {
    return switch (sport) {
      AppSport.volleyball => const [
          AiMessage(
            role: AiMessageRole.assistant,
            text:
                'Hi! I\'m your SetPoint AI coach. Ask me about form, timing, or recovery.',
          ),
          AiMessage(
            role: AiMessageRole.user,
            text: 'How can I improve my spike follow-through?',
          ),
          AiMessage(
            role: AiMessageRole.assistant,
            text:
                'Keep your elbow higher through contact and finish across the body. '
                'Your last session showed the elbow ~13° low vs the coach model.',
          ),
        ],
      AppSport.soccer => const [
          AiMessage(
            role: AiMessageRole.assistant,
            text:
                'Hi! I\'m your SetPoint AI coach. Ask me about shooting, passing, footwork, or recovery.',
          ),
          AiMessage(
            role: AiMessageRole.user,
            text: 'My shots keep sailing over the bar.',
          ),
          AiMessage(
            role: AiMessageRole.assistant,
            text:
                'Plant your non-kicking foot beside the ball and strike through the center. '
                'Keep your chest over the ball so the shot stays low and driven.',
          ),
        ],
    };
  }

  static String replyFor(String prompt, AppSport sport) {
    final q = prompt.toLowerCase();

    if (q.contains('rehab') || q.contains('shoulder') || q.contains('pain')) {
      return 'Ease volume today and prioritize controlled range of motion. '
          'If pain is sharp, stop the drill and switch to your rehab checklist.';
    }

    if (q.contains('timing') || q.contains('tempo')) {
      return sport == AppSport.volleyball
          ? 'Delay the swing until you reach peak jump height. Count “load–reach–snap” on each rep.'
          : 'Time your plant with the touch. Count “touch–plant–strike” on each shot.';
    }

    if (q.contains('balance') || q.contains('land')) {
      return 'Soft landings start with bent knees and a quiet torso. Film one set and check knee tracking over the toes.';
    }

    return sport == AppSport.volleyball
        ? 'Focus on one cue this set: tall posture, high elbow, and a complete follow-through. Log the session when you finish.'
        : 'Focus on one cue this set: balanced plant foot, locked ankle, and follow through to target. Log the session when you finish.';
  }
}
