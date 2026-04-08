import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';
import 'colors.dart';

class AppTextStyles {
  static TextStyle baseMonospace(AppTheme theme) => TextStyle(
    fontFamily: 'monospace',
    color: AppColors.getAccent(theme),
  );

  static TextStyle title(AppTheme theme) => baseMonospace(theme).copyWith(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 4.0,
    color: AppColors.getAccent(theme),
  );

  static TextStyle body(AppTheme theme) => baseMonospace(theme).copyWith(
    fontSize: 16,
    color: AppColors.getText(theme),
  );

  static TextStyle label(AppTheme theme) => baseMonospace(theme).copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle hudStatus(AppTheme theme) => baseMonospace(theme).copyWith(
    fontSize: 12,
    letterSpacing: 2.0,
    color: AppColors.getAccent(theme),
  );

  static TextStyle matchResult(AppTheme theme) => baseMonospace(theme).copyWith(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.getAccent(theme),
  );

  static TextStyle warning(AppTheme theme) => baseMonospace(theme).copyWith(
    fontSize: 16,
    color: AppColors.amberWarning,
  );
}
