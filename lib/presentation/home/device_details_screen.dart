import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/network_service.dart';
import '../camera/widgets/scanline_painter.dart';

class DeviceDetailsScreen extends ConsumerWidget {
  static const String TAG = "DeviceDetailsScreen";
  final NetworkDevice device;

  const DeviceDetailsScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    developer.log('[build] → Entry: node=${device.ip}', name: TAG);
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('DEVICE // ${device.ip}',
            style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
          bottom: TabBar(
            indicatorColor: accentColor,
            labelColor: accentColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
            onTap: (index) {
              developer.log('[Interaction] → Tab switched to index $index', name: TAG);
            },
            tabs: const [
              Tab(text: 'SYSTEM'),
              Tab(text: 'NETWORK'),
              Tab(text: 'SECURITY'),
            ],
          ),
        ),
        body: Stack(
          children: [
            const _BackgroundHUD(),
            TabBarView(
              children: [
                _buildSystemTab(theme, accentColor),
                _buildNetworkTab(theme, accentColor),
                _buildSecurityTab(theme, accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemTab(AppTheme theme, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('OS_TYPE', 'IDENTIFYING...', accentColor, theme),
          _buildInfoRow('ARCHITECTURE', 'IDENTIFYING...', accentColor, theme),
          _buildInfoRow('UPTIME', 'UNKNOWN', accentColor, theme),
          _buildInfoRow('VENDOR', device.vendor ?? 'UNKNOWN', accentColor, theme),
          const SizedBox(height: 20),
          _buildDiagnosticGraph(accentColor, theme),
        ],
      ),
    );
  }

  Widget _buildNetworkTab(AppTheme theme, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('IP_ADDRESS', device.ip, accentColor, theme),
          _buildInfoRow('MAC_ADDRESS', device.macAddress ?? 'RESTRICTED', accentColor, theme),
          _buildInfoRow('HOSTNAME', device.hostname ?? 'ANONYMOUS_NODE', accentColor, theme),
          _buildInfoRow('LATENCY', 'SCANNING...', accentColor, theme),
          const SizedBox(height: 20),
          Text('ACTIVE_INTERFACES', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 8),
          _buildPortList(device.openPorts, accentColor, theme),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(AppTheme theme, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('VULNERABILITIES', 'SCAN_PENDING', accentColor, theme),
          _buildInfoRow('ENCRYPTION', 'IDENTIFYING...', accentColor, theme),
          _buildInfoRow('FIREWALL', 'IDENTIFYING...', accentColor, theme),
          const SizedBox(height: 24),
          _buildActionItem('INTERROGATE_PORTS', Icons.lock_open, accentColor, theme),
          _buildActionItem('PROBE_SERVICES', Icons.leak_add, accentColor, theme),
          _buildActionItem('OSINT_NODE_SEARCH', Icons.person_search, accentColor, theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.grey, fontSize: 10)),
          Text(value, style: AppTextStyles.hudStatus(theme).copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPortList(List<int> ports, Color accentColor, AppTheme theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ports.map((p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          color: accentColor.withValues(alpha: 0.1),
        ),
        child: Text('PORT:$p', style: TextStyle(color: accentColor, fontSize: 9, fontFamily: 'monospace')),
      )).toList(),
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color, AppTheme theme) {
    return GestureDetector(
      onTap: () {
        developer.log('[Interaction] → Remote action triggered: $label', name: TAG);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            Icon(icon, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticGraph(Color accentColor, AppTheme theme) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Center(child: Text('TRAFFIC_ANALYTICS_STREAM...', style: TextStyle(color: accentColor.withValues(alpha: 0.3), fontSize: 8, fontFamily: 'monospace'))),
    );
  }
}

class _BackgroundHUD extends StatefulWidget {
  const _BackgroundHUD();

  @override
  State<_BackgroundHUD> createState() => _BackgroundHUDState();
}

class _BackgroundHUDState extends State<_BackgroundHUD> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        size: Size.infinite,
        painter: ScanlinePainter(progress: _ctrl.value, color: Colors.cyanAccent.withValues(alpha: 0.1)),
      ),
    );
  }
}
