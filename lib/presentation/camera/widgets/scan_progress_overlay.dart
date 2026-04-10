import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class ScanProgressOverlay extends ConsumerWidget {
  final double progress;
  final String status;
  final String? result;

  const ScanProgressOverlay({
    super.key,
    required this.progress,
    required this.status,
    this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    // Use a darker, less intrusive overlay background
    final backgroundColor = Colors.black.withValues(alpha: 0.4);

    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.toUpperCase(),
              style: AppTextStyles.title(theme).copyWith(
                fontSize: 18,
                color: theme == AppTheme.whiteBlack ? Colors.white : accentColor,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 250,
              height: 4,
              decoration: BoxDecoration(
                color: theme == AppTheme.whiteBlack ? Colors.white.withValues(alpha: 0.2) : AppColors.getSurface(theme),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme == AppTheme.whiteBlack ? Colors.white : accentColor,
                    boxShadow: [
                      if (theme == AppTheme.neonBlack)
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (result != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme == AppTheme.watchDogs
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.getSurface(theme).withValues(alpha: 0.8),
                  border: Border.all(color: accentColor, width: 2),
                ),
                child: Text(
                  result!,
                  style: AppTextStyles.matchResult(theme).copyWith(
                    color: theme == AppTheme.watchDogs ? Colors.black : accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (progress >= 1.0 && result == null)
              Icon(Icons.check_circle_outline, color: accentColor, size: 40),
          ],
        ),
      ),
    );
  }
}
