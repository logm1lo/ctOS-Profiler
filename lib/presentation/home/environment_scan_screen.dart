import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/network_service.dart';
import '../../core/services/network_resilience_service.dart';
import '../camera/widgets/scanline_painter.dart';
import '../tools/rtsp_security_tool.dart';
import 'device_details_screen.dart';

class EnvironmentScanScreen extends ConsumerStatefulWidget {
  const EnvironmentScanScreen({super.key});

  @override
  ConsumerState<EnvironmentScanScreen> createState() => _EnvironmentScanScreenState();
}

class _EnvironmentScanScreenState extends ConsumerState<EnvironmentScanScreen> with SingleTickerProviderStateMixin {
  static const String TAG = "EnvironmentScanScreen";
  final NetworkService _networkService = NetworkService();
  final NetworkResilienceService _resilienceService = NetworkResilienceService();
  final List<NetworkDevice> _devices = [];
  bool _isScanning = false;
  String? _localIp;
  String? _subnetMask;
  late AnimationController _animationController;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _startScan();
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    developer.log('[_startScan] → Entry', name: TAG);
    if (_isScanning) {
      developer.log('[_startScan] → Exit: Already scanning', name: TAG);
      return;
    }

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    developer.log('[_startScan] → Status: Identifying network interface', name: TAG);
    _localIp = await _networkService.getLocalIp();
    _subnetMask = await _networkService.getSubnetMask();

    if (_localIp == null) {
      developer.log('[_startScan] → Error: Local IP not found', name: TAG);
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UNABLE_TO_IDENTIFY_NETWORK_RANGE'))
        );
      }
      return;
    }

    final subnet = _localIp!.substring(0, _localIp!.lastIndexOf('.'));
    developer.log('[_startScan] → Status: Probing range $subnet.0/24', name: TAG);

    _networkService.discoverDevices(subnet).listen((device) {
      if (mounted) {
        developer.log('[_startScan] → Device discovered: ${device.ip}', name: TAG);
        setState(() {
          _devices.add(device);
        });
      }
    }, onDone: () {
      developer.log('[_startScan] → Status: Scan cycle completed', name: TAG);
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }, onError: (e) {
      developer.log('[_startScan] → Error: $e', name: TAG, error: e);
      if (mounted) {
        setState(() => _isScanning = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ctOS // ENV_SCAN', style: AppTextStyles.title(theme).copyWith(fontSize: 18, color: accentColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isScanning)
            IconButton(
              icon: Icon(Icons.refresh, color: accentColor),
              onPressed: () {
                developer.log('[Interaction] → Manual refresh requested', name: TAG);
                _startScan();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ScanlinePainter(
              progress: _animationController.value,
              color: AppColors.getScanLine(theme).withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(theme, accentColor),
                const SizedBox(height: 12),
                if (_isScanning)
                  Column(
                    children: [
                      const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                        minHeight: 1,
                      ),
                      const SizedBox(height: 4),
                      Text('SCANNING_SUBNET: ${_localIp?.substring(0, _localIp!.lastIndexOf('.'))}.0/24',
                        style: TextStyle(color: accentColor.withValues(alpha: 0.5), fontSize: 8, fontFamily: 'monospace')),
                    ],
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: _devices.isEmpty && !_isScanning
                      ? _buildEmptyState(theme, accentColor)
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) => _buildDeviceTile(_devices[index], theme, accentColor),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(AppTheme theme, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        color: accentColor.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi, color: accentColor, size: 14),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LOCAL_IP: ${_localIp ?? "IDENTIFYING..."}', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontSize: 9)),
              Text('MASK: ${_subnetMask ?? "255.255.255.0"}', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor.withValues(alpha: 0.6), fontSize: 7)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: _isScanning ? Colors.amberAccent : Colors.greenAccent),
            ),
            child: Text(
              _isScanning ? "IN_PROGRESS" : "SYNCED",
              style: TextStyle(color: _isScanning ? Colors.amberAccent : Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(NetworkDevice device, AppTheme theme, Color accentColor) {
    return GestureDetector(
      onTap: () {
        developer.log('[Navigation] → Inspecting node details: ${device.ip}', name: TAG);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeviceDetailsScreen(device: device))
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          color: AppColors.getSurface(theme).withValues(alpha: 0.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IP_NODE // ${device.ip}', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontWeight: FontWeight.bold)),
                    Text(device.hostname ?? 'ANONYMOUS_DEVICE', style: TextStyle(color: accentColor.withValues(alpha: 0.5), fontSize: 8, fontFamily: 'monospace')),
                  ],
                ),
                Icon(Icons.chevron_right, color: accentColor.withValues(alpha: 0.5), size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSmallButton(
                  'INTERROGATE',
                  accentColor,
                  onTap: () {
                    developer.log('[Interaction] → Interrogating ${device.ip}', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceDetailsScreen(device: device)));
                  }
                ),
                const SizedBox(width: 8),
                if (device.openPorts.contains(554) || device.openPorts.contains(8554))
                  _buildSmallButton(
                    'CAM_ACCESS',
                    Colors.amberAccent,
                    onTap: () {
                      developer.log('[Interaction] → Hijacking RTSP stream from ${device.ip}', name: TAG);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => RTSPSecurityTool(targetIp: device.ip, port: device.openPorts.contains(554) ? 554 : 8554)));
                    }
                  ),
                const Spacer(),
                _buildSmallButton(
                  'DISCONNECT',
                  Colors.redAccent,
                  onTap: () async {
                    developer.log('[Interaction] → Initiating disruption cycle for node ${device.ip}', name: TAG);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DISRUPTION_INITIATED')));
                    await _resilienceService.kickDevice(device.ip, _localIp!);
                  }
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton(String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 8, fontFamily: 'monospace')),
      ),
    );
  }

  Widget _buildEmptyState(AppTheme theme, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 40, color: accentColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('NO DEVICES DETECTED', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}
