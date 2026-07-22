import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Visual record control for the Live Coach shell (no camera APIs).
class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  final bool isRecording;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isRecording ? 'Stop recording' : 'Start recording',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.onCoachDark.withValues(alpha: 0.9),
                width: 4,
              ),
            ),
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: isRecording ? 28 : 52,
              height: isRecording ? 28 : 52,
              decoration: BoxDecoration(
                color: AppColors.darkRed,
                borderRadius: BorderRadius.circular(isRecording ? 6 : 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
