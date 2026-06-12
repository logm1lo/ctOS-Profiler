import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DateFormatType { dmy }
enum MeasurementUnit { metric }
enum AppTheme { neonBlack, watchDogs, whiteBlack }
enum ShutterStyle { shutter, hack }

class AppSettings {
  final DateFormatType dateFormat;
  final MeasurementUnit measurementUnit;
  final AppTheme theme;
  final bool showDiagnostics;
  final bool privacyMode;
  final ShutterStyle shutterStyle;
  final String osintApiKey;
  final bool osintTestingMode;

  AppSettings({
    this.dateFormat = DateFormatType.dmy,
    this.measurementUnit = MeasurementUnit.metric,
    this.theme = AppTheme.watchDogs,
    this.showDiagnostics = false,
    this.privacyMode = false,
    this.shutterStyle = ShutterStyle.hack,
    this.osintApiKey = '',
    this.osintTestingMode = true,
  });

  AppSettings copyWith({
    DateFormatType? dateFormat,
    MeasurementUnit? measurementUnit,
    AppTheme? theme,
    bool? showDiagnostics,
    bool? privacyMode,
    ShutterStyle? shutterStyle,
    String? osintApiKey,
    bool? osintTestingMode,
  }) {
    return AppSettings(
      dateFormat: dateFormat ?? this.dateFormat,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      theme: theme ?? this.theme,
      showDiagnostics: showDiagnostics ?? this.showDiagnostics,
      privacyMode: privacyMode ?? this.privacyMode,
      shutterStyle: shutterStyle ?? this.shutterStyle,
      osintApiKey: osintApiKey ?? this.osintApiKey,
      osintTestingMode: osintTestingMode ?? this.osintTestingMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String TAG = "SettingsNotifier";
  static const _keyDateFormat = 'date_format';
  static const _keyMeasurementUnit = 'measurement_unit';
  static const _keyTheme = 'theme';
  static const _keyShowDiagnostics = 'show_diagnostics';
  static const _keyPrivacyMode = 'privacy_mode';
  static const _keyShutterStyle = 'shutter_style';
  static const _keyOsintApiKey = 'osint_api_key';
  static const _keyOsintTestingMode = 'osint_testing_mode';

  SettingsNotifier() : super(AppSettings()) {
    developer.log('ctOS_TRACE: SettingsNotifier instance created', name: TAG);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    developer.log('[_loadSettings] → Entry', name: TAG);
    try {
      final prefs = await SharedPreferences.getInstance();
      state = AppSettings(
        dateFormat: DateFormatType.values[prefs.getInt(_keyDateFormat) ?? DateFormatType.dmy.index],
        measurementUnit: MeasurementUnit.values[prefs.getInt(_keyMeasurementUnit) ?? MeasurementUnit.metric.index],
        theme: AppTheme.values[prefs.getInt(_keyTheme) ?? AppTheme.watchDogs.index],
        showDiagnostics: prefs.getBool(_keyShowDiagnostics) ?? false,
        privacyMode: prefs.getBool(_keyPrivacyMode) ?? false,
        shutterStyle: ShutterStyle.values[prefs.getInt(_keyShutterStyle) ?? ShutterStyle.hack.index],
        osintApiKey: prefs.getString(_keyOsintApiKey) ?? '',
        osintTestingMode: prefs.getBool(_keyOsintTestingMode) ?? true,
      );
      developer.log('[_loadSettings] → Exit: Current theme is ${state.theme}', name: TAG);
    } catch (e) {
      developer.log('[_loadSettings] → Error: $e', name: TAG, error: e);
    }
  }

  void setDateFormat(DateFormatType format) {
    developer.log('[setDateFormat] → Entry: format=$format', name: TAG);
    state = state.copyWith(dateFormat: format);
    _saveInt(_keyDateFormat, format.index);
  }

  void setMeasurementUnit(MeasurementUnit unit) {
    developer.log('[setMeasurementUnit] → Entry: unit=$unit', name: TAG);
    state = state.copyWith(measurementUnit: unit);
    _saveInt(_keyMeasurementUnit, unit.index);
  }

  void setTheme(AppTheme theme) {
    developer.log('[setTheme] → Entry: theme=$theme', name: TAG);
    state = state.copyWith(theme: theme);
    _saveInt(_keyTheme, theme.index);
    developer.log('[setTheme] → Exit: Global HUD theme updated', name: TAG);
  }

  void toggleDiagnostics() {
    final newValue = !state.showDiagnostics;
    developer.log('[toggleDiagnostics] → Entry: current=${state.showDiagnostics}, target=$newValue', name: TAG);
    state = state.copyWith(showDiagnostics: newValue);
    _saveBool(_keyShowDiagnostics, newValue);
  }

  void togglePrivacyMode() {
    final newValue = !state.privacyMode;
    developer.log('[togglePrivacyMode] → Entry: current=${state.privacyMode}, target=$newValue', name: TAG);
    state = state.copyWith(privacyMode: newValue);
    _saveBool(_keyPrivacyMode, newValue);
  }

  void setShutterStyle(ShutterStyle style) {
    developer.log('[setShutterStyle] → Entry: style=$style', name: TAG);
    state = state.copyWith(shutterStyle: style);
    _saveInt(_keyShutterStyle, style.index);
  }

  Future<void> setOsintApiKey(String key) async {
    developer.log('[setOsintApiKey] → Entry: length=${key.length}', name: TAG);
    state = state.copyWith(osintApiKey: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOsintApiKey, key);
    developer.log('[setOsintApiKey] → Exit: Token persistent storage updated', name: TAG);
  }

  void toggleOsintTestingMode() {
    final newValue = !state.osintTestingMode;
    developer.log('[toggleOsintTestingMode] → Entry: current=${state.osintTestingMode}, target=$newValue', name: TAG);
    state = state.copyWith(osintTestingMode: newValue);
    _saveBool(_keyOsintTestingMode, newValue);
  }

  Future<void> _saveInt(String key, int value) async {
    developer.log('[_saveInt] → Saving key=$key, value=$value', name: TAG);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    developer.log('[_saveBool] → Saving key=$key, value=$value', name: TAG);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
