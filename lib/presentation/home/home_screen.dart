import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/osint_service.dart';
import '../camera/camera_screen.dart';
import '../gallery/registered_faces_screen.dart';
import '../shared/neon_button.dart';
import '../tools/tools_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const String TAG = "HomeScreen";
  String _locationText = 'LOCATING...';
  String _batteryText = 'SYNCING_POWER...';
  final Battery _battery = Battery();
  StreamSubscription<ServiceStatus>? _locationServiceSubscription;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    _updateLocation();
    _updateBattery();
  }

  Future<void> _updateLocation() async {
    developer.log('[_updateLocation] → Entry', name: TAG);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      developer.log('[_updateLocation] → Status: Location services disabled', name: TAG);
      if (mounted) setState(() => _locationText = 'LOCATION_SERVICES_DISABLED');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      developer.log('[_updateLocation] → Status: Requesting permissions', name: TAG);
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        developer.log('[_updateLocation] → Status: Permission denied by user', name: TAG);
        if (mounted) setState(() => _locationText = 'PERMISSION_DENIED');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      developer.log('[_updateLocation] → Status: Permission denied permanently', name: TAG);
      if (mounted) setState(() => _locationText = 'PERMISSION_DENIED_PERMANENTLY');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) {
        setState(() {
          final lat = position.latitude.abs().toStringAsFixed(4).replaceAll('.', '');
          final long = position.longitude.abs().toStringAsFixed(4).replaceAll('.', '');
          _locationText = '0x${int.parse(lat).toRadixString(16).toUpperCase()} : 0x${int.parse(long).toRadixString(16).toUpperCase()}';
        });
      }
      developer.log('[_updateLocation] → Exit: Coords acquired and obfuscated', name: TAG);
    } catch (e) {
      developer.log('[_updateLocation] → Error: $e', name: TAG, error: e);
      if (mounted) setState(() => _locationText = 'SIGNAL_LOST');
    }
  }

  Future<void> _updateBattery() async {
    developer.log('[_updateBattery] → Entry', name: TAG);
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryText = 'PWR_LVL: $level%';
        });
      }
      developer.log('[_updateBattery] → Exit: level=$level%', name: TAG);
    } catch (e) {
      developer.log('[_updateBattery] → Error: $e', name: TAG, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // developer.log('[build] → Entry', name: TAG);
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.security, color: accentColor, size: 80),
                        const SizedBox(height: 20),
                        Text(
                          'ctOS v1.1.0',
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

                  NeonButton(
                    label: 'SEARCH',
                    icon: Icons.search,
                    onPressed: () {
                      developer.log('[Navigation] → Requesting CameraScreen', name: TAG);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CameraScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  NeonButton(
                    label: 'TOOLS',
                    icon: Icons.grid_view,
                    onPressed: () {
                      developer.log('[Navigation] → Requesting ToolsScreen', name: TAG);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ToolsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  NeonButton(
                    label: 'PROFILES',
                    icon: Icons.person_search,
                    onPressed: () {
                      developer.log('[Navigation] → Requesting RegisteredFacesScreen', name: TAG);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisteredFacesScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 60),

                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'SYSTEM STATUS: ONLINE',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _batteryText,
                            style: TextStyle(color: accentColor.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'GRID_COORD: $_locationText',
                        style: TextStyle(color: accentColor, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.settings, color: accentColor),
              onPressed: () {
                developer.log('[Interaction] → Opening System Settings', name: TAG);
                _showSettingsDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }
}

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  static const String TAG = "SettingsDialog";
  late TextEditingController _apiKeyController;
  bool _isValidating = false;
  String? _validationError;
  bool _isValidated = false;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    final currentKey = ref.read(settingsProvider).osintApiKey;
    _apiKeyController = TextEditingController(text: currentKey);
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSaveKey() async {
    developer.log('[_validateAndSaveKey] → Entry', name: TAG);
    setState(() {
      _isValidating = true;
      _validationError = null;
      _isValidated = false;
    });

    final key = _apiKeyController.text.trim();
    developer.log('[_validateAndSaveKey] → Validating token format/existence', name: TAG);
    final isValid = await OSINTService().validateToken(key);

    if (isValid) {
      developer.log('[_validateAndSaveKey] → Token valid, persisting to store', name: TAG);
      await ref.read(settingsProvider.notifier).setOsintApiKey(key);
      setState(() {
        _isValidated = true;
      });
    } else {
      developer.log('[_validateAndSaveKey] → Warning: Token rejected by provider', name: TAG);
      setState(() {
        _validationError = 'INVALID API TOKEN';
      });
    }

    setState(() {
      _isValidating = false;
    });
    developer.log('[_validateAndSaveKey] → Exit', name: TAG);
  }

  @override
  Widget build(BuildContext context) {
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
                onChanged: (val) {
                  developer.log('[ThemeSelector] → Target: $val', name: TAG);
                  ref.read(settingsProvider.notifier).setTheme(val!);
                },
              ),
              const SizedBox(height: 20),
              _buildSwitchTile('SHOW DIAGNOSTICS', settings.showDiagnostics,
                (_) => ref.read(settingsProvider.notifier).toggleDiagnostics(), theme, accentColor, textColor),
              _buildSwitchTile('PRIVACY MODE (BLUR)', settings.privacyMode,
                (_) => ref.read(settingsProvider.notifier).togglePrivacyMode(), theme, accentColor, textColor),
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
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              Text('OSINT API CONFIGURATION', style: AppTextStyles.title(theme).copyWith(fontSize: 14, color: accentColor)),
              const SizedBox(height: 10),
              TextField(
                controller: _apiKeyController,
                style: TextStyle(color: textColor, fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'FACECHECK.ID API KEY',
                  labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 10),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
                  suffixIcon: _isValidating
                    ? SizedBox(width: 20, height: 20, child: Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)))
                    : (_isValidated ? const Icon(Icons.check_circle, color: Colors.green) : null),
                ),
              ),
              if (_validationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_validationError!, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isValidating ? null : _validateAndSaveKey,
                  style: OutlinedButton.styleFrom(side: BorderSide(color: accentColor)),
                  child: Text('SAVE & VALIDATE KEY', style: TextStyle(color: accentColor, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 10),
              _buildSwitchTile(
                'TESTING MODE (NO CREDITS)',
                settings.osintTestingMode,
                (_) => ref.read(settingsProvider.notifier).toggleOsintTestingMode(),
                theme, accentColor, textColor
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  'Scans 100k faces instead of billions.',
                  style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 8, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CLOSE', style: TextStyle(color: accentColor)),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged, AppTheme theme, Color accent, Color textColor) {
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
          onChanged: (val) {
            developer.log('[Switch] → $title toggled to $val', name: TAG);
            onChanged(val);
          },
          activeThumbColor: activeColor,
          activeTrackColor: activeColor.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
