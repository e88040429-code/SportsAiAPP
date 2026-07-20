import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LibrarySearchBar extends StatelessWidget {
  const LibrarySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search drills & poses',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface.withValues(alpha: 0.45),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.onSurface.withValues(alpha: 0.45),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.action, width: 1.5),
        ),
      ),
    );
  }
}
