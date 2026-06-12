import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/bluetooth_service.dart';
import '../camera/widgets/scanline_painter.dart';

class BluetoothProberTool extends ConsumerStatefulWidget {
  const BluetoothProberTool({super.key});

  @override
  ConsumerState<BluetoothProberTool> createState() => _BluetoothProberToolState();
}

class _BluetoothProberToolState extends ConsumerState<BluetoothProberTool> with SingleTickerProviderStateMixin {
  static const String TAG = "BluetoothProberTool";
  final BluetoothProberService _service = BluetoothProberService();
  final Map<String, BluetoothDeviceData> _devicesMap = {};
  bool _isScanning = false;
  String? _activeDump;
  late AnimationController _animationController;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _requestPermissionsAndStart();
  }

  Future<void> _requestPermissionsAndStart() async {
    developer.log('[_requestPermissionsAndStart] → Entry', name: TAG);
    final status = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (status[Permission.bluetoothScan]!.isGranted) {
      developer.log('[_requestPermissionsAndStart] → Permissions granted, initiating discovery', name: TAG);
      _startDiscovery();
    } else {
      developer.log('[_requestPermissionsAndStart] → Error: Permissions denied', name: TAG);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BLUETOOTH_SCAN_PERMISSION_DENIED')),
        );
      }
    }
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _service.stopDiscovery();
    _animationController.dispose();
    super.dispose();
  }

  void _startDiscovery() {
    developer.log('[_startDiscovery] → Entry', name: TAG);
    setState(() {
      _isScanning = true;
      _devicesMap.clear();
      _activeDump = null;
    });

    _service.startDiscovery().listen((device) {
      if (mounted) {
        developer.log('[_startDiscovery] → Node intercepted: ${device.id}', name: TAG);
        setState(() => _devicesMap[device.id] = device);
      }
    }, onError: (e) {
      developer.log('[_startDiscovery] → Error: $e', name: TAG, error: e);
       if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('BT_ERROR: $e')));
      }
    }, onDone: () {
      developer.log('[_startDiscovery] → Status: Discovery cycle completed', name: TAG);
      if (mounted) {
        setState(() => _isScanning = false);
      }
    });
  }

  Future<void> _runPoC(String id) async {
    developer.log('[_runPoC] → Entry: targetId=$id', name: TAG);
    setState(() => _activeDump = "INITIATING_L2CAP_EXPLOIT...\nCONNECTING_TO_TARGET...");
    
    try {
      final result = await _service.executeBlueBornePoC(id);
      developer.log('[_runPoC] → Status: PoC executed, result intercepted', name: TAG);
      if (mounted) {
        setState(() => _activeDump = result);
      }
      developer.log('[_runPoC] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[_runPoC] → Error: $e', name: TAG, error: e);
      if (mounted) setState(() => _activeDump = "EXPLOIT_FAILED: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // developer.log('[build] → Entry', name: TAG);
    final theme = ref.watch(settingsProvider).theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);
    final devices = _devicesMap.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('BT // PROBER', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accentColor), onPressed: () => Navigator.pop(context)),
        actions: [
          if (!_isScanning) IconButton(icon: Icon(Icons.refresh, color: accentColor), onPressed: () {
            developer.log('[Interaction] → Manual discovery refresh', name: TAG);
            _startDiscovery();
          }),
        ],
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ScanlinePainter(
              progress: _animationController.value,
              color: AppColors.getScanLine(theme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 if (_activeDump != null) _buildDumpTerminal(accentColor),
                 const SizedBox(height: 10),
                 Text('STATUS: ${_isScanning ? "PROBING_WAVES" : "DISCOVERY_IDLE"}', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontSize: 10)),
                 const SizedBox(height: 16),
                 Expanded(
                   child: ListView.builder(
                     itemCount: devices.length,
                     itemBuilder: (context, index) => _buildDeviceTile(devices[index], accentColor, theme),
                   ),
                 ),
                 if (_isScanning) const LinearProgressIndicator(backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDumpTerminal(Color color) {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.redAccent),
      ),
      child: SingleChildScrollView(
        child: Text(
          _activeDump!,
          style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  Widget _buildDeviceTile(BluetoothDeviceData device, Color color, AppTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: device.isVulnerable ? Colors.redAccent : color, width: 2)),
        color: AppColors.getSurface(theme).withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(device.name.toUpperCase(), style: AppTextStyles.hudStatus(theme).copyWith(color: device.isVulnerable ? Colors.redAccent : color, fontWeight: FontWeight.bold)),
              Text('${device.rssi} dBm', style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 4),
          Text('ID: ${device.id}', style: const TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace')),
          if (device.isVulnerable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  child: const Text('VULNERABLE // BLUEBORNE', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _runPoC(device.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: Colors.redAccent)),
                    child: const Text('EXECUTE_POC', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
