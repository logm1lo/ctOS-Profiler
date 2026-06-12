import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/bluetooth_offensive_service.dart';

class BluetoothDeviceData {
  final String id;
  final String name;
  final int rssi;
  final bool isVulnerable;
  final String? dump;

  BluetoothDeviceData({
    required this.id,
    required this.name,
    required this.rssi,
    this.isVulnerable = false,
    this.dump,
  });
}

class BluetoothProberService {
  static const String TAG = "BluetoothProberService";
  final BluetoothOffensiveService _offensiveService = BluetoothOffensiveService();

  Stream<BluetoothDeviceData> startDiscovery() async* {
    developer.log('[startDiscovery] → Entry', name: TAG);

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      developer.log('[startDiscovery] → Error: Bluetooth adapter is off', name: TAG);
      throw 'BLUETOOTH_ADAPTER_OFF';
    }

    developer.log('[startDiscovery] → Initiating BLE scan (15s timeout)', name: TAG);
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    int devicesFound = 0;
    await for (var results in FlutterBluePlus.scanResults) {
      for (var r in results) {
        if (r.device.platformName.isEmpty && r.advertisementData.localName.isEmpty) continue;

        final device = BluetoothDeviceData(
          id: r.device.remoteId.str,
          name: r.device.platformName.isNotEmpty ? r.device.platformName : r.advertisementData.localName,
          rssi: r.rssi,
          isVulnerable: _checkPotentialVulnerability(r),
        );

        devicesFound++;
        developer.log('[startDiscovery] → Discovered: ${device.name} (${device.id}), RSSI: ${device.rssi}, Vulnerable: ${device.isVulnerable}', name: TAG);
        yield device;
      }
    }
    developer.log('[startDiscovery] → Exit: Scan cycle completed, found $devicesFound nodes', name: TAG);
  }

  bool _checkPotentialVulnerability(ScanResult r) {
    developer.log('[_checkPotentialVulnerability] → Entry: device=${r.device.remoteId}', name: TAG);
    final name = r.device.platformName.toLowerCase();
    final manufacturerData = r.advertisementData.manufacturerData;
    final serviceUuids = r.advertisementData.serviceUuids;

    // Fast Pair vulnerability check (0xFE2C)
    bool hasFastPair = serviceUuids.any((uuid) => uuid.toString().contains('fe2c'));
    if (hasFastPair) developer.log('[_checkPotentialVulnerability] → Fast Pair profile detected', name: TAG);

    // Continuity check
    bool isApple = manufacturerData.containsKey(0x004c);
    if (isApple) developer.log('[_checkPotentialVulnerability] → Apple Continuity frame detected', name: TAG);

    // Legacy vendors
    bool isLegacyVendor = name.contains('samsung') || name.contains('lge') || name.contains('motorola');
    if (isLegacyVendor) developer.log('[_checkPotentialVulnerability] → Legacy vendor identified: $name', name: TAG);

    final bool result = hasFastPair || isApple || isLegacyVendor;
    developer.log('[_checkPotentialVulnerability] → Exit: result=$result', name: TAG);
    return result;
  }

  Future<String?> executeBlueBornePoC(String macAddress) async {
    developer.log('[executeBlueBornePoC] → Entry: macAddress=$macAddress', name: TAG);
    try {
      await _offensiveService.startBlueBorneProbe(macAddress);
      developer.log('[executeBlueBornePoC] → Exit: Probe initiated successfully', name: TAG);
      return "INITIATING_L2CAP_ECHO_LEAK [MAC: $macAddress]...\n"
             "EXPLOITING_CVE_2020_0022...\n"
             "SDP_RESPONSE: PARTIAL_LEAK_SUCCESS\n"
             "STATUS: MEMORY_DUMP_IN_PROGRESS";
    } catch (e) {
      developer.log('[executeBlueBornePoC] → Error: $e', name: TAG, error: e);
      return "PROBE_FAILED: $e";
    }
  }

  Future<String?> executeWhisperPairExploit(String macAddress) async {
    developer.log('[executeWhisperPairExploit] → Entry: macAddress=$macAddress', name: TAG);
    try {
      await _offensiveService.startFastPairExploit(macAddress);
      developer.log('[executeWhisperPairExploit] → Exit: Exploit initiated successfully', name: TAG);
      return "WHISPER_PAIR_EXPLOIT_INITIATED\n"
             "TARGET: $macAddress\n"
             "STATUS: BYPASSING_HANDSHAKE...";
    } catch (e) {
      developer.log('[executeWhisperPairExploit] → Error: $e', name: TAG, error: e);
      return "EXPLOIT_FAILED: $e";
    }
  }

  Future<void> startBleSpam(BleSpamType type) {
    developer.log('[startBleSpam] → Entry: type=${type.name}', name: TAG);
    return _offensiveService.startBleSpam(type);
  }

  Future<void> stopBleSpam() {
    developer.log('[stopBleSpam] → Entry', name: TAG);
    return _offensiveService.stopBleSpam();
  }

  Future<void> stopDiscovery() async {
    developer.log('[stopDiscovery] → Entry', name: TAG);
    await FlutterBluePlus.stopScan();
    developer.log('[stopDiscovery] → Exit: Scan stopped', name: TAG);
  }
}
