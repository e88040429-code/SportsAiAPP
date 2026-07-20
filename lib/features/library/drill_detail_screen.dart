import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'data/drill_detail_mock_data.dart';
import 'widgets/drill_description_section.dart';
import 'widgets/drill_video_placeholder.dart';
import 'widgets/key_positions_timeline.dart';
import 'widgets/start_drill_button.dart';

class DrillDetailScreen extends StatelessWidget {
  const DrillDetailScreen({super.key, required this.drillId});

  final String drillId;

  @override
  Widget build(BuildContext context) {
    final detail = DrillDetailMockData.forId(drillId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drill Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DrillVideoPlaceholder(durationMinutes: detail.durationMinutes),
                  const SizedBox(height: 24),
                  DrillDescriptionSection(detail: detail),
                  const SizedBox(height: 28),
                  KeyPositionsTimeline(positions: detail.keyPositions),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: StartDrillButton(
                onPressed: () => context.go('/coach'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
