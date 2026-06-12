import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/utils/bluetooth_service.dart';

enum WhisperPairTab { scanner, paired, recordings }

class WhisperPairState {
  final WhisperPairTab currentTab;
  final List<BluetoothDeviceData> discoveredDevices;
  final List<BluetoothDeviceData> pairedDevices;
  final bool isScanning;
  final Map<String, String> exploitLogs;

  WhisperPairState({
    this.currentTab = WhisperPairTab.scanner,
    this.discoveredDevices = const [],
    this.pairedDevices = const [],
    this.isScanning = false,
    this.exploitLogs = const {},
  });

  WhisperPairState copyWith({
    WhisperPairTab? currentTab,
    List<BluetoothDeviceData>? discoveredDevices,
    List<BluetoothDeviceData>? pairedDevices,
    bool? isScanning,
    Map<String, String>? exploitLogs,
  }) {
    return WhisperPairState(
      currentTab: currentTab ?? this.currentTab,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      isScanning: isScanning ?? this.isScanning,
      exploitLogs: exploitLogs ?? this.exploitLogs,
    );
  }
}

class WhisperPairNotifier extends StateNotifier<WhisperPairState> {
  static const String TAG = "WhisperPairNotifier";
  final BluetoothProberService _service = BluetoothProberService();
  StreamSubscription? _scanSubscription;

  WhisperPairNotifier() : super(WhisperPairState()) {
    developer.log('ctOS_TRACE: WhisperPairNotifier instance created', name: TAG);
  }

  void setTab(WhisperPairTab tab) {
    developer.log('[setTab] → Entry: tab=$tab', name: TAG);
    state = state.copyWith(currentTab: tab);
    developer.log('[setTab] → Exit: Completed successfully', name: TAG);
  }

  void startScan() {
    developer.log('[startScan] → Entry', name: TAG);
    if (state.isScanning) {
      developer.log('[startScan] → Exit: Already scanning', name: TAG);
      return;
    }
    state = state.copyWith(isScanning: true, discoveredDevices: []);

    _scanSubscription?.cancel();
    _scanSubscription = _service.startDiscovery().listen((device) {
      if (!state.discoveredDevices.any((d) => d.id == device.id)) {
        developer.log('[startScan] → Node discovered: ${device.id}', name: TAG);
        state = state.copyWith(discoveredDevices: [...state.discoveredDevices, device]);
      }
    }, onDone: () {
      developer.log('[startScan] → Status: Scan cycle completed', name: TAG);
      state = state.copyWith(isScanning: false);
    }, onError: (e) {
      developer.log('[startScan] → Error: $e', name: TAG, error: e);
      state = state.copyWith(isScanning: false);
    });
  }

  void stopScan() {
    developer.log('[stopScan] → Entry', name: TAG);
    _scanSubscription?.cancel();
    state = state.copyWith(isScanning: false);
    developer.log('[stopScan] → Exit: Completed successfully', name: TAG);
  }

  Future<void> runMagicExploit(BluetoothDeviceData device) async {
    developer.log('[runMagicExploit] → Entry: deviceId=${device.id}', name: TAG);
    _updateLog(device.id, "INITIATING_MAGIC_HANDSHAKE...");

    try {
      final result = await _service.executeWhisperPairExploit(device.id);

      if (result != null) {
        developer.log('[runMagicExploit] → Status: $result', name: TAG);
        _updateLog(device.id, "STATUS: $result");
        if (result.contains("SUCCESS") || result.contains("INITIATED")) {
          if (!state.pairedDevices.any((d) => d.id == device.id)) {
            developer.log('[runMagicExploit] → Status: Target successfully hijacked', name: TAG);
            state = state.copyWith(pairedDevices: [...state.pairedDevices, device]);
          }
        }
      }
      developer.log('[runMagicExploit] → Exit: Exploit sequence triggered', name: TAG);
    } catch (e) {
      developer.log('[runMagicExploit] → Error: $e', name: TAG, error: e);
      _updateLog(device.id, "EXPLOIT_FAILED: $e");
    }
  }

  void _updateLog(String deviceId, String log) {
    developer.log('[_updateLog] → Entry: id=$deviceId, log=$log', name: TAG);
    final newLogs = Map<String, String>.from(state.exploitLogs);
    newLogs[deviceId] = log;
    state = state.copyWith(exploitLogs: newLogs);
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _scanSubscription?.cancel();
    super.dispose();
  }
}

final whisperPairProvider = StateNotifierProvider<WhisperPairNotifier, WhisperPairState>((ref) {
  return WhisperPairNotifier();
});
