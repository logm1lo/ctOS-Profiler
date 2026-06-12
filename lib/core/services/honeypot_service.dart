import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

class HoneypotService {
  static const String TAG = "HoneypotService";
  static const MethodChannel _channel = MethodChannel('com.logm1lo.ctos/honeypot');

  Future<bool> startHotspot(String ssid) async {
    developer.log('[startHotspot] → Entry: ssid=$ssid', name: TAG);
    try {
      final bool result = await _channel.invokeMethod('startHotspot', {'ssid': ssid});
      developer.log('[startHotspot] → Exit: result=$result', name: TAG);
      return result;
    } catch (e) {
      developer.log('[startHotspot] → Error: Failed to start hotspot: $e', name: TAG, error: e);
      return false;
    }
  }

  Future<void> stopHotspot() async {
    developer.log('[stopHotspot] → Entry', name: TAG);
    try {
      await _channel.invokeMethod('stopHotspot');
      developer.log('[stopHotspot] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[stopHotspot] → Error: Failed to stop hotspot: $e', name: TAG, error: e);
    }
  }
}
