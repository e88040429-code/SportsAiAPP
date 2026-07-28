import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/sport/app_sport.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/sport_colors.dart';
import '../data/clip_analysis_session.dart';
import '../data/model_pose_library.dart';

class InstantFeedbackCard extends StatelessWidget {
  const InstantFeedbackCard({
    super.key,
    required this.sport,
    required this.analysis,
    required this.onOpenRecap,
  });

  final AppSport sport;
  final ClipAnalysisResult analysis;
  final VoidCallback onOpenRecap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SportColors.of(sport);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.darkestNavy.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.action.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.action.withValues(alpha: 0.2),
                  border: Border.all(color: colors.action, width: 2),
                ),
                child: Text(
                  '${analysis.overallScore}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What I see in your clip',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysis.headline,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.onCoachDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.motionDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onCoachDark.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Coach notes',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.cta,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final tip in analysis.feedback) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt, size: 16, color: colors.cta),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onCoachDark.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenRecap,
              style: FilledButton.styleFrom(
                backgroundColor: colors.action,
                foregroundColor: AppColors.onPrimary,
              ),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Open full review in Recap'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Athlete writes what happens in the clip before tapping Generate.
class AthleteClipDescriptionField extends StatelessWidget {
  const AthleteClipDescriptionField({
    super.key,
    required this.sport,
    required this.controller,
    this.enabled = true,
  });

  final AppSport sport;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SportColors.of(sport);
    final hint = sport == AppSport.volleyball
        ? 'Example: Right-side spike from zone 2, approach felt late, I floated on the last step and swung across my body…'
        : 'Example: Right-foot strike after a short dribble, plant felt soft, ball skidded low to the near post…';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.darkestNavy.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.accent.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: colors.accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '1. Describe your clip',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Write what you’re doing and what felt off. Then tap Generate for written feedback.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onCoachDark.withValues(alpha: 0.7),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: enabled,
            minLines: 4,
            maxLines: 8,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onCoachDark,
              height: 1.4,
            ),
            cursorColor: colors.accent,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onCoachDark.withValues(alpha: 0.4),
                height: 1.35,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.28),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colors.coachLine.withValues(alpha: 0.35),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colors.coachLine.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.accent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clip flow: describe → Generate → written feedback.
class ClipAnalysisPanel extends StatelessWidget {
  const ClipAnalysisPanel({
    super.key,
    required this.sport,
    required this.kind,
    required this.clipName,
    required this.videoController,
    this.previewNote,
    required this.isGenerating,
    this.analysis,
    required this.athleteDescriptionController,
    required this.onKindChanged,
    required this.onClose,
    required this.onGenerate,
    required this.onOpenRecap,
  });

  final AppSport sport;
  final SkillModelKind kind;
  final String clipName;
  final VideoPlayerController? videoController;
  final String? previewNote;
  final bool isGenerating;
  final ClipAnalysisResult? analysis;
  final TextEditingController athleteDescriptionController;
  final ValueChanged<SkillModelKind> onKindChanged;
  final VoidCallback onClose;
  final VoidCallback onGenerate;
  final VoidCallback onOpenRecap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SportColors.of(sport);
    final ready =
        videoController != null && videoController!.value.isInitialized;
    final hasFeedback = analysis != null;

    return Container(
      color: AppColors.coachDark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    color: AppColors.onCoachDark,
                    tooltip: 'Back to live camera',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clip analysis',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.onCoachDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          clipName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.onCoachDark.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasFeedback)
                    TextButton(
                      onPressed: onOpenRecap,
                      child: Text(
                        'Recap',
                        style: TextStyle(color: colors.accent),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedButton<SkillModelKind>(
                segments: [
                  ButtonSegment(
                    value: SkillModelKind.receive,
                    label: Text(
                      sport == AppSport.volleyball ? 'Receive' : 'First touch',
                    ),
                    icon: const Icon(Icons.front_hand, size: 16),
                  ),
                  ButtonSegment(
                    value: SkillModelKind.hitting,
                    label: Text(
                      sport == AppSport.volleyball ? 'Hitting' : 'Strike',
                    ),
                    icon: const Icon(Icons.sports, size: 16),
                  ),
                ],
                selected: {kind},
                onSelectionChanged: isGenerating
                    ? null
                    : (set) => onKindChanged(set.first),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.onPrimary;
                    }
                    return AppColors.onCoachDark;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return colors.action;
                    }
                    return AppColors.darkTeal.withValues(alpha: 0.35);
                  }),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    if (ready)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: videoController!.value.aspectRatio == 0
                              ? 16 / 9
                              : videoController!.value.aspectRatio,
                          child: ListenableBuilder(
                            listenable: videoController!,
                            builder: (context, _) {
                              return Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  VideoPlayer(videoController!),
                                  Container(
                                    width: double.infinity,
                                    color: Colors.black45,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            final c = videoController!;
                                            c.value.isPlaying
                                                ? c.pause()
                                                : c.play();
                                          },
                                          icon: Icon(
                                            videoController!.value.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: AppColors.onCoachDark,
                                          ),
                                        ),
                                        Expanded(
                                          child: VideoProgressIndicator(
                                            videoController!,
                                            allowScrubbing: true,
                                            colors: VideoProgressColors(
                                              playedColor: colors.action,
                                              bufferedColor: colors.highlight
                                                  .withValues(alpha: 0.4),
                                              backgroundColor: Colors.white24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      )
                    else if (previewNote != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.darkestNavy.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          previewNote!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                AppColors.onCoachDark.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    if (ready || previewNote != null) const SizedBox(height: 14),
                    AthleteClipDescriptionField(
                      sport: sport,
                      controller: athleteDescriptionController,
                      enabled: !isGenerating,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isGenerating ? null : onGenerate,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.cta,
                          foregroundColor: AppColors.onPrimary,
                          disabledBackgroundColor:
                              colors.cta.withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          isGenerating
                              ? 'Generating…'
                              : hasFeedback
                                  ? 'Generate again'
                                  : 'Generate',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    if (isGenerating) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing your clip with your description…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onCoachDark.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    if (hasFeedback && !isGenerating) ...[
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '2. Written feedback',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InstantFeedbackCard(
                        sport: sport,
                        analysis: analysis!,
                        onOpenRecap: onOpenRecap,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
