import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class MarocFlyApp extends StatelessWidget {
  const MarocFlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MarocFly AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
