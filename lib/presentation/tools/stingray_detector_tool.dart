import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/telephony_service.dart';
import '../camera/widgets/scanline_painter.dart';

class StingrayDetectorTool extends ConsumerStatefulWidget {
  const StingrayDetectorTool({super.key});

  @override
  ConsumerState<StingrayDetectorTool> createState() => _StingrayDetectorToolState();
}

class _StingrayDetectorToolState extends ConsumerState<StingrayDetectorTool> with SingleTickerProviderStateMixin {
  static const String TAG = "StingrayDetectorTool";
  final TelephonyService _service = TelephonyService();
  final List<TowerData> _towers = [];
  late AnimationController _animationController;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    developer.log('[_requestPermissionAndStart] → Entry', name: TAG);
    final status = await Permission.phone.request();
    developer.log('[_requestPermissionAndStart] → Permission status: $status', name: TAG);
    
    if (status.isGranted) {
      developer.log('[_requestPermissionAndStart] → Access granted, starting monitor', name: TAG);
      _startMonitoring();
    } else {
      developer.log('[_requestPermissionAndStart] → Error: Permission denied', name: TAG);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PHONE_STATE_PERMISSION_DENIED')),
        );
      }
    }
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _animationController.dispose();
    super.dispose();
  }

  void _startMonitoring() {
    developer.log('[_startMonitoring] → Entry', name: TAG);
    _service.monitorTowers().listen((data) {
      if (mounted) {
        developer.log('[_startMonitoring] → Tower data intercepted: ${data.id}, status=${data.status}', name: TAG);
        setState(() => _towers.insert(0, data));
      }
    }, onError: (e) {
      developer.log('[_startMonitoring] → Error: $e', name: TAG, error: e);
    });
  }

  @override
  Widget build(BuildContext context) {
    // developer.log('[build] → Entry', name: TAG);
    final theme = ref.watch(settingsProvider).theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('STINGRAY // DETECTOR', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accentColor), onPressed: () => Navigator.pop(context)),
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
                _buildWarningBanner(theme),
                const SizedBox(height: 20),
                Text('CELLULAR_TRAFFIC_MONITOR', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontSize: 10)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _towers.length,
                    itemBuilder: (context, index) => _buildTowerTile(_towers[index], accentColor, theme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(AppTheme theme) {
    bool hasAlert = _towers.any((t) => t.status == TowerStatus.alert);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAlert ? Colors.redAccent.withValues(alpha: 0.1) : Colors.greenAccent.withValues(alpha: 0.05),
        border: Border.all(color: hasAlert ? Colors.redAccent : Colors.greenAccent),
      ),
      child: Row(
        children: [
          Icon(hasAlert ? Icons.warning : Icons.security, color: hasAlert ? Colors.redAccent : Colors.greenAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasAlert ? 'THREAT DETECTED' : 'ENVIRONMENT SECURE', style: TextStyle(color: hasAlert ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                Text(hasAlert ? 'SUSPICIOUS CELL TOWER DETECTED (IMSI CATCHER). AVOID TRANSMITTING SENSITIVE DATA.' : 'NO ACTIVE IMSI CATCHERS DETECTED IN LOCAL RANGE.', style: TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowerTile(TowerData tower, Color color, AppTheme theme) {
    Color towerColor = tower.status == TowerStatus.alert ? Colors.redAccent : (tower.status == TowerStatus.suspicious ? Colors.amberAccent : color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: towerColor.withValues(alpha: 0.3)),
        color: towerColor.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tower.id, style: TextStyle(color: towerColor, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'monospace')),
              Text('TECH: ${tower.type}', style: const TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace')),
            ],
          ),
          Text(tower.signal, style: TextStyle(color: towerColor, fontSize: 10, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
