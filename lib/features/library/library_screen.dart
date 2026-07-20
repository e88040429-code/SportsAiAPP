import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/library_mock_data.dart';
import 'widgets/category_chips_row.dart';
import 'widgets/drill_list.dart';
import 'widgets/featured_drill_card.dart';
import 'widgets/library_mode_toggle.dart';
import 'widgets/library_search_bar.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();

  LibraryMode _mode = LibraryMode.training;
  String _categoryId = 'all';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onModeChanged(LibraryMode mode) {
    setState(() {
      _mode = mode;
      _categoryId = 'all';
    });
  }

  void _openDrill(LibraryDrill drill) {
    context.push('/library/drill/${drill.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = LibraryMockData.categoriesFor(_mode);
    final featured = LibraryMockData.featuredFor(_mode);
    final drills = LibraryMockData.filter(
      mode: _mode,
      categoryId: _categoryId,
      query: _query,
    );

    // Keep featured out of the list when it would otherwise duplicate.
    final listDrills = featured == null
        ? drills
        : drills.where((d) => d.id != featured.id).toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pose Library',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse sport-specific drills and poses',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              LibrarySearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 16),
              LibraryModeToggle(
                selected: _mode,
                onChanged: _onModeChanged,
              ),
              const SizedBox(height: 16),
              CategoryChipsRow(
                categories: categories,
                selectedId: _categoryId,
                onSelected: (id) => setState(() => _categoryId = id),
              ),
              if (featured != null &&
                  _query.trim().isEmpty &&
                  (_categoryId == 'all' || featured.categoryId == _categoryId)) ...[
                const SizedBox(height: 24),
                FeaturedDrillCard(
                  drill: featured,
                  onTap: () => _openDrill(featured),
                ),
              ],
              const SizedBox(height: 28),
              DrillList(
                drills: listDrills,
                onDrillTap: _openDrill,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
