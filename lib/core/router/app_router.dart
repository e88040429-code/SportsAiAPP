import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_response/ai_response_screen.dart';
import '../../features/coach/coach_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/library/drill_detail_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/recap/recap_screen.dart';
import '../../features/rehab/rehab_screen.dart';
import '../../features/sports/sports_screen.dart';
import '../sport/app_sport.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/sports',
  routes: [
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/sports',
      name: 'sports',
      builder: (context, state) => const SportsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/ai',
      name: 'ai',
      builder: (context, state) => const AiResponseScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              name: 'library',
              builder: (context, state) => const LibraryScreen(),
              routes: [
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'drill/:drillId',
                  name: 'drillDetail',
                  builder: (context, state) {
                    final drillId = state.pathParameters['drillId'] ?? 'unknown';
                    return DrillDetailScreen(drillId: drillId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/coach',
              name: 'coach',
              builder: (context, state) => const CoachScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ask',
              name: 'ask',
              builder: (context, state) => const AiResponseScreen(
                lockedSport: AppSport.volleyball,
                title: 'Ask Volleyball',
                hintText: 'Ask anything about volleyball…',
                qaMode: true,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recap',
              name: 'recap',
              builder: (context, state) => const RecapScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/rehab',
              name: 'rehab',
              builder: (context, state) => const RehabScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_volleyball_outlined),
            selectedIcon: Icon(Icons.sports_volleyball),
            label: 'Ask AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Recap',
          ),
          NavigationDestination(
            icon: Icon(Icons.healing_outlined),
            selectedIcon: Icon(Icons.healing),
            label: 'Rehab',
          ),
        ],
      ),
    );
  }
}
