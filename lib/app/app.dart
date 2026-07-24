import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

/// Root widget of the IronSight AI application.
class IronSightApp extends StatelessWidget {
  const IronSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IronSight AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: appRoutes,
    );
  }
}
