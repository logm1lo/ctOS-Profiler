import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/vulnerability_scanner_service.dart';
import '../camera/widgets/scanline_painter.dart';

class RTSPSecurityTool extends ConsumerStatefulWidget {
  final String targetIp;
  final int port;

  const RTSPSecurityTool({super.key, required this.targetIp, required this.port});

  @override
  ConsumerState<RTSPSecurityTool> createState() => _RTSPSecurityToolState();
}

class _RTSPSecurityToolState extends ConsumerState<RTSPSecurityTool> with SingleTickerProviderStateMixin {
  static const String TAG = "RTSPSecurityTool";
  final VulnerabilityScannerService _scanner = VulnerabilityScannerService();
  bool _isRunning = false;
  VulnerabilityResult? _result;
  late AnimationController _animationController;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _runAssessment();
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _runAssessment() async {
    developer.log('[_runAssessment] → Entry: target=${widget.targetIp}:${widget.port}', name: TAG);
    setState(() {
      _isRunning = true;
      _result = null;
    });

    try {
      final res = await _scanner.testRtspSecurity(widget.targetIp, widget.port);
      developer.log('[_runAssessment] → Status: Assessment returned (isInsecure=${res.isInsecure})', name: TAG);

      if (mounted) {
        setState(() {
          _result = res;
          _isRunning = false;
        });
      }
      developer.log('[_runAssessment] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[_runAssessment] → Error: $e', name: TAG, error: e);
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider).theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('ctOS // IOT_VULN_SCAN', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
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
                _buildHeader(accentColor, theme),
                const SizedBox(height: 24),
                if (_isRunning) ...[
                   Text('ATTEMPTING_DICTIONARY_ATTACK...', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.amberAccent)),
                   const SizedBox(height: 8),
                   const LinearProgressIndicator(backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent)),
                ] else if (_result != null) ...[
                  _buildResultCard(accentColor, theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.3)), color: color.withValues(alpha: 0.05)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TARGET_IP: ${widget.targetIp}', style: AppTextStyles.hudStatus(theme).copyWith(color: color)),
          Text('SERVICE: RTSP (PORT ${widget.port})', style: TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildResultCard(Color color, AppTheme theme) {
    bool insecure = _result!.isInsecure;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: insecure ? Colors.redAccent : Colors.greenAccent),
        color: (insecure ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(insecure ? Icons.warning : Icons.security, color: insecure ? Colors.redAccent : Colors.greenAccent),
              const SizedBox(width: 12),
              Text(insecure ? 'VULNERABILITY DETECTED' : 'SERVICE SECURE', style: AppTextStyles.hudStatus(theme).copyWith(color: insecure ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Text(_result!.findings ?? 'NO DATA', style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
          if (insecure) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                   developer.log('[Interaction] → Stream hijack initiated for ${widget.targetIp}', name: TAG);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('STREAM_HIJACK_INITIATED')));
                },
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                child: const Text('OPEN_LIVE_STREAM', style: TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
