import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../camera/widgets/scanline_painter.dart';
import '../camera/widgets/glitchy_button.dart';
import 'providers/blueborne_provider.dart';

class BlueBorneScreen extends ConsumerStatefulWidget {
  const BlueBorneScreen({super.key});

  @override
  ConsumerState<BlueBorneScreen> createState() => _BlueBorneScreenState();
}

class _BlueBorneScreenState extends ConsumerState<BlueBorneScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _selectedExploit = 'CVE-2017-0781 (RCE)';

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
    final bbState = ref.watch(blueborneProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('ctOS // BLUEBORNE_PROBER', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accentColor), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(bbState.isScanning ? Icons.stop : Icons.refresh, color: accentColor),
            onPressed: () => bbState.isScanning ? null : ref.read(blueborneProvider.notifier).startScan(),
          ),
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
                _buildExploitSelector(accentColor),
                const SizedBox(height: 20),
                _buildTerminal(bbState, accentColor),
                const SizedBox(height: 24),
                Text('REMOTE_TARGETS', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontSize: 10)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: bbState.devices.length,
                    itemBuilder: (context, index) => _buildDeviceCard(bbState.devices[index], bbState, accentColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploitSelector(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: DropdownButton<String>(
        value: _selectedExploit,
        dropdownColor: Colors.black,
        isExpanded: true,
        underline: Container(),
        style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace'),
        items: [
          'CVE-2017-0781 (RCE)',
          'CVE-2017-0785 (INFO_LEAK)',
          'CVE-2020-0022 (RCE)',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => _selectedExploit = v),
      ),
    );
  }

  Widget _buildTerminal(BlueBorneState state, Color color) {
    String content = 'READY_FOR_ENGAGEMENT';
    if (state.activeProbe != null) {
      content = 'PROBING_${state.activeProbe}...\nATTEMPTING_MEMORY_LEAK_VIA_SDP...';
    } else if (state.probeResults.isNotEmpty) {
      content = state.probeResults.values.last;
    }

    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.deepPurpleAccent),
      ),
      child: SingleChildScrollView(
        child: Text(content, style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 8, fontFamily: 'monospace')),
      ),
    );
  }

  Widget _buildDeviceCard(device, BlueBorneState state, Color color) {
    final isProbing = state.activeProbe == device.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.deepPurpleAccent, width: 2)),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          const Icon(Icons.leak_add, color: Colors.deepPurpleAccent, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
                Text('ID: ${device.id}', style: const TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace')),
              ],
            ),
          ),
          if (isProbing)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent))
          else
            GlitchyButton(
              onPressed: () => ref.read(blueborneProvider.notifier).runProbe(device.id),
              label: 'PROBE',
            ),
        ],
      ),
    );
  }
}
