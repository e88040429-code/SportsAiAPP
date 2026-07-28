import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/sport/app_sport.dart';
import 'core/theme/app_theme.dart';

class SetPointApp extends StatelessWidget {
  const SetPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSportController,
      builder: (context, _) {
        return MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.forSport(appSportController.sport),
          routerConfig: appRouter,
        );
      },
    );
  }
}
