import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

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
    name: 'Maya Chen',
    greeting: 'Good morning',
  );

  static const metrics = <HomeMetric>[
    HomeMetric(label: 'Form', value: '87%', icon: Icons.trending_up),
    HomeMetric(label: 'Drills', value: '42', icon: Icons.sports_volleyball),
    HomeMetric(label: 'This Week', value: '5.2h', icon: Icons.schedule),
  ];

  static const todaysSession = SessionPreview(
    title: 'Drive • Toss • Contact',
    dayLabel: 'Day 14',
    durationMinutes: 22,
  );

  static const commonSkills = <SkillChip>[
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
  ];

  static const continueLearning = <LearningItem>[
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
  ];
}
