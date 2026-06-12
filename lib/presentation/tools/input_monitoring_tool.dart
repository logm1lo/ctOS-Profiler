import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/input_monitoring_service.dart';
import '../camera/widgets/scanline_painter.dart';

class InputMonitoringTool extends ConsumerStatefulWidget {
  const InputMonitoringTool({super.key});

  @override
  ConsumerState<InputMonitoringTool> createState() => _InputMonitoringToolState();
}

class _InputMonitoringToolState extends ConsumerState<InputMonitoringTool> with SingleTickerProviderStateMixin {
  static const String TAG = "InputMonitoringTool";
  final List<String> _events = [];
  bool _isEnabled = false;
  late AnimationController _animationController;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _checkStatus();

    // Listen for events
    InputMonitoringService.logStream.listen((event) {
      if (mounted) {
        developer.log('[logStream] → Intercepted input event: $event', name: TAG);
        setState(() => _events.insert(0, event));
      }
    }, onError: (e) {
      developer.log('[logStream] → Error: $e', name: TAG, error: e);
    });
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    developer.log('[_checkStatus] → Entry', name: TAG);
    try {
      final enabled = await InputMonitoringService.isEnabled();
      developer.log('[_checkStatus] → Exit: status=$enabled', name: TAG);
      if (mounted) {
        setState(() => _isEnabled = enabled);
      }
    } catch (e) {
      developer.log('[_checkStatus] → Error: $e', name: TAG, error: e);
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
        title: Text('INPUT // MONITOR', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
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
                _buildStatusBanner(accentColor, theme),
                const SizedBox(height: 20),
                Text('LIVE_INPUT_AUDIT_LOG', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontSize: 10)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) => _buildEventTile(_events[index], accentColor, theme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(Color color, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEnabled ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
        border: Border.all(color: _isEnabled ? Colors.greenAccent : Colors.redAccent),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_isEnabled ? Icons.security : Icons.warning, color: _isEnabled ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isEnabled ? 'MONITORING_ACTIVE' : 'SERVICE_DISABLED', style: TextStyle(color: _isEnabled ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                    Text(_isEnabled ? 'SYSTEM_WIDE_INPUT_CAPTURE_ENABLED. ALL KEYSTROKES LOGGED.' : 'ENABLE ACCESSIBILITY SERVICE IN SETTINGS TO INITIATE INPUT AUDIT.', style: const TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
          if (!_isEnabled) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  developer.log('[Interaction] → Requesting accessibility permission', name: TAG);
                  InputMonitoringService.requestPermission();
                },
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                child: const Text('AUTHORIZE_SERVICE', style: TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventTile(String event, Color color, AppTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.2)),
        color: color.withValues(alpha: 0.02),
      ),
      child: Text(
        event,
        style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9, fontFamily: 'monospace'),
      ),
    );
  }
}
