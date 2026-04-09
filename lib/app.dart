import 'package:flutter/material.dart';
import 'core/theme/colors.dart';
import 'presentation/home/home_screen.dart';

class CtOSApp extends StatelessWidget {
  const CtOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ctOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.cyanAccent,
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.cyanAccent,
          secondary: AppColors.cyanAccent,
          surface: AppColors.background,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
