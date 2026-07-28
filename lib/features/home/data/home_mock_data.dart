import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/sport_colors.dart';

class HomeUser {
  const HomeUser({required this.name, required this.greeting});

  final String name;
  final String greeting;
}

class HomeMetric {
  const HomeMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class SessionPreview {
  const SessionPreview({
    required this.title,
    required this.dayLabel,
    required this.durationMinutes,
  });

  final String title;
  final String dayLabel;
  final int durationMinutes;
}

class SkillChip {
  const SkillChip({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color accent;
}

class LearningItem {
  const LearningItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  final String id;
  final String title;
  final String subtitle;
  final double progress;
}

abstract final class HomeMockData {
  static const user = HomeUser(
    name: 'Emma',
    greeting: 'Good morning',
  );

  static List<HomeMetric> metricsFor(AppSport sport) {
    return [
      const HomeMetric(label: 'Form', value: '87%', icon: Icons.trending_up),
      HomeMetric(
        label: 'Drills',
        value: sport == AppSport.volleyball ? '42' : '28',
        icon: sport.icon,
      ),
      const HomeMetric(label: 'This Week', value: '5.2h', icon: Icons.schedule),
    ];
  }

  static SessionPreview todaysSessionFor(AppSport sport) {
    return switch (sport) {
      AppSport.volleyball => const SessionPreview(
          title: 'Drive • Toss • Contact',
          dayLabel: 'Day 14',
          durationMinutes: 22,
        ),
      AppSport.soccer => const SessionPreview(
          title: 'Touch • Plant • Strike',
          dayLabel: 'Day 9',
          durationMinutes: 20,
        ),
    };
  }

  static List<SkillChip> commonSkillsFor(AppSport sport) {
    return switch (sport) {
      AppSport.volleyball => const [
          SkillChip(
            id: 'spike',
            label: 'Spike',
            icon: Icons.flash_on,
            accent: AppColors.primary,
          ),
          SkillChip(
            id: 'jump-serve',
            label: 'Jump Serve',
            icon: Icons.arrow_upward,
            accent: AppColors.action,
          ),
          SkillChip(
            id: 'overhead-set',
            label: 'Overhead Set',
            icon: Icons.pan_tool_alt,
            accent: AppColors.highlight,
          ),
        ],
      AppSport.soccer => [
          SkillChip(
            id: 'power-shot',
            label: 'Power Shot',
            icon: Icons.sports_soccer,
            accent: SportColors.soccer.primary,
          ),
          SkillChip(
            id: 'inside-pass',
            label: 'Inside Pass',
            icon: Icons.swipe_right,
            accent: SportColors.soccer.action,
          ),
          SkillChip(
            id: 'close-control',
            label: 'Close Control',
            icon: Icons.directions_run,
            accent: SportColors.soccer.highlight,
          ),
        ],
    };
  }

  static List<LearningItem> continueLearningFor(AppSport sport) {
    return switch (sport) {
      AppSport.volleyball => const [
          LearningItem(
            id: '3-step-approach',
            title: '3-step approach',
            subtitle: 'Spike fundamentals',
            progress: 0.65,
          ),
          LearningItem(
            id: 'rotator-cuff',
            title: 'Rotator cuff resilience',
            subtitle: 'Shoulder care',
            progress: 0.40,
          ),
        ],
      AppSport.soccer => const [
          LearningItem(
            id: 'power-shot',
            title: 'Power shot mechanics',
            subtitle: 'Plant & strike',
            progress: 0.55,
          ),
          LearningItem(
            id: 'soccer-hip-mobility',
            title: 'Hip mobility for strikers',
            subtitle: 'Kick range',
            progress: 0.35,
          ),
        ],
    };
  }
}
