import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/library_mock_data.dart';

class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<LibraryCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == selectedId;
          return _CategoryChip(
            label: category.label,
            selected: selected,
            onTap: () => onSelected(category.id),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
      color: selected ? AppColors.highlight : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(
                    color: AppColors.onSurface.withValues(alpha: 0.08),
                  ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.darkestNavy : AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
