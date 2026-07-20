import 'package:flutter/material.dart';

enum LibraryMode { training, rehab }

class LibraryCategory {
  const LibraryCategory({required this.id, required this.label});

  final String id;
  final String label;
}

class LibraryDrill {
  const LibraryDrill({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryId,
    required this.mode,
    required this.durationMinutes,
    required this.icon,
    this.featured = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String categoryId;
  final LibraryMode mode;
  final int durationMinutes;
  final IconData icon;
  final bool featured;
}

abstract final class LibraryMockData {
  static const trainingCategories = <LibraryCategory>[
    LibraryCategory(id: 'all', label: 'All'),
    LibraryCategory(id: 'spike', label: 'Spike'),
    LibraryCategory(id: 'serve', label: 'Serve'),
    LibraryCategory(id: 'set', label: 'Set'),
    LibraryCategory(id: 'dig', label: 'Dig'),
    LibraryCategory(id: 'block', label: 'Block'),
  ];

  static const rehabCategories = <LibraryCategory>[
    LibraryCategory(id: 'all', label: 'All'),
    LibraryCategory(id: 'shoulder', label: 'Shoulder'),
    LibraryCategory(id: 'knee', label: 'Knee'),
    LibraryCategory(id: 'ankle', label: 'Ankle'),
    LibraryCategory(id: 'core', label: 'Core'),
  ];

  static List<LibraryCategory> categoriesFor(LibraryMode mode) {
    return mode == LibraryMode.training ? trainingCategories : rehabCategories;
  }

  static const drills = <LibraryDrill>[
    LibraryDrill(
      id: '3-step-approach',
      title: '3-step approach',
      subtitle: 'Spike fundamentals',
      categoryId: 'spike',
      mode: LibraryMode.training,
      durationMinutes: 12,
      icon: Icons.flash_on,
      featured: true,
    ),
    LibraryDrill(
      id: 'arm-swing-timing',
      title: 'Arm swing timing',
      subtitle: 'Spike contact window',
      categoryId: 'spike',
      mode: LibraryMode.training,
      durationMinutes: 10,
      icon: Icons.sports_volleyball,
    ),
    LibraryDrill(
      id: 'jump-serve',
      title: 'Jump serve toss',
      subtitle: 'Serve consistency',
      categoryId: 'serve',
      mode: LibraryMode.training,
      durationMinutes: 14,
      icon: Icons.arrow_upward,
    ),
    LibraryDrill(
      id: 'float-serve',
      title: 'Float serve contact',
      subtitle: 'Serve placement',
      categoryId: 'serve',
      mode: LibraryMode.training,
      durationMinutes: 11,
      icon: Icons.sports_handball,
    ),
    LibraryDrill(
      id: 'overhead-set',
      title: 'Overhead set',
      subtitle: 'Hand framing & release',
      categoryId: 'set',
      mode: LibraryMode.training,
      durationMinutes: 9,
      icon: Icons.pan_tool_alt,
    ),
    LibraryDrill(
      id: 'quick-set',
      title: 'Quick set tempo',
      subtitle: 'Setter footwork',
      categoryId: 'set',
      mode: LibraryMode.training,
      durationMinutes: 13,
      icon: Icons.speed,
    ),
    LibraryDrill(
      id: 'platform-dig',
      title: 'Platform dig',
      subtitle: 'Passing angle control',
      categoryId: 'dig',
      mode: LibraryMode.training,
      durationMinutes: 10,
      icon: Icons.shield_outlined,
    ),
    LibraryDrill(
      id: 'block-read',
      title: 'Block read & jump',
      subtitle: 'Timing at the net',
      categoryId: 'block',
      mode: LibraryMode.training,
      durationMinutes: 15,
      icon: Icons.vertical_align_top,
    ),
    LibraryDrill(
      id: 'rotator-cuff',
      title: 'Rotator cuff resilience',
      subtitle: 'Shoulder care',
      categoryId: 'shoulder',
      mode: LibraryMode.rehab,
      durationMinutes: 8,
      icon: Icons.accessibility_new,
      featured: true,
    ),
    LibraryDrill(
      id: 'scapular-stability',
      title: 'Scapular stability',
      subtitle: 'Shoulder control',
      categoryId: 'shoulder',
      mode: LibraryMode.rehab,
      durationMinutes: 10,
      icon: Icons.fitness_center,
    ),
    LibraryDrill(
      id: 'knee-landing',
      title: 'Soft landing mechanics',
      subtitle: 'Knee alignment',
      categoryId: 'knee',
      mode: LibraryMode.rehab,
      durationMinutes: 12,
      icon: Icons.directions_run,
    ),
    LibraryDrill(
      id: 'ankle-mobility',
      title: 'Ankle mobility circuit',
      subtitle: 'Dorsiflexion & balance',
      categoryId: 'ankle',
      mode: LibraryMode.rehab,
      durationMinutes: 9,
      icon: Icons.do_not_step,
    ),
    LibraryDrill(
      id: 'core-brace',
      title: 'Core brace & rotate',
      subtitle: 'Trunk stability',
      categoryId: 'core',
      mode: LibraryMode.rehab,
      durationMinutes: 11,
      icon: Icons.self_improvement,
    ),
  ];

  static LibraryDrill? featuredFor(LibraryMode mode) {
    for (final drill in drills) {
      if (drill.mode == mode && drill.featured) return drill;
    }
    return null;
  }

  static List<LibraryDrill> filter({
    required LibraryMode mode,
    required String categoryId,
    required String query,
  }) {
    final normalized = query.trim().toLowerCase();
    return drills.where((drill) {
      if (drill.mode != mode) return false;
      if (categoryId != 'all' && drill.categoryId != categoryId) return false;
      if (normalized.isEmpty) return true;
      return drill.title.toLowerCase().contains(normalized) ||
          drill.subtitle.toLowerCase().contains(normalized);
    }).toList(growable: false);
  }
}
