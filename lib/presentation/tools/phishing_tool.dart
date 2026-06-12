import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/phishing_service.dart';
import '../camera/widgets/scanline_painter.dart';

class PhishingTool extends ConsumerStatefulWidget {
  const PhishingTool({super.key});

  @override
  ConsumerState<PhishingTool> createState() => _PhishingToolState();
}

class _PhishingToolState extends ConsumerState<PhishingTool> with SingleTickerProviderStateMixin {
  static const String TAG = "PhishingTool";
  final PhishingService _service = PhishingService();
  String? _serverUrl;
  final List<Map<String, String>> _capturedData = [];
  late AnimationController _animationController;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _service.credentialStream.listen((data) {
      if (mounted) {
        developer.log('[credentialStream] → Intercepted credentials: ${data.keys.toList()}', name: TAG);
        setState(() => _capturedData.insert(0, data));
      }
    }, onError: (e) {
      developer.log('[credentialStream] → Error: $e', name: TAG, error: e);
    });
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _service.stopServer();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleServer() async {
    developer.log('[_toggleServer] → Entry: currentState=${_serverUrl != null ? "ACTIVE" : "IDLE"}', name: TAG);
    if (_serverUrl != null) {
      developer.log('[_toggleServer] → Status: Terminating server', name: TAG);
      await _service.stopServer();
      if (mounted) setState(() => _serverUrl = null);
      developer.log('[_toggleServer] → Exit: Server offline', name: TAG);
    } else {
      developer.log('[_toggleServer] → Status: Deploying phishing portal', name: TAG);
      final url = await _service.startServer();
      if (mounted) {
        setState(() => _serverUrl = url);
      }
      developer.log('[_toggleServer] → Exit: Server online at $url', name: TAG);
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
        title: Text('ctOS // PHISH_TOOL', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
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
                _buildStatusBanner(accentColor, theme),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      developer.log('[Interaction] → Toggle server requested', name: TAG);
                      _toggleServer();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _serverUrl != null ? Colors.redAccent : accentColor),
                    ),
                    child: Text(_serverUrl != null ? 'STOP_REAL_TIME_SERVER' : 'START_PHISHING_SERVER', style: TextStyle(color: _serverUrl != null ? Colors.redAccent : accentColor, fontFamily: 'monospace')),
                  ),
                ),
                const SizedBox(height: 32),
                Text('INTERCEPTED_CREDENTIALS', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontSize: 10)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _capturedData.length,
                    itemBuilder: (context, index) => _buildCredentialTile(_capturedData[index], accentColor, theme),
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
        color: _serverUrl != null ? Colors.greenAccent.withValues(alpha: 0.1) : color.withValues(alpha: 0.05),
        border: Border.all(color: _serverUrl != null ? Colors.greenAccent : color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_serverUrl != null ? 'SERVER_RUNNING' : 'SERVER_OFFLINE', style: AppTextStyles.hudStatus(theme).copyWith(color: _serverUrl != null ? Colors.greenAccent : color)),
          if (_serverUrl != null) ...[
            const SizedBox(height: 8),
            Text('ENDPOINT: $_serverUrl', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('POINT_TEST_SUBJECTS_HERE_VIA_MITM', style: TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }

  Widget _buildCredentialTile(Map<String, String> data, Color color, AppTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        color: Colors.redAccent.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CREDENTIALS_INTERCEPTED', style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const Divider(color: Colors.redAccent, height: 16),
          Text('ID: ${data['username']}', style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
          Text('PW: ${data['password']}', style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
