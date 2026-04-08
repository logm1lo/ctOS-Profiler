import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class GlitchyButton extends ConsumerStatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const GlitchyButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  ConsumerState<GlitchyButton> createState() => _GlitchyButtonState();
}

class _GlitchyButtonState extends ConsumerState<GlitchyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  Timer? _glitchTimer;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _startGlitchCycle();
  }

  void _startGlitchCycle() {
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_random.nextDouble() > 0.7) {
        if (mounted) {
          setState(() => _isGlitching = true);
          _controller.forward(from: 0).then((_) {
            if (mounted) setState(() => _isGlitching = false);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final secondaryColor = theme == AppTheme.neonBlack ? Colors.redAccent : AppColors.secondaryWD;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double offset = _isGlitching ? (_random.nextDouble() * 10 - 5) : 0;
        final double opacity = _isGlitching ? (_random.nextDouble() * 0.5 + 0.5) : 1.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (_isGlitching) ...[
              Transform.translate(
                offset: Offset(offset, 0),
                child: _buildButton(context, accentColor.withOpacity(0.3), theme, accentColor),
              ),
              Transform.translate(
                offset: Offset(-offset, 0),
                child: _buildButton(context, secondaryColor.withOpacity(0.3), theme, accentColor),
              ),
            ],
            Opacity(
              opacity: opacity,
              child: _buildButton(context, Colors.transparent, theme, accentColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton(BuildContext context, Color overlayColor, AppTheme theme, Color accentColor) {
    final baseColor = overlayColor.alpha > 0 ? overlayColor : accentColor;
    return OutlinedButton(
      onPressed: widget.onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: accentColor.withOpacity(0.1).withAlpha((overlayColor.alpha > 0) ? overlayColor.alpha : 25),
        side: BorderSide(color: baseColor, width: 2),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        widget.label,
        style: AppTextStyles.hudStatus(theme).copyWith(
          color: baseColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
