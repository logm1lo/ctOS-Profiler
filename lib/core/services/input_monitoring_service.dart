import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

class InputMonitoringService {
  static const String TAG = "InputMonitoringService";
  static const MethodChannel _channel = MethodChannel('com.logm1lo.ctos/accessibility');

  static final StreamController<String> _logController = StreamController<String>.broadcast();
  static Stream<String> get logStream => _logController.stream;

  static Future<bool> isEnabled() async {
    developer.log('[isEnabled] → Entry', name: TAG);
    try {
      final bool result = await _channel.invokeMethod('isAccessibilityEnabled');
      developer.log('[isEnabled] → Exit: result=$result', name: TAG);
      return result;
    } catch (e) {
      developer.log('[isEnabled] → Error: $e', name: TAG, error: e);
      return false;
    }
  }

  static Future<void> requestPermission() async {
    developer.log('[requestPermission] → Entry', name: TAG);
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
      developer.log('[requestPermission] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[requestPermission] → Error: $e', name: TAG, error: e);
    }
  }

  // This would be called from the native side via MethodChannel
  static void onEventReceived(String event) {
    developer.log('[onEventReceived] → Entry: event=$event', name: TAG);
    _logController.add(event);
    developer.log('[onEventReceived] → Exit: Event added to stream', name: TAG);
  }
}
