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

/// Seed copy + offline fallback coaching replies.
abstract final class AiResponseMockData {
  static List<AiMessage> seedFor(AppSport sport) {
    return switch (sport) {
      AppSport.volleyball => const [
          AiMessage(
            role: AiMessageRole.assistant,
            text:
                'Hi! I\'m your SetPoint AI coach. Ask me about form, timing, strategy, or recovery — I\'ll give you a full coaching breakdown.',
          ),
        ],
      AppSport.soccer => const [
          AiMessage(
            role: AiMessageRole.assistant,
            text:
                'Hi! I\'m your SetPoint AI coach. Ask me about shooting, passing, footwork, or recovery — I\'ll give you a full coaching breakdown.',
          ),
        ],
    };
  }

  static String replyFor(String prompt, AppSport sport) {
    final q = prompt.toLowerCase();

    if (q.contains('rehab') || q.contains('shoulder') || q.contains('pain')) {
      return 'Back off volume today and treat this as a recovery session, not a max-effort day. '
          'Start with easy range-of-motion work, then add light band or bodyweight control drills only if pain stays at a dull ache or lower. '
          'Sharp or shooting pain means stop that pattern immediately and switch to your Rehab Hub checklist.\n\n'
          'In practice: keep sets short, breathe through each rep, and film one easy set so you can check whether you are compensating with shrugging or side-bending. '
          'If symptoms hang around across sessions, get a clinician involved — I can coach form, but I am not a doctor.\n\n'
          'Next session plan: warm-up mobility → 2 controlled activation drills → optional technique work at 50–60% effort → ice/compress if that is in your program.';
    }

    if (q.contains('timing') || q.contains('tempo')) {
      return sport == AppSport.volleyball
          ? 'Most timing misses happen because the swing starts before you finish rising. '
              'Think of the jump and arm swing as two linked clocks: first you load and leave the ground, then you reach high, then you snap.\n\n'
              'Use the cue “load – reach – snap.” On the approach, get the penultimate step long and the plant firm. '
              'As you jump, both arms should help lift; the hitting elbow stays high and back until you are near the peak. '
              'Only then lead with the elbow and accelerate through contact.\n\n'
              'Common mistake: swinging early because the set is tight. If the set is off, adjust your approach angle instead of rushing the arm. '
              'Drill it with 8–10 controlled contacts focusing only on delaying the swing, then add pace once the rhythm feels automatic.'
          : 'Shooting timing is mostly plant-foot timing. If the plant arrives late or early, the strike gets shoved or leaned back and the ball flies.\n\n'
              'Use “touch – plant – strike.” Take a clean first touch that sets the ball slightly ahead, plant the non-kicking foot beside the ball with the toes pointing toward your target, '
              'then swing through the center of the ball with a locked ankle.\n\n'
              'Common mistake: leaning away to “help” power. Keep your chest over the ball and finish toward the target. '
              'Drill with 10 placed finishes at walk-in pace before you add a run-up, and film from the side so you can check plant distance and body lean.';
    }

    if (q.contains('balance') || q.contains('land')) {
      return 'Balance and soft landings protect your knees and keep the next rep ready. '
          'Land with bent hips and knees, feet about hip-width, and a quiet torso — no crashing into locked joints.\n\n'
          'Cue “soft knees, quiet feet.” After contact or a cut, stick the landing for a full second before resetting. '
          'Watch whether either knee caves inward; if it does, shorten the drill and emphasize tracking the knee over the toes.\n\n'
          'Practice plan: 2 sets of controlled jump-lands, then your skill reps with an intentional stick on every finish. '
          'Film frontal and side views once so you can compare left/right symmetry.';
    }

    return sport == AppSport.volleyball
        ? 'Let\'s treat this like a full coaching block. Start with posture: tall through the torso, eyes on the ball early, and a balanced base on the plant. '
            'A high elbow on the hitting arm gives you room to accelerate; if the elbow drops, contact gets late and weak.\n\n'
            'Through the swing, lead with the elbow, snap the wrist over the top of the ball, and finish across your body instead of stopping short. '
            'That follow-through is what keeps the ball driven and topspun instead of sprayed long.\n\n'
            'Common misses: drifting under the ball, swinging before peak jump, and collapsing the shoulder after contact. '
            'Pick one cue for your next set — “elbow high” is usually the highest leverage — and run 8–12 focused reps before you chase power.\n\n'
            'When you finish, log the session in Recap and note whether contact felt earlier, higher, or cleaner. That feedback loop is how form actually sticks.'
        : 'Build the shot from the ground up. Get a balanced base, plant the non-kicking foot beside the ball, and keep your hips square enough to rotate through the target. '
            'A locked ankle and firm striking surface give you cleaner contact than a floppy foot.\n\n'
            'Through the strike, keep your chest over the ball and follow through toward the aim point instead of falling away. '
            'That combination keeps shots low and driven rather than scooped over the bar.\n\n'
            'Common misses: planting too far behind the ball, opening the hips too early, and swinging only with the leg instead of sequencing hip-to-foot. '
            'Choose one cue — “plant beside, chest over” — and hit 10 controlled finishes before you add pace.\n\n'
            'After the set, note whether contact felt centered and whether your plant felt stable. Small, repeated corrections beat random hard shots.';
  }
}
