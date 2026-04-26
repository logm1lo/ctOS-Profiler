import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';

class NeonButton extends ConsumerWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isSecondary;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final accentColor = AppColors.getAccent(settings.theme);
    final backgroundColor = isSecondary ? Colors.transparent : accentColor.withValues(alpha: 0.1);

    return Semantics(
      label: label.toUpperCase(),
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: accentColor,
              width: 2,
            ),
            boxShadow: [
              if (!isSecondary && settings.theme == AppTheme.neonBlack)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.toUpperCase(),
                    style: AppTextStyles.label(settings.theme).copyWith(
                      color: accentColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
