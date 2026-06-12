import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../camera/widgets/scanline_painter.dart';
import '../home/environment_scan_screen.dart';
import 'breach_lookup_tool.dart';
import 'username_scanner_tool.dart';
import 'nfc_skimmer_tool.dart';
import 'bluetooth_prober_tool.dart';
import 'stingray_detector_tool.dart';
import 'honeypot_tool.dart';
import 'blueborne_screen.dart';
import 'ble_spam_screen.dart';
import 'whisper_pair_screen.dart';
import 'widgets/ctos_tool_card.dart';

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> with SingleTickerProviderStateMixin {
  static const String TAG = "ToolsScreen";
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // developer.log('[build] → Entry', name: TAG);
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ctOS // TOOLS_HUB', style: AppTextStyles.title(theme).copyWith(fontSize: 18, color: accentColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
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
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildToolCard(
                  'ENV_SCAN',
                  'Network Topology & Node Discovery',
                  Icons.radar,
                  accentColor,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening ENV_SCAN', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EnvironmentScanScreen()));
                  },
                ),
                _buildToolCard(
                  'BREACH_CHK',
                  'Data Breach & Password Correlation',
                  Icons.vpn_key,
                  accentColor,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening BREACH_CHK', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BreachLookupTool()));
                  },
                ),
                _buildToolCard(
                  'SOCIAL_ID',
                  'Universal Username Discovery',
                  Icons.account_circle,
                  accentColor,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening SOCIAL_ID', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UsernameScannerTool()));
                  },
                ),
                _buildToolCard(
                  'NFC_SKIM',
                  'Contactless Card Security Audit',
                  Icons.nfc,
                  Colors.orangeAccent,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening NFC_SKIM', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NFCSkimmerTool()));
                  },
                ),
                _buildToolCard(
                  'BT_PROBE',
                  'Local BLE Device Discovery',
                  Icons.bluetooth,
                  Colors.blueAccent,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening BT_PROBE', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BluetoothProberTool()));
                  },
                ),
                _buildToolCard(
                  'IMSI_DET',
                  'IMSI Catcher / Stingray Detector',
                  Icons.cell_tower,
                  Colors.redAccent,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening IMSI_DET', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StingrayDetectorTool()));
                  },
                ),
                _buildToolCard(
                  'WIFI_SPOOF',
                  'Wireless Honeypot & Analysis',
                  Icons.wifi_tethering,
                  Colors.cyanAccent,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening WIFI_SPOOF', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HoneypotTool()));
                  },
                ),
                _buildToolCard(
                  'BLUEBORNE',
                  'L2CAP/SDP Remote Vulnerability Probe',
                  Icons.leak_add,
                  Colors.deepPurpleAccent,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening BLUEBORNE', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BlueBorneScreen()));
                  },
                ),
                _buildToolCard(
                  'BLE_SPAM',
                  'Mass Pairing Popup Request Flood',
                  Icons.message,
                  Colors.lightGreenAccent,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening BLE_SPAM', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BleSpamScreen()));
                  },
                ),
                _buildToolCard(
                  'WHISPER_PAIR',
                  'Fast Pair CVE-2025-36911 Exploit',
                  Icons.record_voice_over,
                  Colors.pinkAccent,
                  theme,
                  () {
                    developer.log('[Navigation] → Opening WHISPER_PAIR', name: TAG);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WhisperPairScreen()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, String desc, IconData icon, Color color, AppTheme theme, VoidCallback onTap) {
    return CtosToolCard(
      title: title,
      description: desc,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }
}
