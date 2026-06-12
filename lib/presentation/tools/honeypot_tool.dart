import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/honeypot_service.dart';
import '../camera/widgets/scanline_painter.dart';

class HoneypotTool extends ConsumerStatefulWidget {
  const HoneypotTool({super.key});

  @override
  ConsumerState<HoneypotTool> createState() => _HoneypotToolState();
}

class _HoneypotToolState extends ConsumerState<HoneypotTool> with SingleTickerProviderStateMixin {
  static const String TAG = "HoneypotTool";
  final HoneypotService _service = HoneypotService();
  final TextEditingController _ssidController = TextEditingController(text: 'ctOS_FREE_WIFI');
  bool _isActive = false;
  late AnimationController _animationController;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _animationController.dispose();
    _ssidController.dispose();
    super.dispose();
  }

  Future<void> _toggleHotspot() async {
    developer.log('[_toggleHotspot] → Entry: currentActive=$_isActive', name: TAG);
    if (_isActive) {
      developer.log('[_toggleHotspot] → Status: Terminating hotspot', name: TAG);
      await _service.stopHotspot();
      if (mounted) setState(() => _isActive = false);
      developer.log('[_toggleHotspot] → Exit: Terminated', name: TAG);
    } else {
      final ssid = _ssidController.text;
      developer.log('[_toggleHotspot] → Status: Deploying hotspot with SSID: $ssid', name: TAG);
      final success = await _service.startHotspot(ssid);
      
      if (success) {
        developer.log('[_toggleHotspot] → Exit: Deployment successful', name: TAG);
        if (mounted) setState(() => _isActive = true);
      } else {
        developer.log('[_toggleHotspot] → Error: Deployment failed (Permissions or OS restriction)', name: TAG);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('HOTSPOT_FAILED: CHECK_SYSTEM_PERMISSIONS')));
        }
      }
    }
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
        title: Text('ctOS // HONEYPOT', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusIndicator(accentColor, theme),
                const SizedBox(height: 32),
                TextField(
                  controller: _ssidController,
                  enabled: !_isActive,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    labelText: 'SPOOF_SSID',
                    labelStyle: TextStyle(color: accentColor.withValues(alpha: 0.5)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton(
                    onPressed: () {
                      developer.log('[Interaction] → Toggle hotspot requested', name: TAG);
                      _toggleHotspot();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _isActive ? Colors.redAccent : accentColor),
                      backgroundColor: (_isActive ? Colors.redAccent : accentColor).withValues(alpha: 0.05),
                    ),
                    child: Text(
                      _isActive ? 'TERMINATE_SIGNAL' : 'DEPLOY_HONEYPOT',
                      style: TextStyle(color: _isActive ? Colors.redAccent : accentColor, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('TRAFFIC_INSPECTION_MODULE', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontSize: 10)),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    child: const SingleChildScrollView(
                      child: Text(
                        'WAITING_FOR_CLIENT_ASSOCIATION...',
                        style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(Color color, AppTheme theme) {
    return Row(
      children: [
        Icon(_isActive ? Icons.wifi_tethering : Icons.wifi_tethering_off, color: _isActive ? Colors.greenAccent : Colors.grey, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isActive ? 'SIGNAL_ACTIVE' : 'READY_TO_DEPLOY', style: AppTextStyles.hudStatus(theme).copyWith(color: _isActive ? Colors.greenAccent : Colors.grey)),
            const Text('MODULE: WIRELESS_SPOOFER_v4.2', style: TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace')),
          ],
        ),
      ],
    );
  }
}
