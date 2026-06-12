import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../camera/widgets/scanline_painter.dart';
import '../camera/widgets/glitchy_button.dart';
import 'providers/ble_spam_provider.dart';

class BleSpamScreen extends ConsumerStatefulWidget {
  const BleSpamScreen({super.key});

  @override
  ConsumerState<BleSpamScreen> createState() => _BleSpamScreenState();
}

class _BleSpamScreenState extends ConsumerState<BleSpamScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider).theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);
    final spamState = ref.watch(bleSpamProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('ctOS // BLE_TRANSMITTER', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accentColor), onPressed: () => Navigator.pop(context)),
        actions: [
          _buildQueueModeToggle(spamState, accentColor, theme),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildTransmissionStatus(spamState, accentColor, theme),
                const SizedBox(height: 24),
                Text('AVAILABLE_PAYLOADS', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontSize: 10)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _buildExpandableGroup('APPLE_ECOSYSTEM', [
                        _buildProtocolItem('APPLE_ACTION_MODAL', 'Nearby Action Modal flood', Icons.apple, spamState),
                        _buildProtocolItem('APPLE_DEVICE_POPUP', 'New Device Popup (AirPods)', Icons.apple, spamState),
                      ], accentColor, theme),
                      _buildExpandableGroup('ANDROID_ECOSYSTEM', [
                        _buildProtocolItem('GOOGLE_FAST_PAIR', 'Fast Pair popup flood', Icons.android, spamState),
                      ], accentColor, theme),
                      _buildExpandableGroup('SAMSUNG_ECOSYSTEM', [
                        _buildProtocolItem('SAMSUNG_BUDS', 'Galaxy Buds pairing flood', Icons.headphones, spamState),
                      ], accentColor, theme),
                      _buildExpandableGroup('WINDOWS_SYSTEMS', [
                        _buildProtocolItem('SWIFT_PAIR', 'Microsoft Swift Pair flood', Icons.laptop_windows, spamState),
                      ], accentColor, theme),
                    ],
                  ),
                ),
                _buildConsole(spamState, accentColor),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueModeToggle(BleSpamState state, Color color, AppTheme theme) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.reorder, color: state.queueMode == BleSpamQueueMode.linear ? color : Colors.grey),
          onPressed: () => ref.read(bleSpamProvider.notifier).setQueueMode(BleSpamQueueMode.linear),
        ),
        IconButton(
          icon: Icon(Icons.shuffle, color: state.queueMode == BleSpamQueueMode.random ? color : Colors.grey),
          onPressed: () => ref.read(bleSpamProvider.notifier).setQueueMode(BleSpamQueueMode.random),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTransmissionStatus(BleSpamState state, Color color, AppTheme theme) {
    final active = state.isTransmitting;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? Colors.redAccent.withValues(alpha: 0.1) : color.withValues(alpha: 0.05),
        border: Border.all(color: active ? Colors.redAccent : color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(active ? Icons.radar : Icons.power_settings_new, color: active ? Colors.redAccent : color, size: 20),
              const SizedBox(width: 12),
              Text(active ? 'TRANSMITTING // ACTIVE' : 'RADIO_SILENCE',
                   style: AppTextStyles.hudStatus(theme).copyWith(color: active ? Colors.redAccent : color, fontWeight: FontWeight.bold)),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 8),
            Text('PAYLOAD: ${state.activeProtocol}', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
            const SizedBox(height: 4),
            const LinearProgressIndicator(backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation(Colors.redAccent)),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableGroup(String title, List<Widget> children, Color color, AppTheme theme) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        children: children,
      ),
    );
  }

  Widget _buildProtocolItem(String id, String desc, IconData icon, BleSpamState state) {
    final isActive = state.activeProtocol == id;
    final color = AppColors.getAccent(ref.watch(settingsProvider).theme);

    return GestureDetector(
      onTap: () => ref.read(bleSpamProvider.notifier).toggleSpam(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? Colors.redAccent : color.withValues(alpha: 0.2)),
          color: isActive ? Colors.redAccent.withValues(alpha: 0.05) : color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.redAccent : color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id, style: TextStyle(color: isActive ? Colors.redAccent : color, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
                  Text(desc.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 7, fontFamily: 'monospace')),
                ],
              ),
            ),
            Icon(isActive ? Icons.stop : Icons.play_arrow, color: isActive ? Colors.redAccent : color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConsole(BleSpamState state, Color color) {
    return Container(
      width: double.infinity,
      height: 100,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ListView.builder(
        itemCount: state.logs.length,
        itemBuilder: (context, index) => Text(state.logs[index], style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9, fontFamily: 'monospace')),
      ),
    );
  }
}
