import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';

class AppColors {
  // Original Neon Theme
  static const Color backgroundNeon = Color(0xFF0A0A0A);
  static const Color cyanAccent = Color(0xFF00FFFF);
  static const Color amberWarning = Color(0xFFFFBF00);
  static const Color darkGreyNeon = Color(0xFF1A1A1A);
  static const Color lightGreyNeon = Color(0xFFCCCCCC);

  // Watch Dogs Black-White Theme
  static const Color backgroundWD = Color(0xFF0F0F0F);
  static const Color accentWD = Color(0xFFFFFFFF);
  static const Color secondaryWD = Color(0xFF00A0FF); // Light blue/cyan
  static const Color darkGreyWD = Color(0xFF1E1E1E);
  static const Color lightGreyWD = Color(0xFFDDDDDD);

  // White-Black Theme
  static const Color backgroundWB = Color(0xFFF0F0F0);
  static const Color accentWB = Color(0xFF000000);
  static const Color darkGreyWB = Color(0xFFE0E0E0);
  static const Color lightGreyWB = Color(0xFF333333);

  static Color getBackground(AppTheme theme) {
    switch (theme) {
      case AppTheme.neonBlack: return backgroundNeon;
      case AppTheme.watchDogs: return backgroundWD;
      case AppTheme.whiteBlack: return backgroundWB;
    }
  }

  static Color getAccent(AppTheme theme) {
    switch (theme) {
      case AppTheme.neonBlack: return cyanAccent;
      case AppTheme.watchDogs: return accentWD;
      case AppTheme.whiteBlack: return accentWB;
    }
  }

  static Color getSecondaryAccent(AppTheme theme) {
    switch (theme) {
      case AppTheme.neonBlack: return amberWarning;
      case AppTheme.watchDogs: return secondaryWD;
      case AppTheme.whiteBlack: return secondaryWD;
    }
  }

  static Color getSurface(AppTheme theme) {
    switch (theme) {
      case AppTheme.neonBlack: return darkGreyNeon;
      case AppTheme.watchDogs: return darkGreyWD;
      case AppTheme.whiteBlack: return darkGreyWB;
    }
  }

  static Color getText(AppTheme theme) {
    switch (theme) {
      case AppTheme.neonBlack: return lightGreyNeon;
      case AppTheme.watchDogs: return lightGreyWD;
      case AppTheme.whiteBlack: return lightGreyWB;
    }
  }
  static Color getScanLine(AppTheme theme) => (theme == AppTheme.neonBlack ? cyanAccent : secondaryWD).withValues(alpha: 0.3);

  // Constants (for now, will refactor to use getters)
  static const Color background = Color(0xFF0A0A0A);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const Color lightGrey = Color(0xFFCCCCCC);
  static const Color scanLine = Color(0x4D00FFFF);
}
