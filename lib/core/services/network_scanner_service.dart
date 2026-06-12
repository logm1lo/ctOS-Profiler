import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkDevice {
  final String ip;
  final String? hostname;
  final List<int> openPorts;
  final Map<int, String> banners;

  NetworkDevice({required this.ip, this.hostname, this.openPorts = const [], this.banners = const {}});
}

class NetworkScannerService {
  static const String TAG = "NetworkScannerService";
  final NetworkInfo _networkInfo = NetworkInfo();

  Stream<NetworkDevice> scanSubnet({Function(double)? onProgress}) async* {
    developer.log('[scanSubnet] → Entry', name: TAG);
    final String? localIp = await _networkInfo.getWifiIP();
    developer.log('[scanSubnet] → Local IP: $localIp', name: TAG);

    if (localIp == null) {
      developer.log('[scanSubnet] → Exit: Local IP is null, aborting scan', name: TAG);
      return;
    }

    final String subnet = localIp.substring(0, localIp.lastIndexOf('.'));
    final List<int> commonPorts = [22, 23, 80, 443, 445, 554, 8000, 8080, 8554];
    developer.log('[scanSubnet] → Subnet identified: $subnet.0/24', name: TAG);

    int scanned = 0;
    const int total = 254;

    // Use a pool of futures to scan in parallel
    final List<Future<NetworkDevice?>> futures = [];
    for (int i = 1; i <= 254; i++) {
      final String targetIp = '$subnet.$i';
      futures.add(_scanDevice(targetIp, commonPorts).then((device) {
        scanned++;
        onProgress?.call(scanned / total);
        return device;
      }));
    }

    developer.log('[scanSubnet] → Waiting for all scan tasks to complete', name: TAG);
    final results = await Future.wait(futures);
    int devicesFound = 0;
    for (var device in results) {
      if (device != null) {
        devicesFound++;
        yield device;
      }
    }
    developer.log('[scanSubnet] → Exit: Scan completed, found $devicesFound devices', name: TAG);
  }

  Future<NetworkDevice?> _scanDevice(String ip, List<int> ports) async {
    developer.log('[_scanDevice] → Entry: ip=$ip, ports=$ports', name: TAG);
    final List<int> openPorts = [];
    final Map<int, String> banners = {};
    bool isAlive = false;

    // First try a quick ping (ICMP might be blocked, so we also rely on port scan)
    try {
      final socket = await Socket.connect(ip, 80, timeout: const Duration(milliseconds: 300));
      socket.destroy();
      isAlive = true;
      developer.log('[_scanDevice] → Host $ip is alive (port 80)', name: TAG);
    } catch (_) {
      // If port 80 is closed, it might still be alive
    }

    for (int port in ports) {
      try {
        final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 200));
        openPorts.add(port);
        isAlive = true;
        developer.log('[_scanDevice] → Port $port open on $ip', name: TAG);

        // Optional: Banner grabbing
        if (port == 80 || port == 8080 || port == 443) {
          developer.log('[_scanDevice] → Attempting banner grab on $ip:$port', name: TAG);
          socket.write('GET / HTTP/1.0\r\n\r\n');
          final response = await socket.first.timeout(const Duration(milliseconds: 500)).catchError((_) => Uint8List(0));
          if (response.isNotEmpty) {
            final header = String.fromCharCodes(response);
            if (header.contains('Server: ')) {
              final serverLine = header.split('\n').firstWhere((l) => l.startsWith('Server: '), orElse: () => '');
              banners[port] = serverLine.replaceFirst('Server: ', '').trim();
              developer.log('[_scanDevice] → Banner for $ip:$port: ${banners[port]}', name: TAG);
            }
          }
        }
        socket.destroy();
      } catch (_) {}
    }

    if (isAlive) {
      final device = NetworkDevice(ip: ip, openPorts: openPorts, banners: banners);
      developer.log('[_scanDevice] → Exit: Found device ${device.ip} with ${device.openPorts.length} open ports', name: TAG);
      return device;
    }

    developer.log('[_scanDevice] → Exit: No host found at $ip', name: TAG);
    return null;
  }
}
