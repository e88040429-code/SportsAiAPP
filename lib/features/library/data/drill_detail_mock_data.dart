import 'package:flutter/material.dart';

import 'library_mock_data.dart';

class KeyPosition {
  const KeyPosition({
    required this.step,
    required this.label,
    required this.icon,
  });

  final int step;
  final String label;
  final IconData icon;
}

class DrillDetail {
  const DrillDetail({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.durationMinutes,
    required this.icon,
    required this.keyPositions,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int durationMinutes;
  final IconData icon;
  final List<KeyPosition> keyPositions;
}

abstract final class DrillDetailMockData {
  static const _details = <String, DrillDetail>{
    '3-step-approach': DrillDetail(
      id: '3-step-approach',
      title: '3-step approach',
      subtitle: 'Spike fundamentals',
      description:
          'Build a powerful, balanced spike approach. Focus on a controlled first step, '
          'an explosive second plant, and a high third step that loads the hips for a '
          'clean jump. Keep the torso tall, arms swinging back on the plant, and eyes '
          'on the ball through contact.',
      durationMinutes: 12,
      icon: Icons.flash_on,
      keyPositions: [
        KeyPosition(step: 1, label: 'Ready', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Step 1', icon: Icons.directions_walk),
        KeyPosition(step: 3, label: 'Plant', icon: Icons.front_hand),
        KeyPosition(step: 4, label: 'Jump', icon: Icons.arrow_upward),
        KeyPosition(step: 5, label: 'Swing', icon: Icons.sports_volleyball),
        KeyPosition(step: 6, label: 'Land', icon: Icons.arrow_downward),
      ],
    ),
    'arm-swing-timing': DrillDetail(
      id: 'arm-swing-timing',
      title: 'Arm swing timing',
      subtitle: 'Spike contact window',
      description:
          'Synchronize the hitting arm with the peak of your jump. Start the elbow high '
          'and back, lead with the elbow into the swing, and strike the ball at full '
          'extension. Practice delaying the swing so contact happens at the highest '
          'reachable point without collapsing the shoulder.',
      durationMinutes: 10,
      icon: Icons.sports_volleyball,
      keyPositions: [
        KeyPosition(step: 1, label: 'Load', icon: Icons.replay),
        KeyPosition(step: 2, label: 'Elbow high', icon: Icons.height),
        KeyPosition(step: 3, label: 'Lead', icon: Icons.trending_flat),
        KeyPosition(step: 4, label: 'Contact', icon: Icons.flash_on),
        KeyPosition(step: 5, label: 'Follow', icon: Icons.swipe_down),
      ],
    ),
    'jump-serve': DrillDetail(
      id: 'jump-serve',
      title: 'Jump serve toss',
      subtitle: 'Serve consistency',
      description:
          'Develop a repeatable jump-serve toss. Place the ball in the same release '
          'spot every rep, step into the approach as the toss peaks, and contact with '
          'a firm wrist. Prioritize toss height and placement over power until the '
          'rhythm feels automatic.',
      durationMinutes: 14,
      icon: Icons.arrow_upward,
      keyPositions: [
        KeyPosition(step: 1, label: 'Stance', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Toss', icon: Icons.upload),
        KeyPosition(step: 3, label: 'Approach', icon: Icons.directions_run),
        KeyPosition(step: 4, label: 'Jump', icon: Icons.arrow_upward),
        KeyPosition(step: 5, label: 'Contact', icon: Icons.sports_handball),
        KeyPosition(step: 6, label: 'Finish', icon: Icons.check),
      ],
    ),
    'float-serve': DrillDetail(
      id: 'float-serve',
      title: 'Float serve contact',
      subtitle: 'Serve placement',
      description:
          'Hit a no-spin float serve with a firm, flat hand. Keep the toss low and '
          'in front, contact through the center of the ball, and freeze the wrist on '
          'contact so the ball floats and drops unpredictably over the net.',
      durationMinutes: 11,
      icon: Icons.sports_handball,
      keyPositions: [
        KeyPosition(step: 1, label: 'Setup', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Toss', icon: Icons.upload),
        KeyPosition(step: 3, label: 'Step', icon: Icons.directions_walk),
        KeyPosition(step: 4, label: 'Contact', icon: Icons.front_hand),
        KeyPosition(step: 5, label: 'Hold', icon: Icons.pause),
      ],
    ),
    'overhead-set': DrillDetail(
      id: 'overhead-set',
      title: 'Overhead set',
      subtitle: 'Hand framing & release',
      description:
          'Shape a clean overhead set with soft hands and a stable frame. Get under '
          'the ball early, form a triangle with thumbs and index fingers, and extend '
          'through the release toward the target. Keep elbows out and finish high.',
      durationMinutes: 9,
      icon: Icons.pan_tool_alt,
      keyPositions: [
        KeyPosition(step: 1, label: 'Base', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Move', icon: Icons.directions_run),
        KeyPosition(step: 3, label: 'Frame', icon: Icons.pan_tool_alt),
        KeyPosition(step: 4, label: 'Catch', icon: Icons.back_hand),
        KeyPosition(step: 5, label: 'Release', icon: Icons.north_east),
      ],
    ),
    'quick-set': DrillDetail(
      id: 'quick-set',
      title: 'Quick set tempo',
      subtitle: 'Setter footwork',
      description:
          'Train quick-set tempo with sharp footwork and a compact release. Beat the '
          'ball to the spot, square the shoulders early, and deliver a tight set that '
          'lets the hitter attack on one step. Emphasize speed without rushing the hands.',
      durationMinutes: 13,
      icon: Icons.speed,
      keyPositions: [
        KeyPosition(step: 1, label: 'Read', icon: Icons.visibility),
        KeyPosition(step: 2, label: 'Plant', icon: Icons.front_hand),
        KeyPosition(step: 3, label: 'Square', icon: Icons.crop_square),
        KeyPosition(step: 4, label: 'Set', icon: Icons.pan_tool_alt),
        KeyPosition(step: 5, label: 'Recover', icon: Icons.replay),
      ],
    ),
    'platform-dig': DrillDetail(
      id: 'platform-dig',
      title: 'Platform dig',
      subtitle: 'Passing angle control',
      description:
          'Build a reliable forearm platform for digs and passes. Stay low, angle the '
          'platform toward the target, and absorb pace with the legs rather than the '
          'arms. Keep the platform flat and quiet through contact.',
      durationMinutes: 10,
      icon: Icons.shield_outlined,
      keyPositions: [
        KeyPosition(step: 1, label: 'Ready', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Move', icon: Icons.directions_run),
        KeyPosition(step: 3, label: 'Platform', icon: Icons.horizontal_rule),
        KeyPosition(step: 4, label: 'Angle', icon: Icons.rotate_right),
        KeyPosition(step: 5, label: 'Absorb', icon: Icons.compress),
      ],
    ),
    'block-read': DrillDetail(
      id: 'block-read',
      title: 'Block read & jump',
      subtitle: 'Timing at the net',
      description:
          'Read the setter and hitter, then time your block jump to seal the net. '
          'Press hands over early, keep shoulders square, and land soft on both feet. '
          'Practice reading line versus angle before leaving the ground.',
      durationMinutes: 15,
      icon: Icons.vertical_align_top,
      keyPositions: [
        KeyPosition(step: 1, label: 'Base', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Read', icon: Icons.visibility),
        KeyPosition(step: 3, label: 'Shuffle', icon: Icons.swap_horiz),
        KeyPosition(step: 4, label: 'Jump', icon: Icons.arrow_upward),
        KeyPosition(step: 5, label: 'Press', icon: Icons.back_hand),
        KeyPosition(step: 6, label: 'Land', icon: Icons.arrow_downward),
      ],
    ),
    'rotator-cuff': DrillDetail(
      id: 'rotator-cuff',
      title: 'Rotator cuff resilience',
      subtitle: 'Shoulder care',
      description:
          'Strengthen the rotator cuff with controlled external rotation and scapular '
          'setting. Move slowly through each rep, keep the elbow pinned to your side, '
          'and stop if you feel sharp pain. Consistency beats heavy load for shoulder care.',
      durationMinutes: 8,
      icon: Icons.accessibility_new,
      keyPositions: [
        KeyPosition(step: 1, label: 'Setup', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Set scap', icon: Icons.fitness_center),
        KeyPosition(step: 3, label: 'Rotate', icon: Icons.rotate_right),
        KeyPosition(step: 4, label: 'Hold', icon: Icons.pause),
        KeyPosition(step: 5, label: 'Return', icon: Icons.replay),
      ],
    ),
    'scapular-stability': DrillDetail(
      id: 'scapular-stability',
      title: 'Scapular stability',
      subtitle: 'Shoulder control',
      description:
          'Train scapular control so the shoulder blade stays stable under load. Focus '
          'on depression and retraction without shrugging. Pair light resistance with '
          'clean posture to support hitting and serving volume.',
      durationMinutes: 10,
      icon: Icons.fitness_center,
      keyPositions: [
        KeyPosition(step: 1, label: 'Posture', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Depress', icon: Icons.arrow_downward),
        KeyPosition(step: 3, label: 'Retract', icon: Icons.compress),
        KeyPosition(step: 4, label: 'Hold', icon: Icons.pause),
        KeyPosition(step: 5, label: 'Release', icon: Icons.expand),
      ],
    ),
    'knee-landing': DrillDetail(
      id: 'knee-landing',
      title: 'Soft landing mechanics',
      subtitle: 'Knee alignment',
      description:
          'Practice soft landings that keep knees tracking over the toes. Absorb force '
          'through the hips and ankles, keep the chest tall, and avoid letting the '
          'knees collapse inward. Start from a small hop and progress height gradually.',
      durationMinutes: 12,
      icon: Icons.directions_run,
      keyPositions: [
        KeyPosition(step: 1, label: 'Ready', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Hop', icon: Icons.arrow_upward),
        KeyPosition(step: 3, label: 'Align', icon: Icons.align_vertical_center),
        KeyPosition(step: 4, label: 'Absorb', icon: Icons.compress),
        KeyPosition(step: 5, label: 'Hold', icon: Icons.pause),
      ],
    ),
    'ankle-mobility': DrillDetail(
      id: 'ankle-mobility',
      title: 'Ankle mobility circuit',
      subtitle: 'Dorsiflexion & balance',
      description:
          'Improve ankle dorsiflexion and single-leg balance for safer landings and '
          'quicker court movement. Move through controlled ranges, keep the heel down '
          'on mobility drills, and challenge balance only after mobility feels easy.',
      durationMinutes: 9,
      icon: Icons.do_not_step,
      keyPositions: [
        KeyPosition(step: 1, label: 'Warm', icon: Icons.whatshot),
        KeyPosition(step: 2, label: 'Rock', icon: Icons.swipe),
        KeyPosition(step: 3, label: 'Flex', icon: Icons.accessibility),
        KeyPosition(step: 4, label: 'Balance', icon: Icons.balance),
        KeyPosition(step: 5, label: 'Reset', icon: Icons.replay),
      ],
    ),
    'core-brace': DrillDetail(
      id: 'core-brace',
      title: 'Core brace & rotate',
      subtitle: 'Trunk stability',
      description:
          'Learn to brace the trunk before rotating through swings and serves. Exhale '
          'to set the ribs down, keep the pelvis neutral, and rotate through the torso '
          'without losing the brace. Strong core control protects the shoulder and lower back.',
      durationMinutes: 11,
      icon: Icons.self_improvement,
      keyPositions: [
        KeyPosition(step: 1, label: 'Align', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Brace', icon: Icons.compress),
        KeyPosition(step: 3, label: 'Rotate', icon: Icons.rotate_right),
        KeyPosition(step: 4, label: 'Return', icon: Icons.replay),
        KeyPosition(step: 5, label: 'Reset', icon: Icons.check),
      ],
    ),
    // Home Common Skills aliases
    'spike': DrillDetail(
      id: 'spike',
      title: 'Spike',
      subtitle: 'Attack fundamentals',
      description:
          'A full spike overview covering approach, jump, and arm swing. Use this drill '
          'to connect footwork with a high contact point and a confident follow-through.',
      durationMinutes: 12,
      icon: Icons.flash_on,
      keyPositions: [
        KeyPosition(step: 1, label: 'Ready', icon: Icons.accessibility_new),
        KeyPosition(step: 2, label: 'Approach', icon: Icons.directions_run),
        KeyPosition(step: 3, label: 'Plant', icon: Icons.front_hand),
        KeyPosition(step: 4, label: 'Jump', icon: Icons.arrow_upward),
        KeyPosition(step: 5, label: 'Contact', icon: Icons.sports_volleyball),
        KeyPosition(step: 6, label: 'Land', icon: Icons.arrow_downward),
      ],
    ),
  };

  static const _fallbackPositions = <KeyPosition>[
    KeyPosition(step: 1, label: 'Setup', icon: Icons.accessibility_new),
    KeyPosition(step: 2, label: 'Load', icon: Icons.fitness_center),
    KeyPosition(step: 3, label: 'Execute', icon: Icons.play_arrow),
    KeyPosition(step: 4, label: 'Hold', icon: Icons.pause),
    KeyPosition(step: 5, label: 'Finish', icon: Icons.check),
  ];

  static DrillDetail forId(String drillId) {
    final detail = _details[drillId];
    if (detail != null) return detail;

    LibraryDrill? libraryDrill;
    for (final drill in LibraryMockData.drills) {
      if (drill.id == drillId) {
        libraryDrill = drill;
        break;
      }
    }

    if (libraryDrill != null) {
      return DrillDetail(
        id: libraryDrill.id,
        title: libraryDrill.title,
        subtitle: libraryDrill.subtitle,
        description:
            'Practice ${libraryDrill.title.toLowerCase()} with controlled reps. '
            'Focus on form first, then add speed. Review each key position before '
            'starting the live coach session.',
        durationMinutes: libraryDrill.durationMinutes,
        icon: libraryDrill.icon,
        keyPositions: _fallbackPositions,
      );
    }

    return DrillDetail(
      id: drillId,
      title: _titleFromId(drillId),
      subtitle: 'Drill overview',
      description:
          'Review the key positions for this drill, then start a live coach session '
          'to practice with real-time form cues.',
      durationMinutes: 10,
      icon: Icons.sports_volleyball,
      keyPositions: _fallbackPositions,
    );
  }

  static String _titleFromId(String id) {
    return id
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
