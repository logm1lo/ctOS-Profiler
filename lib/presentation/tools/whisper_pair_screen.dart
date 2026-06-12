import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../camera/widgets/scanline_painter.dart';
import '../camera/widgets/glitchy_button.dart';
import 'providers/whisper_pair_provider.dart';

class WhisperPairScreen extends ConsumerStatefulWidget {
  const WhisperPairScreen({super.key});

  @override
  ConsumerState<WhisperPairScreen> createState() => _WhisperPairScreenState();
}

class _WhisperPairScreenState extends ConsumerState<WhisperPairScreen> with SingleTickerProviderStateMixin {
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
    final wpState = ref.watch(whisperPairProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('ctOS // WHISPER_PAIR', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accentColor), onPressed: () => Navigator.pop(context)),
      ),
      bottomNavigationBar: _buildBottomNav(wpState, accentColor, theme),
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
            child: _buildCurrentTab(wpState, accentColor, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(WhisperPairState state, Color color, AppTheme theme) {
    return BottomNavigationBar(
      currentIndex: state.currentTab.index,
      backgroundColor: Colors.black,
      selectedItemColor: color,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 10),
      unselectedLabelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 10),
      onTap: (index) => ref.read(whisperPairProvider.notifier).setTab(WhisperPairTab.values[index]),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.bluetooth_searching), label: 'SCANNER'),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'PAIRED'),
        BottomNavigationBarItem(icon: Icon(Icons.audiotrack), label: 'RECORDS'),
      ],
    );
  }

  Widget _buildCurrentTab(WhisperPairState state, Color color, AppTheme theme) {
    switch (state.currentTab) {
      case WhisperPairTab.scanner:
        return _buildScannerTab(state, color, theme);
      case WhisperPairTab.paired:
        return _buildPairedTab(state, color, theme);
      case WhisperPairTab.recordings:
        return _buildRecordingsTab(state, color, theme);
    }
  }

  Widget _buildScannerTab(WhisperPairState state, Color color, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildScanControl(state, color, theme),
        const SizedBox(height: 24),
        Text('NODES_DETECTED', style: AppTextStyles.hudStatus(theme).copyWith(color: color, fontSize: 10)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: state.discoveredDevices.length,
            itemBuilder: (context, index) => _buildDeviceCard(state.discoveredDevices[index], state, color, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildScanControl(WhisperPairState state, Color color, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(state.isScanning ? Icons.sync : Icons.bluetooth, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.isScanning ? 'SEARCHING_WAVES' : 'RADIO_IDLE', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                Text(state.isScanning ? 'DETECTING FAST PAIR NODES...' : 'INITIATE SCAN FOR TARGETS', style: const TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace')),
              ],
            ),
          ),
          GlitchyButton(
            onPressed: () => state.isScanning ? ref.read(whisperPairProvider.notifier).stopScan() : ref.read(whisperPairProvider.notifier).startScan(),
            label: state.isScanning ? 'STOP' : 'SCAN',
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(device, WhisperPairState state, Color color, AppTheme theme) {
    final log = state.exploitLogs[device.id];
    final isVulnerable = device.isVulnerable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isVulnerable ? Colors.pinkAccent.withValues(alpha: 0.5) : color.withValues(alpha: 0.2)),
        color: isVulnerable ? Colors.pinkAccent.withValues(alpha: 0.05) : color.withValues(alpha: 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headphones, color: isVulnerable ? Colors.pinkAccent : color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name.toUpperCase(), style: TextStyle(color: isVulnerable ? Colors.pinkAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                    Text('ID: ${device.id}', style: const TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace')),
                  ],
                ),
              ),
              if (isVulnerable)
                GlitchyButton(
                  onPressed: () => _showMagicDialog(device),
                  label: 'MAGIC',
                ),
            ],
          ),
          if (log != null) ...[
            const Divider(color: Colors.white12, height: 16),
            Text(log, style: const TextStyle(color: Colors.cyanAccent, fontSize: 8, fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }

  void _showMagicDialog(device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.pinkAccent)),
        title: const Text('BYPASS_AUTH_CONFIRMATION', style: TextStyle(color: Colors.pinkAccent, fontFamily: 'monospace', fontSize: 14)),
        content: Text('ATTEMPTING TO FORCE-PAIR WITH ${device.name}?\n\nTHIS EXPLOITS CVE-2025-36911 TO BYPASS USER CONSENT.',
                     style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ABORT', style: TextStyle(color: Colors.grey, fontFamily: 'monospace'))),
          TextButton(onPressed: () {
            ref.read(whisperPairProvider.notifier).runMagicExploit(device);
            Navigator.pop(context);
          }, child: const Text('EXECUTE', style: TextStyle(color: Colors.pinkAccent, fontFamily: 'monospace'))),
        ],
      ),
    );
  }

  Widget _buildPairedTab(WhisperPairState state, Color color, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('HIJACKED_NODES', style: AppTextStyles.hudStatus(theme).copyWith(color: color, fontSize: 10)),
        const SizedBox(height: 12),
        if (state.pairedDevices.isEmpty)
          const Expanded(child: Center(child: Text('NO ACTIVE HIJACKS', style: TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace'))))
        else
          Expanded(
            child: ListView.builder(
              itemCount: state.pairedDevices.length,
              itemBuilder: (context, index) => _buildPairedCard(state.pairedDevices[index], color),
            ),
          ),
      ],
    );
  }

  Widget _buildPairedCard(device, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
        color: Colors.greenAccent.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                const Text('STATUS: HIJACK_SUCCESS', style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontFamily: 'monospace')),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.mic, color: Colors.cyanAccent), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildRecordingsTab(WhisperPairState state, Color color, AppTheme theme) {
    return const Center(child: Text('ENCRYPTED_DATA_VAULT_EMPTY', style: TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')));
  }
}
