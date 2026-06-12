import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:cellular_info/cellular_info.dart';
import 'package:permission_handler/permission_handler.dart';

enum TowerStatus { safe, suspicious, alert }

class TowerData {
  final String id;
  final String signal;
  final String type;
  final TowerStatus status;

  TowerData({
    required this.id,
    required this.signal,
    required this.type,
    required this.status,
  });
}

class TelephonyService {
  static const String TAG = "TelephonyService";

  Stream<TowerData> monitorTowers() async* {
    developer.log('[monitorTowers] → Entry', name: TAG);
    if (!Platform.isAndroid) {
      developer.log('[monitorTowers] → Exit: Non-Android platform, aborting', name: TAG);
      yield* const Stream.empty();
      return;
    }

    // Check permissions
    developer.log('[monitorTowers] → Checking location permissions', name: TAG);
    var status = await Permission.location.status;
    if (!status.isGranted) {
      developer.log('[monitorTowers] → Requesting location permissions', name: TAG);
      status = await Permission.location.request();
      if (!status.isGranted) {
        developer.log('[monitorTowers] → Error: Location permission denied', name: TAG);
        throw 'LOCATION_PERMISSION_REQUIRED';
      }
    }

    developer.log('[monitorTowers] → Initiating continuous monitoring loop (5s interval)', name: TAG);
    // Continuous monitoring loop
    while (true) {
      try {
        final dynamic cells = await (CellularInfo as dynamic).getCellInfo;
        if (cells != null && cells is Iterable) {
          int count = 0;
          for (var cell in cells) {
            String cid = cell.cellId?.toString() ?? 'UNKNOWN';
            String lac = cell.lac?.toString() ?? 'UNKNOWN';
            String type = cell.networkType ?? 'UNKNOWN';
            String signal = '${cell.dbm ?? 0} dBm';

            TowerStatus towerStatus = TowerStatus.safe;
            // Basic heuristics for rogue base stations
            if (cid == '0' || cid == '65535' || lac == '0') {
              towerStatus = TowerStatus.suspicious;
              developer.log('[monitorTowers] → Warning: Suspicious tower detected! CID=$cid, LAC=$lac', name: TAG);
            }

            final data = TowerData(
              id: 'CID:$cid / LAC:$lac',
              signal: signal,
              type: type,
              status: towerStatus,
            );

            count++;
            yield data;
          }
          developer.log('[monitorTowers] → Status: Intercepted $count local cell towers', name: TAG);
        }
      } catch (e) {
        developer.log('[monitorTowers] → Error: Failed to retrieve cell info: $e', name: TAG, error: e);
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
