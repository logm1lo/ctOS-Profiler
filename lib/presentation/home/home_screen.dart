import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../camera/camera_screen.dart';
import '../gallery/registered_faces_screen.dart';
import '../shared/neon_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background "ctOS" watermark
          Positioned(
            bottom: -50,
            right: -50,
            child: Opacity(
              opacity: 0.05,
              child: Text(
                'ctOS',
                style: AppTextStyles.title(theme).copyWith(fontSize: 200, color: accentColor),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.security,
                          color: accentColor,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ctOS v1.0.1',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'CENTRAL OPERATING SYSTEM',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            letterSpacing: 2.0,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),

                  // Main Buttons
                  NeonButton(
                    label: 'SEARCH',
                    icon: Icons.search,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CameraScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  NeonButton(
                    label: 'PROFILES',
                    icon: Icons.person_search,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisteredFacesScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 60),

                  // Footer info
                  Column(
                    children: [
                      const Text(
                        'SYSTEM STATUS: CONNECTED',
                        style: TextStyle(color: Colors.green, fontSize: 10, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PROXIMATED LOCATION: 41.8781° N, 87.6298° W (CHICAGO)',
                        style: TextStyle(color: accentColor, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),

          // Settings Button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.settings, color: accentColor),
              onPressed: () => _showSettingsDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }
}

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final dialogBg = AppColors.getBackground(theme);
    final textColor = AppColors.getText(theme);

    return AlertDialog(
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(side: BorderSide(color: accentColor)),
      title: Text('SYSTEM_SETTINGS', style: AppTextStyles.title(theme).copyWith(fontSize: 18, color: accentColor)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SYSTEM THEME', style: AppTextStyles.hudStatus(theme).copyWith(color: textColor.withValues(alpha: 0.6))),
              DropdownButton<AppTheme>(
                value: settings.theme,
                isExpanded: true,
                dropdownColor: dialogBg,
                style: TextStyle(color: textColor),
                items: AppTheme.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t == AppTheme.neonBlack ? 'NEON-BLACK' : (t == AppTheme.watchDogs ? 'WATCH-DOGS (B/W)' : 'WHITE-BLACK')),
                )).toList(),
                onChanged: (val) => ref.read(settingsProvider.notifier).setTheme(val!),
              ),
              const SizedBox(height: 20),
              _buildSwitchTile('SHOW DIAGNOSTICS', settings.showDiagnostics,
                (_) => ref.read(settingsProvider.notifier).toggleDiagnostics(), theme, accentColor, textColor, ref),
              _buildSwitchTile('PRIVACY MODE (BLUR)', settings.privacyMode,
                (_) => ref.read(settingsProvider.notifier).togglePrivacyMode(), theme, accentColor, textColor, ref),
              const SizedBox(height: 20),
              Text('SHUTTER STYLE', style: AppTextStyles.hudStatus(theme).copyWith(color: textColor.withValues(alpha: 0.6))),
              DropdownButton<ShutterStyle>(
                value: settings.shutterStyle,
                isExpanded: true,
                dropdownColor: dialogBg,
                style: TextStyle(color: textColor),
                items: ShutterStyle.values.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name.toUpperCase()),
                )).toList(),
                onChanged: (val) => ref.read(settingsProvider.notifier).setShutterStyle(val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Placeholder for save logic if persistent storage is added later
            // For now it just closes the dialog as settings are updated via providers
            Navigator.pop(context);
          },
          child: Text('SAVE', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CLOSE', style: TextStyle(color: accentColor)),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged, AppTheme theme, Color accent, Color textColor, WidgetRef ref) {
    final activeColor = theme == AppTheme.watchDogs ? AppColors.secondaryWD : accent;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.hudStatus(theme).copyWith(color: textColor.withValues(alpha: 0.6)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeColor,
          activeTrackColor: activeColor.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
