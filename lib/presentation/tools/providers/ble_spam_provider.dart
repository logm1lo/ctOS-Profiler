import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/bluetooth_offensive_service.dart';

enum BleSpamQueueMode { linear, random }

class BleSpamState {
  final bool isTransmitting;
  final String? activeProtocol;
  final BleSpamQueueMode queueMode;
  final List<String> logs;

  BleSpamState({
    this.isTransmitting = false,
    this.activeProtocol,
    this.queueMode = BleSpamQueueMode.linear,
    this.logs = const [],
  });

  BleSpamState copyWith({
    bool? isTransmitting,
    String? activeProtocol,
    BleSpamQueueMode? queueMode,
    List<String>? logs,
    bool clearActiveProtocol = false,
  }) {
    return BleSpamState(
      isTransmitting: isTransmitting ?? this.isTransmitting,
      activeProtocol: clearActiveProtocol ? null : (activeProtocol ?? this.activeProtocol),
      queueMode: queueMode ?? this.queueMode,
      logs: logs ?? this.logs,
    );
  }
}

class BleSpamNotifier extends StateNotifier<BleSpamState> {
  static const String TAG = "BleSpamNotifier";
  final BluetoothOffensiveService _service = BluetoothOffensiveService();

  BleSpamNotifier() : super(BleSpamState()) {
    developer.log('ctOS_TRACE: BleSpamNotifier instance created', name: TAG);
  }

  Future<void> toggleSpam(String protocol) async {
    developer.log('[toggleSpam] → Entry: protocol=$protocol', name: TAG);
    try {
      if (state.activeProtocol == protocol) {
        developer.log('[toggleSpam] → Status: Protocol match found, stopping transmission', name: TAG);
        await _service.stopBleSpam();
        state = state.copyWith(isTransmitting: false, clearActiveProtocol: true);
        _addLog('STOPPED: $protocol');
      } else {
        developer.log('[toggleSpam] → Status: Switching to protocol $protocol', name: TAG);
        await _service.stopBleSpam();

        BleSpamType nativeType;
        if (protocol.contains('APPLE')) nativeType = BleSpamType.apple;
        else if (protocol.contains('SAMSUNG')) nativeType = BleSpamType.samsung;
        else nativeType = BleSpamType.google;

        await _service.startBleSpam(nativeType);
        state = state.copyWith(isTransmitting: true, activeProtocol: protocol);
        _addLog('TRANSMITTING: $protocol');
      }
      developer.log('[toggleSpam] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[toggleSpam] → Error: $e', name: TAG, error: e);
      _addLog('ERROR: Failed to engage transmitter');
    }
  }

  void setQueueMode(BleSpamQueueMode mode) {
    developer.log('[setQueueMode] → Entry: mode=$mode', name: TAG);
    state = state.copyWith(queueMode: mode);
    _addLog('MODE_CHANGED: ${mode.name.toUpperCase()}');
    developer.log('[setQueueMode] → Exit: Completed successfully', name: TAG);
  }

  void _addLog(String log) {
    developer.log('[_addLog] → Entry: message=$log', name: TAG);
    final timestamp = DateTime.now().toString().substring(11, 19);
    state = state.copyWith(logs: ['$timestamp > $log', ...state.logs].take(50).toList());
  }
}

final bleSpamProvider = StateNotifierProvider<BleSpamNotifier, BleSpamState>((ref) {
  return BleSpamNotifier();
});
