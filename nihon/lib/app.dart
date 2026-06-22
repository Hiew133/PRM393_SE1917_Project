import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/welcome/welcome_screen.dart';

/// Widget gốc của app さくら.
class SakuraApp extends StatelessWidget {
  const SakuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'さくら – Japanese Learning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WelcomeScreen(),
    );
  }
}
