import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkDevice {
  final String ip;
  final String? hostname;
  final List<int> openPorts;
  final String? vendor;
  final String? macAddress;

  NetworkDevice({
    required this.ip,
    this.hostname,
    this.openPorts = const [],
    this.vendor,
    this.macAddress,
  });
}

class NetworkService {
  static const String TAG = "NetworkService";
  final _info = NetworkInfo();

  Future<String?> getLocalIp() async {
    developer.log('[getLocalIp] → Entry', name: TAG);
    final ip = await _info.getWifiIP();
    developer.log('[getLocalIp] → Exit: ip=$ip', name: TAG);
    return ip;
  }

  Future<String?> getSubnetMask() async {
    developer.log('[getSubnetMask] → Entry', name: TAG);
    final mask = await _info.getWifiSubmask();
    developer.log('[getSubnetMask] → Exit: mask=$mask', name: TAG);
    return mask;
  }

  Future<String?> getBroadcastIp() async {
    developer.log('[getBroadcastIp] → Entry', name: TAG);
    final broadcast = await _info.getWifiBroadcast();
    developer.log('[getBroadcastIp] → Exit: broadcast=$broadcast', name: TAG);
    return broadcast;
  }

  Stream<NetworkDevice> discoverDevices(String subnet) async* {
    developer.log('[discoverDevices] → Entry: subnet=$subnet.0/24', name: TAG);
    // Faster concurrent scanning
    final List<Future<NetworkDevice?>> futures = [];
    for (int i = 1; i < 255; i++) {
      final host = '$subnet.$i';
      futures.add(_checkDevice(host));
    }

    developer.log('[discoverDevices] → Status: Waiting for host discovery', name: TAG);
    final results = await Future.wait(futures);
    int discoveredCount = 0;
    for (var device in results) {
      if (device != null) {
        discoveredCount++;
        yield device;
      }
    }
    developer.log('[discoverDevices] → Exit: Scan complete, found $discoveredCount nodes', name: TAG);
  }

  Future<NetworkDevice?> _checkDevice(String ip) async {
    developer.log('[_checkDevice] → Entry: ip=$ip', name: TAG);
    final commonPorts = [80, 443, 22, 554, 8554];
    List<int> foundPorts = [];

    for (var port in commonPorts) {
      try {
        final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 300));
        socket.destroy();
        foundPorts.add(port);
      } catch (_) {}
    }

    if (foundPorts.isNotEmpty) {
      developer.log('[_checkDevice] → Host $ip is active (ports=$foundPorts)', name: TAG);
      String? hostname;
      try {
        final result = await InternetAddress(ip).reverse();
        hostname = result.host;
        developer.log('[_checkDevice] → Resolved hostname for $ip: $hostname', name: TAG);
      } catch (_) {}

      final device = NetworkDevice(
        ip: ip,
        openPorts: foundPorts,
        hostname: hostname,
        vendor: null,
        macAddress: null,
      );
      developer.log('[_checkDevice] → Exit: Device identified', name: TAG);
      return device;
    }

    // developer.log('[_checkDevice] → Exit: No response from $ip', name: TAG);
    return null;
  }

  Future<List<int>> scanPorts(String ip) async {
    developer.log('[scanPorts] → Entry: ip=$ip', name: TAG);
    final List<int> commonPorts = [21, 22, 23, 80, 443, 445, 554, 3389, 8080, 8554];
    final List<int> openPorts = [];

    for (var port in commonPorts) {
      try {
        final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 300));
        socket.destroy();
        openPorts.add(port);
        developer.log('[scanPorts] → Port $port is OPEN on $ip', name: TAG);
      } catch (_) {}
    }
    developer.log('[scanPorts] → Exit: Found ${openPorts.length} open ports', name: TAG);
    return openPorts;
  }
}
