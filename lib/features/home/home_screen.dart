import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/sport/app_sport.dart';
import 'data/home_mock_data.dart';
import 'widgets/common_skills_row.dart';
import 'widgets/continue_learning_list.dart';
import 'widgets/home_header.dart';
import 'widgets/metric_cards_row.dart';
import 'widgets/todays_session_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appSportController,
          builder: (context, _) {
            final sport = appSportController.sport;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHeader(
                    user: HomeMockData.user,
                    sport: sport,
                  ),
                  const SizedBox(height: 20),
                  MetricCardsRow(metrics: HomeMockData.metricsFor(sport)),
                  const SizedBox(height: 24),
                  TodaysSessionCard(
                    session: HomeMockData.todaysSessionFor(sport),
                    onPlay: () => context.go('/coach'),
                  ),
                  const SizedBox(height: 28),
                  CommonSkillsRow(
                    skills: HomeMockData.commonSkillsFor(sport),
                    onSkillTap: (skill) =>
                        context.push('/library/drill/${skill.id}'),
                  ),
                  const SizedBox(height: 28),
                  ContinueLearningList(
                    items: HomeMockData.continueLearningFor(sport),
                    onItemTap: (item) =>
                        context.push('/library/drill/${item.id}'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
