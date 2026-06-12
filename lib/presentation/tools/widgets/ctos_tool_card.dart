import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class CtosToolCard extends ConsumerStatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CtosToolCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  ConsumerState<CtosToolCard> createState() => _CtosToolCardState();
}

class _CtosToolCardState extends ConsumerState<CtosToolCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  Timer? _glitchTimer;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _startGlitchCycle();
  }

  void _startGlitchCycle() {
    _glitchTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_random.nextDouble() > 0.8) {
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
    final theme = ref.watch(settingsProvider).theme;
    final secondaryColor = theme == AppTheme.neonBlack ? Colors.redAccent : AppColors.secondaryWD;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double offset = _isGlitching ? (_random.nextDouble() * 8 - 4) : 0;
        final double opacity = _isGlitching ? (_random.nextDouble() * 0.3 + 0.7) : 1.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_isGlitching) ...[
              Transform.translate(
                offset: Offset(offset, offset / 2),
                child: _buildCard(widget.color.withValues(alpha: 0.3), theme, isInteractive: false),
              ),
              Transform.translate(
                offset: Offset(-offset, -offset / 2),
                child: _buildCard(secondaryColor.withValues(alpha: 0.3), theme, isInteractive: false),
              ),
            ],
            Opacity(
              opacity: opacity,
              child: _buildCard(widget.color, theme, isInteractive: true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(Color color, AppTheme theme, {required bool isInteractive}) {
    return GestureDetector(
      onTap: isInteractive ? widget.onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          color: color.withValues(alpha: 0.05),
          boxShadow: [
            if (_isGlitching)
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
          ],
        ),
        child: Stack(
          children: [
            // Corner Decoration
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: color, width: 2),
                    left: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: color, width: 2),
                    right: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: color, size: 32),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.hudStatus(theme).copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.7),
                    fontSize: 7,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
