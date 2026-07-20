import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/library_mock_data.dart';

class LibraryModeToggle extends StatelessWidget {
  const LibraryModeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final LibraryMode selected;
  final ValueChanged<LibraryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Training',
              selected: selected == LibraryMode.training,
              onTap: () => onChanged(LibraryMode.training),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Rehab',
              selected: selected == LibraryMode.rehab,
              onTap: () => onChanged(LibraryMode.rehab),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected ? AppColors.action : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.onPrimary : AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
