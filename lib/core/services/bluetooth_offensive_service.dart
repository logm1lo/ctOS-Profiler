import 'dart:developer' as developer;
import 'package:flutter/services.dart';

enum BleSpamType { apple, samsung, google }

class BluetoothOffensiveService {
  static const String TAG = "BluetoothOffensiveService";
  static const MethodChannel _channel = MethodChannel('com.logm1lo.ctos/bt_offensive');

  Future<void> startBleSpam(BleSpamType type) async {
    developer.log('[startBleSpam] → Entry: type=${type.name}', name: TAG);
    try {
      await _channel.invokeMethod('startBleSpam', {'type': type.name});
      developer.log('[startBleSpam] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[startBleSpam] → Error: Failed to start BLE spam: $e', name: TAG, error: e);
      rethrow;
    }
  }

  Future<void> stopBleSpam() async {
    developer.log('[stopBleSpam] → Entry', name: TAG);
    try {
      await _channel.invokeMethod('stopBleSpam');
      developer.log('[stopBleSpam] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[stopBleSpam] → Error: Failed to stop BLE spam: $e', name: TAG, error: e);
    }
  }

  Future<void> startFastPairExploit(String address) async {
    developer.log('[startFastPairExploit] → Entry: address=$address', name: TAG);
    try {
      await _channel.invokeMethod('startFastPairExploit', {'address': address});
      developer.log('[startFastPairExploit] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[startFastPairExploit] → Error: Failed to start Fast Pair exploit: $address, error: $e', name: TAG, error: e);
      rethrow;
    }
  }

  Future<void> startBlueBorneProbe(String address) async {
    developer.log('[startBlueBorneProbe] → Entry: address=$address', name: TAG);
    try {
      await _channel.invokeMethod('startBlueBorneProbe', {'address': address});
      developer.log('[startBlueBorneProbe] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[startBlueBorneProbe] → Error: Failed to start BlueBorne probe: $address, error: $e', name: TAG, error: e);
      rethrow;
    }
  }
}
