import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/utils/bluetooth_service.dart';

class BlueBorneState {
  final List<BluetoothDeviceData> devices;
  final bool isScanning;
  final Map<String, String> probeResults;
  final String? activeProbe;

  BlueBorneState({
    this.devices = const [],
    this.isScanning = false,
    this.probeResults = const {},
    this.activeProbe,
  });

  BlueBorneState copyWith({
    List<BluetoothDeviceData>? devices,
    bool? isScanning,
    Map<String, String>? probeResults,
    String? activeProbe,
    bool clearActiveProbe = false,
  }) {
    return BlueBorneState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      probeResults: probeResults ?? this.probeResults,
      activeProbe: clearActiveProbe ? null : (activeProbe ?? this.activeProbe),
    );
  }
}

class BlueBorneNotifier extends StateNotifier<BlueBorneState> {
  static const String TAG = "BlueBorneNotifier";
  final BluetoothProberService _service = BluetoothProberService();
  StreamSubscription? _subscription;

  BlueBorneNotifier() : super(BlueBorneState()) {
    developer.log('ctOS_TRACE: BlueBorneNotifier instance created', name: TAG);
  }

  void startScan() {
    developer.log('[startScan] → Entry', name: TAG);
    if (state.isScanning) {
      developer.log('[startScan] → Exit: Already scanning', name: TAG);
      return;
    }
    state = state.copyWith(isScanning: true, devices: []);

    _subscription?.cancel();
    _subscription = _service.startDiscovery().listen((device) {
       if (!state.devices.any((d) => d.id == device.id)) {
        developer.log('[startScan] → Target node discovered: ${device.id}', name: TAG);
        state = state.copyWith(devices: [...state.devices, device]);
      }
    }, onDone: () {
      developer.log('[startScan] → Status: Discovery completed', name: TAG);
      state = state.copyWith(isScanning: false);
    }, onError: (e) {
      developer.log('[startScan] → Error: $e', name: TAG, error: e);
      state = state.copyWith(isScanning: false);
    });
  }

  Future<void> runProbe(String id) async {
    developer.log('[runProbe] → Entry: targetId=$id', name: TAG);
    state = state.copyWith(activeProbe: id);

    try {
      final result = await _service.executeBlueBornePoC(id);

      if (result != null) {
        developer.log('[runProbe] → Status: Probe successful, data intercepted', name: TAG);
        final newResults = Map<String, String>.from(state.probeResults);
        newResults[id] = result;
        state = state.copyWith(probeResults: newResults);
      }
      state = state.copyWith(clearActiveProbe: true);
      developer.log('[runProbe] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[runProbe] → Error: $e', name: TAG, error: e);
      state = state.copyWith(clearActiveProbe: true);
    }
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _subscription?.cancel();
    super.dispose();
  }
}

final blueborneProvider = StateNotifierProvider<BlueBorneNotifier, BlueBorneState>((ref) {
  return BlueBorneNotifier();
});
