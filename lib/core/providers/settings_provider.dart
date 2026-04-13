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

  AppSettings({
    this.dateFormat = DateFormatType.dmy,
    this.measurementUnit = MeasurementUnit.metric,
    this.theme = AppTheme.watchDogs,
    this.showDiagnostics = false,
    this.privacyMode = false,
    this.shutterStyle = ShutterStyle.hack,
  });

  AppSettings copyWith({
    DateFormatType? dateFormat,
    MeasurementUnit? measurementUnit,
    AppTheme? theme,
    bool? showDiagnostics,
    bool? privacyMode,
    ShutterStyle? shutterStyle,
  }) {
    return AppSettings(
      dateFormat: dateFormat ?? this.dateFormat,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      theme: theme ?? this.theme,
      showDiagnostics: showDiagnostics ?? this.showDiagnostics,
      privacyMode: privacyMode ?? this.privacyMode,
      shutterStyle: shutterStyle ?? this.shutterStyle,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const _keyDateFormat = 'date_format';
  static const _keyMeasurementUnit = 'measurement_unit';
  static const _keyTheme = 'theme';
  static const _keyShowDiagnostics = 'show_diagnostics';
  static const _keyPrivacyMode = 'privacy_mode';
  static const _keyShutterStyle = 'shutter_style';

  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      dateFormat: DateFormatType.values[prefs.getInt(_keyDateFormat) ?? DateFormatType.dmy.index],
      measurementUnit: MeasurementUnit.values[prefs.getInt(_keyMeasurementUnit) ?? MeasurementUnit.metric.index],
      theme: AppTheme.values[prefs.getInt(_keyTheme) ?? AppTheme.watchDogs.index],
      showDiagnostics: prefs.getBool(_keyShowDiagnostics) ?? false,
      privacyMode: prefs.getBool(_keyPrivacyMode) ?? false,
      shutterStyle: ShutterStyle.values[prefs.getInt(_keyShutterStyle) ?? ShutterStyle.hack.index],
    );
  }

  void setDateFormat(DateFormatType format) {
    state = state.copyWith(dateFormat: format);
    _saveInt(_keyDateFormat, format.index);
  }

  void setMeasurementUnit(MeasurementUnit unit) {
    state = state.copyWith(measurementUnit: unit);
    _saveInt(_keyMeasurementUnit, unit.index);
  }

  void setTheme(AppTheme theme) {
    state = state.copyWith(theme: theme);
    _saveInt(_keyTheme, theme.index);
  }

  void toggleDiagnostics() {
    final newValue = !state.showDiagnostics;
    state = state.copyWith(showDiagnostics: newValue);
    _saveBool(_keyShowDiagnostics, newValue);
  }

  void togglePrivacyMode() {
    final newValue = !state.privacyMode;
    state = state.copyWith(privacyMode: newValue);
    _saveBool(_keyPrivacyMode, newValue);
  }

  void setShutterStyle(ShutterStyle style) {
    state = state.copyWith(shutterStyle: style);
    _saveInt(_keyShutterStyle, style.index);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
